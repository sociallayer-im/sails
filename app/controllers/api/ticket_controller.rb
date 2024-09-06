Stripe.api_version = "2020-08-27"
Stripe.api_key = ENV["STRIPE_APP_SECRET"]

class Api::TicketController < ApiController
  def rsvp
    profile = current_profile!
    event = Event.find(params[:id])
    status = "attending"

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

      if params[:promo_code].present?
        promo_code = PromoCode.find_by(selector: "code", event_id: event.id, code: params[:promo_code])
        amount, discount_value, discount_data = promo_code.get_discounted_price(amount)
        if discount_value
          promo_code.increment!(:order_usage_count)
        end
      end
      status = amount == 0 ? "succeeded" : "pending"
      ticket_item = TicketItem.create(
        status: status,
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
      )
    else
      ticket_item = TicketItem.create(
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

    if ticket_item.status == "succeeded" && participant.status != "succeeded"
      participant.update(payment_status: "succeeded")
      if profile.email.present?
        # event.send_mail_new_event(profile.email)
      end
    end

    render json: { participant: participant.as_json, ticket_item: ticket_item.as_json }
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
      )

    if ticket_item.participant.payment_status != "succeeded"
      ticket_item.participant.update(payment_status: "succeeded")
      if ticket_item.profile.email.present?
        # ticket_item.event.send_mail_new_event(ticket_item.profile.email)
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

  def stripe_client_secret
    p "create payment_intent"
    ticket_item = TicketItem.find(params[:ticket_item_id])

    if !ticket_item
      return render json: { result: "error", message: "ticket_item not found" }
    end

    if ticket_item.chain != "stripe"
      return render json: { result: "error", message: "ticket_item is not for stripe" }
    end

    payment_intent = Stripe::PaymentIntent.create({
      amount: ticket_item.amount,
      automatic_payment_methods: { enabled: true },
      currency: "usd"
    })
    p payment_intent
    ticket_item.update(txhash: payment_intent.id)
    render json: { result: "ok", payment_intent_id: payment_intent.id, client_secret: payment_intent.client_secret }
  end

  def check_promo_code
    promo_code = PromoCode.find_by(event_id: params[:event_id], code: params[:code])
    render json: { promo_code: promo_code.as_json }
  end

  def get_promo_code
    promo_code = PromoCode.find(params[:id])
    authorize promo_code.event, :update?
    render json: { promo_code_id: promo_code.id, code: promo_code.code }
  end

  def promo_code_price
    promo_code = PromoCode.find_by(selector: "code", code: params[:promo_code])
    amount, discount_value, discount_data = promo_code.get_discounted_price(params[:amount])
    render json: { promo_code_id: promo_code.id, amount: amount }
  end
end
