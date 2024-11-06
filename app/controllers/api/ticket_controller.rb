Stripe.api_version = "2020-08-27"
Stripe.api_key = ENV["STRIPE_APP_SECRET"]


class Api::TicketController < ApiController
  def rsvp
    profile = current_profile!
    event = Event.find(params[:id])
    status = "attending"

    if event.status == "closed"
      raise AppError.new("event closed")
    end

    if event.end_time + 1.hour < DateTime.now
      raise AppError.new("event ended")
    end

    if event.venue && event.venue.capacity && event.venue.capacity > 0 && event.participants_count >= event.venue.capacity
      raise AppError.new("exceed venue capacity")
    end

    ticket = Ticket.find_by(id: params[:ticket_id], event_id: event.id)
    if ticket.quantity
      raise AppError.new("run out of ticket") if ticket.quantity <= 0
      ticket.decrement!(:quantity)
    end

    participant = Participant.find_by(event_id: event.id, profile_id: profile.id)
    if !participant
      participant = Participant.create(
        profile: profile,
        event: event,
        status: status,
        payment_status: "pending",
        register_time: DateTime.now,
        message: params[:message],
      )
    elsif participant.status == "cancelled"
        participant.update(
          status: status,
          payment_status: "pending",
          register_time: DateTime.now,
          message: params[:message],
          )
    end

    if ticket.payment_methods.any?
      paymethod = PaymentMethod.find_by(id: params[:payment_method_id], item_type: "Ticket", item_id: ticket.id)
      unless paymethod
        return render json: { result: "error", message: "payment_method not found" }
      end
      amount = paymethod.price
      discount_value = nil
      discount_data = nil
      coupon_id = nil

      # todo : check account-bounded coupon

      if params[:coupon].present?
        coupon = Coupon.find_by(selector_type: "code", event_id: event.id, code: params[:coupon])
        if coupon.expires_at < DateTime.now || coupon.max_allowed_usages <= coupon.order_usage_count
          return render json: { result: "error", message: "coupon is not available" }
        end

        amount, discount_value, discount_data = coupon.get_discounted_price(amount)
        if discount_value
          coupon.increment!(:order_usage_count)
          coupon_id = coupon.id
        end
      end
      if paymethod.chain == "stripe" && amount < 400
        amount = 0
      end
      status = amount == 0 ? "succeeded" : "pending"
      ticket_item = TicketItem.create(
        status: status,
        ticket_type: ticket.ticket_type,
        profile_id: profile.id,
        ticket_id: ticket.id,
        event_id: event.id,
        chain: paymethod.chain,
        participant_id: participant.id,
        amount: amount,
        original_price: paymethod.price,
        payment_method_id: paymethod.id,
        discount_value: discount_value,
        discount_data: discount_data,
        coupon_id: coupon_id,
      )
    else
      ticket_item = TicketItem.create(
        ticket_type: ticket.ticket_type,
        status: "succeeded",
        profile_id: profile.id,
        ticket_id: ticket.id,
        event_id: event.id,
        participant_id: participant.id,
        amount: 0,
        original_price: 0,
      )
    end

    event.increment!(:participants_count)

    ticket_item.update(
      order_number: (ticket_item.id + 1000000).to_s,
      )

    if ticket_item.ticket_type == 'group'
      ticket_item.update(
        group_id: ticket.group_id,
        )
    end

    if params[:answers].present?
      custom_form = CustomForm.find_by(item_type: "Event", item_id: event.id)
      if custom_form.present?
        @submission = Submission.create(custom_form: custom_form, profile: profile, answers: params[:answers], subject_type: "TicketItem", subject_id: ticket_item.id)
      end
    end

    if ticket_item.status == "succeeded" && participant.status != "succeeded"
      participant.update(payment_status: "succeeded")
      if ticket_item.ticket_type == 'group' && Membership.find_by(profile_id: profile.id, group_id: ticket.group_id).blank?
        Membership.create(profile: profile, group: ticket.group, role: "member", status: "active")
      end
      if profile.email.present?
        # event.send_mail_new_event(profile.email)
      end
    end

    render json: { participant: participant.as_json, ticket_item: ticket_item.as_json }
  end

  def cancel_unpaid_item
    ticket_item = TicketItem.find_by(chain: params[:chain], event_id: params[:product_id], order_number: params[:item_id].to_s)
    profile = current_profile!

    unless ticket_item
      return render json: { result: "error", message: "ticket_item not found" }
    end

    if ticket_item.status != "pending"
      return render json: { result: "ok", message: "only for pending ticket_item" }
    end

    if ticket_item.profile_id != profile.id
      raise AppError.new("not allowed")
    end
    ticket_item.cancel

    render json: { ticket_item: ticket_item.as_json }
  end

  def set_payment_status
    unless params[:next_token] == ENV["NEXT_TOKEN"]
      raise AppError.new("invalid next token")
    end

    # next_token
    # chain
    # product_id - event_id
    # item_id - order_number
    # amount
    # txhash

    ticket_item = TicketItem.find_by(chain: params[:chain], event_id: params[:product_id], order_number: params[:item_id].to_s)

    unless ticket_item
      return render json: { result: "error", message: "ticket_item not found" }
    end

    if ticket_item.status == "succeeded"
      return render json: { result: "ok", message: "skip verify succeeded ticket_item" }
    end

    if params[:amount].to_i < ticket_item.amount
      return render json: { result: "error", message: "amount invalid" }
    end

    # todo : verify token_address, receiver_address, chain

    ticket_item.update(
      status: "succeeded",
      txhash: params[:txhash],
      sender_address: params[:sender_address],
      )

    if ticket_item.ticket_type == 'group' && Membership.find_by(profile_id: ticket_item.profile_id, target_id: ticket_item.group_id).blank?
      Membership.create(profile: ticket_item.profile, target: ticket_item.group, role: "member", status: "active")
    end

    if ticket_item.participant.payment_status != "succeeded"
      ticket_item.participant.update(payment_status: "succeeded")
      if ticket_item.profile.email.present?
        ticket_item.profile.send_mail_new_event(ticket_item.event)
      end
    end

    render json: { participant: ticket_item.participant.as_json, ticket_item: ticket_item.as_json }
  end

  def stripe_callback
    if params["type"] == "charge.succeeded"
      intent_id = params["data"]["object"]["payment_intent"]
      status = params["data"]["object"]["status"]
      ticket_item = TicketItem.find_by(txhash: intent_id)
      ticket_item.update(status: status)
      if ticket_item.participant.payment_status != "succeeded"
        ticket_item.participant.update(payment_status: status)
        if ticket_item.profile.email.present?
          # ticket_item.event.send_mail_new_event(ticket_item.profile.email)
        end
      end
    end

    render json: { result: "ok" }
  end

  def stripe_config
    stripe_public_key = Config.find_by(name: "stripe_public_key", group_id: params[:group_id]).try(:value)
    render json: { stripe_public_key: stripe_public_key }
  end

  def stripe_client_secret
    ticket_item = TicketItem.find(params[:ticket_item_id])

    if !ticket_item
      return render json: { result: "error", message: "ticket_item not found" }
    end

    if ticket_item.chain != "stripe"
      return render json: { result: "error", message: "ticket_item is not for stripe" }
    end

    # todo : stripe_secret_key from config
    # Stripe.api_key = Config.find_by(name: "stripe_secret_key", group_id: ticket_item.ticket.group_id).try(:value)

    payment_intent = Stripe::PaymentIntent.create({
      amount: ticket_item.amount,
      automatic_payment_methods: { enabled: true },
      currency: "usd"
    })
    p payment_intent
    ticket_item.update(txhash: payment_intent.id)
    render json: { result: "ok", payment_intent_id: payment_intent.id, client_secret: payment_intent.client_secret }
  end

  def check_coupon
    coupon = Coupon.find_by(event_id: params[:event_id], code: params[:code])
    render json: { coupon: coupon.as_json }
  end

  def get_coupon
    coupon = Coupon.find(params[:id])
    authorize coupon.event, :update?
    render json: { coupon_id: coupon.id, code: coupon.code }
  end

  def coupon_price
    coupon = Coupon.find_by(selector_type: "code", code: params[:coupon])
    amount, discount_value, discount_data = coupon.get_discounted_price(params[:amount])
    render json: { coupon_id: coupon.id, amount: amount }
  end

  def list_group_ticket_types
    group = Group.find_by(handle: params[:group_id]) || Group.find_by(id: params[:group_id])
    render json: { tickets: group.tickets.as_json }
  end

  def add_group_ticket_item
    profile = current_profile
    group = Group.find_by(handle: params[:group_id]) || Group.find_by(id: params[:group_id])
    authorize group, :manage?, policy_class: GroupPolicy
    email = params[:email].downcase

    ticket_item = TicketItem.create_with(status: "unbounded").find_or_create_by(
      event_id: group.group_ticket_event_id,
      ticket_id: Ticket.find_by(content: params["title"].strip, group_id: group.id).id,
      selector_type: "email",
      selector_address: email,
      ticket_type: "group",
      group_id: group.id,
      auth_type: "invite",
    )

    profile = Profile.find_by(email: email)
    if profile
      ticket_item.update(status: "succeeded", profile_id: profile.id)
      Membership.create_with(role: "member").find_or_create_by(profile: profile, target: ticket_item.group, status: "active")
    end

    render json: { result: "ok"}
  end

  def set_coupon
    profile = current_profile!
    event = Event.find(params[:event_id])
    authorize event, :update?, policy_class: EventPolicy

    event.update(event_coupon_params)
    render json: { result: "ok", track: track }
  end

  def daimo_create_payment_link
    ticket_item = TicketItem.find(params[:ticket_item_id])
    ticket = ticket_item.ticket
    p 'ticket', ticket
    payment_method = ticket_item.payment_method
    p 'payment_method', payment_method
    receiver_address = payment_method.receiver_address
    token_address = payment_method.token_address
    amount = ticket_item.amount.to_s

    payload = {
      "intent": "Sola Event Payment",
      "items": [
        {
          "name": "Sola Event Ticket",
          "description": ""
        }
      ],
      "recipient": {
        "address": receiver_address,
        "amount": amount,
        "token": token_address,
        "chain": 10 # todo
      },
      "paymentOptions": [],
      "redirectUri": "https://app.sola.day"
    }
    p payload

    headers = {
      "Idempotency-Key" => ticket_item.order_number,
      "Api-Key" => ENV["DAIMO_API_KEY"],
      "Content-Type" => "application/json",
    }
    p headers

    resp = begin
      response = RestClient.post("https://pay.daimo.com/api/generate", payload.to_json, {
        "Idempotency-Key" => ticket_item.order_number,
        "Api-Key" => ENV["DAIMO_API_KEY"],
        "Content-Type" => "application/json",
      })
      JSON.parse(response.body)
    rescue RestClient::ExceptionWithResponse => e
      e.response
    end

    render json: resp
  end

  def daimo_webhook
    p params
    render json: { result: "ok" }
  end

  private

  def submission_params
    params.require(:submission).permit(:custom_form_id, :answers)
  end

  def event_coupon_params
    params.permit(
      coupons_attributes: [ :id, :selector_type, :label, :code, :receiver_address, :discount_type, :discount, :event_id, :applicable_ticket_ids, :ticket_item_ids, :expires_at, :max_allowed_usages, :order_usage_count, :_destroy ],
    )
  end
end
