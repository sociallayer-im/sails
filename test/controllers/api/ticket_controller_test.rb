require "test_helper"

class Api::TicketControllerTest < ActionDispatch::IntegrationTest
  setup do
    @profile = profiles(:one)
    @auth_token = @profile.gen_auth_token
    @profile2 = profiles(:two)
    @auth_token2 = @profile2.gen_auth_token
    @group = groups(:one)
    @group2 = groups(:two)
    @event = events(:with_ticket)
  end

  test "api#event/create with tickets" do
    post api_event_create_url,
      params: { auth_token: @auth_token, group_id: @group.id, event: {
        title: "new meetup with tickets x",
        start_time: DateTime.new(2024, 8, 8, 10, 20, 30),
        end_time: DateTime.new(2024, 8, 8, 12, 20, 30),
        location: "central park",
        display: "normal",
        event_type: "event",
        tickets_attributes: [
          {
            title: "free", content: "free ticket", quantity: 5,
            payment_methods_attributes: []
          },
          {
            title: "crypto", content: "crypto ticket", quantity: 5,
            payment_methods_attributes: [
              { chain: "op", token_name: "USDT", token_address: "0x1234", price: 5000000 },
              { chain: "arb", token_name: "USDT", token_address: "0x3456", price: 4000000 }
            ]
          },
          {
            title: "fiat", content: "fiat ticket", quantity: 5,
            payment_methods_attributes: [
              { chain: "stripe", token_name: "USD", token_address: "", price: 500 }
            ]
          }
        ]
      } }

    assert_response :success
    event = Event.find_by(title: "new meetup with tickets x")
    ticket = Ticket.find_by(event: event, title: "fiat")
    assert ticket
    assert ticket.ticket_type == "event"
    assert PaymentMethod.find_by(item: ticket, chain: "stripe", token_name: "USD")
  end

  test "api#event/create with group tickets" do
    post api_event_create_url,
      params: { auth_token: @auth_token, group_id: @group.id, event: {
        title: "new meetup with tickets",
        start_time: DateTime.new(2024, 8, 8, 10, 20, 30),
        end_time: DateTime.new(2024, 8, 8, 12, 20, 30),
        location: "central park",
        display: "normal",
        event_type: "group_ticket",
        tickets_attributes: [
          {
            title: "free", content: "free ticket", quantity: 5,
            payment_methods_attributes: []
          },
          {
            title: "crypto", content: "crypto ticket", quantity: 5,
            payment_methods_attributes: [
              { chain: "op", token_name: "USDT", token_address: "0x1234", price: 5000000 },
              { chain: "arb", token_name: "USDT", token_address: "0x3456", price: 4000000 }
            ]
          },
          {
            title: "fiat", content: "fiat ticket", quantity: 5,
            payment_methods_attributes: [
              { chain: "stripe", token_name: "USD", token_address: "", price: 500 }
            ]
          }
        ]
      } }

    assert_response :success
    event = Event.find_by(title: "new meetup with tickets")
    ticket = Ticket.find_by(event: event, title: "fiat")
    assert ticket
    assert ticket.ticket_type == "group"
    assert event.event_type == "group_ticket"
    assert event.group.group_ticket_event_id == event.id
    assert PaymentMethod.find_by(item: ticket, chain: "stripe", token_name: "USD")

    # purchase group ticket with crypto

    ticket = Ticket.find_by(event: event, title: "crypto")
    op_paymethod = PaymentMethod.find_by(item: ticket, chain: "op")

    post api_ticket_rsvp_url,
         params: { auth_token: @auth_token2, id: event.id, ticket_id: ticket.id, payment_method_id: op_paymethod.id }
    assert_response :success

    ticket_item = TicketItem.find_by(event: event)
    assert ticket_item.status == "pending"

    ENV["NEXT_TOKEN"] = "WXYZ"

    post api_ticket_set_payment_status_url,
         params: { next_token: ENV["NEXT_TOKEN"], chain: ticket_item.chain, product_id: event.id, item_id: ticket_item.order_number, amount: ticket_item.amount, txhash: "0x7890" }
    assert_response :success

    ticket_item.reload
    assert ticket_item.txhash == "0x7890"
    assert ticket_item.status == "succeeded"
    assert Participant.find_by(event: event, profile: @profile2, status: "attending").payment_status == "succeeded"
    assert Membership.find_by(profile: @profile2, target: @group, status: "active")
  end

  test "api#ticket/rsvp with free ticket" do
    ticket = Ticket.find_by(event: @event, title: "free")

    post api_ticket_rsvp_url,
         params: { auth_token: @auth_token, id: @event.id, ticket_id: ticket.id, payment_method_id: nil }
    assert_response :success
  end

  test "api#ticket/rsvp with crypto ticket" do
    ticket = Ticket.find_by(event: @event, title: "crypto")
    op_paymethod = PaymentMethod.find_by(item: ticket, chain: "op")

    post api_ticket_rsvp_url,
         params: { auth_token: @auth_token, id: @event.id, ticket_id: ticket.id, payment_method_id: op_paymethod.id }
    assert_response :success

    ticket_item = TicketItem.find_by(event: @event)
    assert ticket_item.status == "pending"

    ENV["NEXT_TOKEN"] = "WXYZ"

    post api_ticket_set_payment_status_url,
         params: { next_token: ENV["NEXT_TOKEN"], chain: ticket_item.chain, product_id: @event.id, item_id: ticket_item.order_number, amount: ticket_item.amount, txhash: "0x7890" }
    assert_response :success

    ticket_item.reload
    assert ticket_item.txhash == "0x7890"
    assert ticket_item.status == "succeeded"
  end

  test "api#ticket/rsvp with crypto ticket and form" do

    ticket = Ticket.find_by(event: @event, title: "crypto")
    op_paymethod = PaymentMethod.find_by(item: ticket, chain: "op")

    custom_form = CustomForm.create(title: "test", status: "active", group_id: @group.id, item_type: "Event", item_id: @event.id)
    form_field = FormField.create(label: "name", field_type: "text", custom_form_id: custom_form.id)

    get api_event_get_url(id: @event.id), params: { auth_token: @auth_token }
    assert_response :success

    response_body = JSON.parse(response.body)
    assert_equal custom_form.id, response_body["custom_form"]["id"]
    assert_equal "name", response_body["custom_form"]["form_fields"][0]["label"]

    post api_ticket_rsvp_url,
         params: { auth_token: @auth_token, id: @event.id, ticket_id: ticket.id, payment_method_id: op_paymethod.id, answers: { "name" => "sam altman" } }
    assert_response :success

    ticket_item = TicketItem.find_by(event: @event)
    assert ticket_item.status == "pending"

    ENV["NEXT_TOKEN"] = "WXYZ"

    post api_ticket_set_payment_status_url,
         params: { next_token: ENV["NEXT_TOKEN"], chain: ticket_item.chain, product_id: @event.id, item_id: ticket_item.order_number, amount: ticket_item.amount, txhash: "0x7890" }
    assert_response :success

    ticket_item.reload
    assert ticket_item.txhash == "0x7890"
    assert ticket_item.status == "succeeded"
    assert Submission.find_by(subject_type: "TicketItem", subject_id: ticket_item.id)
    assert Submission.find_by(subject_type: "TicketItem", subject_id: ticket_item.id).answers["name"] == "sam altman"
  end

  test "api#ticket/rsvp with crypto ticket and free discount" do
    ticket = Ticket.find_by(event: @event, title: "crypto")
    op_paymethod = PaymentMethod.find_by(item: ticket, chain: "op")

    coupon = create_coupon(@event, 0)

    post api_ticket_rsvp_url,
         params: { auth_token: @auth_token, id: @event.id, ticket_id: ticket.id, payment_method_id: op_paymethod.id, coupon: coupon.code }
    assert_response :success

    ticket_item = TicketItem.find_by(event: @event)
    assert ticket_item.status == "succeeded"

    ENV["NEXT_TOKEN"] = "WXYZ"

    post api_ticket_set_payment_status_url,
         params: { next_token: ENV["NEXT_TOKEN"], chain: ticket_item.chain, product_id: @event.id, item_id: ticket_item.order_number, amount: ticket_item.amount, txhash: "0x7890" }
    assert_response :success
    assert response.body == "{\"result\":\"ok\",\"message\":\"skip verify succeeded ticket_item\"}"

    ticket_item.reload
    assert ticket_item.coupon_id == coupon.id
  end

  test "api#ticket/rsvp with crypto ticket and discount" do
    ticket = Ticket.find_by(event: @event, title: "crypto")
    op_paymethod = PaymentMethod.find_by(item: ticket, chain: "op")

    coupon = create_coupon(@event, 6000)

    post api_ticket_rsvp_url,
         params: { auth_token: @auth_token, id: @event.id, ticket_id: ticket.id, payment_method_id: op_paymethod.id, coupon: coupon.code }
    assert_response :success

    ticket_item = TicketItem.find_by(event: @event)
    assert ticket_item.status == "pending"
    assert ticket_item.amount == 3000000
    assert Participant.find_by(event: @event, profile: @profile).payment_status == "pending"
    assert Participant.find_by(event: @event, profile: @profile).status == "attending"


    ENV["NEXT_TOKEN"] = "WXYZ"

    post api_ticket_set_payment_status_url,
         params: { next_token: ENV["NEXT_TOKEN"], chain: ticket_item.chain, product_id: @event.id, item_id: ticket_item.order_number, amount: 3000000, txhash: "0x7890" }
    assert_response :success

    ticket_item.reload
    assert ticket_item.txhash == "0x7890"
    assert ticket_item.status == "succeeded"
    assert ticket_item.coupon_id == coupon.id
    assert Participant.find_by(event: @event, profile: @profile).payment_status == "succeeded"
    assert Participant.find_by(event: @event, profile: @profile).status == "attending"

  end

  test "api#ticket/cancel_unpaid_item" do
    ticket = Ticket.find_by(event: @event, title: "crypto")
    op_paymethod = PaymentMethod.find_by(item: ticket, chain: "op")

    post api_ticket_rsvp_url,
         params: { auth_token: @auth_token, id: @event.id, ticket_id: ticket.id, payment_method_id: op_paymethod.id }
    assert_response :success

    ticket_item = TicketItem.find_by(event: @event)
    assert ticket_item.status == "pending"
    assert Participant.find_by(event: @event, profile: @profile).payment_status == "pending"
    assert Participant.find_by(event: @event, profile: @profile).status == "attending"

    post api_ticket_cancel_unpaid_item_url,
         params: { auth_token: @auth_token, chain: ticket_item.chain, product_id: @event.id, item_id: ticket_item.order_number }
    assert_response :success

    ticket_item.reload
    assert ticket_item.status == "cancelled"
    assert ticket_item.participant_id.nil?
    assert Participant.find_by(event: @event, profile: @profile).payment_status == "cancelled"
    assert Participant.find_by(event: @event, profile: @profile).status == "cancelled"
  end

  # test "api#ticket/rsvp with fiat ticket" do
  #   ticket = Ticket.find_by(event: @event, title: "fiat")
  #   stripe_paymethod = PaymentMethod.find_by(item: ticket, chain: "stripe")

  #   coupon = create_coupon(@event, 6000)

  #   post api_ticket_rsvp_url,
  #        params: { auth_token: @auth_token, id: @event.id, ticket_id: ticket.id, payment_method_id: stripe_paymethod.id, coupon: coupon.code }
  #   assert_response :success

  #   ticket_item = TicketItem.find_by(event: @event)
  #   assert ticket_item.status == "pending"
  #   assert ticket_item.amount == 300

  #   post api_ticket_stripe_client_secret_url,
  #        params: { auth_token: @auth_token, ticket_item_id: ticket_item.id }
  #   assert_response :success
  #   data = JSON.parse(response.body)

  #   post api_ticket_stripe_callback_url,
  #        params: { auth_token: @auth_token,
  #                  "type" => "charge.succeeded",
  #                  "data" => {
  #                    "object" => {
  #                      "status" => "succeeded",
  #                      "payment_intent" => data["payment_intent_id"]
  #                    }
  #                  }
  #                }
  #   assert_response :success

  #   ticket_item.reload
  #   assert ticket_item.status == "succeeded"
  #   assert ticket_item.coupon_id == coupon.id
  # end


  # test "api#ticket/rsvp with daimo ticket" do
  #   travel_to Date.new(2024, 8, 8)

  #   ticket = Ticket.find_by(event: @event, title: "daimo")
  #   paymethod = PaymentMethod.find_by(item: ticket, chain: "base")
  #   p @event.id
  #   p ticket.id
  #   p paymethod.id

  #   post api_ticket_rsvp_url,
  #        params: { auth_token: @auth_token,
  #        id: @event.id,
  #        ticket_id: ticket.id,
  #        payment_method_id: paymethod.id }
  #   assert_response :success
  #   # assert Participant.find_by(event: @event, profile: @profile, status: "attending").payment_status == "succeeded"

  #   ticket_item = TicketItem.find_by(event: @event)
  #   post api_ticket_daimo_create_payment_link_url, params: { auth_token: @auth_token, ticket_item_id: ticket_item.id }
  #   assert_response :success
  #   p response.body
  # end

  test "api#ticket/rsvp with free group ticket" do
    ticket = Ticket.find_by(event: @event, title: "free")

    post api_ticket_rsvp_url,
         params: { auth_token: @auth_token, id: @event.id, ticket_id: ticket.id, payment_method_id: nil }
    assert_response :success
    assert Participant.find_by(event: @event, profile: @profile, status: "attending").payment_status == "succeeded"
  end

  test "api#ticket/check_coupon" do
    get api_ticket_check_coupon_url, params: { auth_token: @auth_token, event_id: @event.id, code: "abcdef" }
    assert_response :success
  end

  test "api#ticket/get_coupon" do
    coupon = create_coupon(@event, 6000)
    get api_ticket_get_coupon_url, params: { auth_token: @auth_token, id: coupon.id }
    assert_response :success
  end

  test "api#ticket/coupon_price" do
    coupon = create_coupon(@event, 6000)
    get api_ticket_coupon_price_url, params: { auth_token: @auth_token, event_id: @event.id, code: coupon.code, amount: 10000 }
    assert_response :success
  end

  test "api#ticket/set_coupon" do
    post api_ticket_set_coupon_url, params: { auth_token: @auth_token, event_id: @event.id, coupons_attributes: [
       { selector_type: "code", label: "community", code: "dddddd", receiver_address: "", discount_type: "ratio", discount: 6000, event_id: @event.id, applicable_ticket_ids: [], ticket_item_ids: [], expires_at: (DateTime.now + 7.days), max_allowed_usages: 10, order_usage_count: 0, _destroy: false }
    ] }
    assert_response :success
    assert Coupon.find_by(selector_type: "code", code: "dddddd")
  end

  private

  def create_coupon(event, discount_value)
    Coupon.create(
      selector_type: "code",
      label: "community",
      code: "abcdef",
      max_allowed_usages: 10,
      order_usage_count: 0,
      expires_at: (DateTime.now + 7.days),
      discount_type: "ratio",
      discount: discount_value,
      event_id: event.id
    )
  end
end