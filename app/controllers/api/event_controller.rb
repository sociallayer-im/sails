class Api::EventController < ApiController
  def create
    profile = current_profile!
    group = Group.find_by(id: params[:group_id])

    status = "published"
    @send_approval_email_to_manager = false
    if group && params[:venue_id]
      venue = Venue.find_by(id: params[:venue_id], group_id: group.id)
      raise AppError.new("group venue not exists") unless venue

      if venue.require_approval && !group.is_manager(profile.id)
        status = "pending"
        @send_approval_email_to_manager = true
      end
    elsif params[:venue_id]
      raise AppError.new("group is empty")
    end

    # todo : allow group setting for pending event

    # todo : move badge_class to voucher
    if params[:badge_class_id]
      badge_class = BadgeClass.find(params[:badge_class_id])
      authorize badge_class, :send?
    end

    event = Event.new(event_params)
    event.update(
      status: status,
      owner: profile,
      group: group,
      display: "normal",
      event_type: event_params[:event_type] || "event", # todo : could be "group_ticket"
    )
    if event_params[:event_type] == 'group_ticket'
      group.update(group_ticket_event_id: event.id)
    end

    group.increment!(:events_count) if group

    if @send_approval_email_to_manager
      Membership.includes(:profile).where(profile_id: group.id, role: [ "owner", "manager" ]).each do |membership|
        if membership.data.present? && membership.data.include?("venue") && membership.profile.email.present?
          group_name = group ? (group.nickname || group.username) : ""
          mailer = GroupMailer.with(group_name: group_name, event_id: event.id, recipient: membership.profile.email).venue_review_email
          mailer.deliver_now!
        end
      end
    end

    render json: { result: "ok", event: event.as_json }
  end

  def set_badge
    profile = current_profile!
    event = Event.find(params[:id])
    badge_class = BadgeClass.find(params[:badge_class_id])
    authorize event, :update?
    authorize badge_class, :send?

    voucher = Voucher.new(
      sender: profile,
      badge_class: badge_class,
      item_type: "Event", item_id: event.id,
      # need test
      strategy: "event",
      counter: 1,
    )
    voucher.save

    render json: { result: "ok", event: event.as_json }
  end

  def send_badge
    profile = current_profile!
    event = Event.find(params[:id])
    voucher = Voucher.find_by(item_type: "Event", item_id: event.id)
    raise AppError.new("event voucher not set") unless voucher

    authorize event, :update?

    vouchers = event.participants.where(status: "checked", voucher_id: nil).map do |participant|
      receiver = participant.profile
      voucher = Voucher.new(
        sender: profile,
        badge_class: badge_class,
        # need test
        message: params[:message],
        strategy: "event",
        counter: 1,
        receiver_address_type: "id",
        receiver_id: receiver.id,
        # need test
        expires_at: (params[:expires_at] || DateTime.now + 90.days),
      )
      voucher.save
      participant.update(voucher_id: voucher.id)
      activity = Activity.create(item: badge_class, initiator_id: profile.id, action: "voucher/send_event_badge")

      voucher
    end

    render json: { vouchers: vouchers.as_json }
  end

  def update
    profile = current_profile!

    event = Event.find(params[:id])
    authorize event, :update?

    if event_params[:venue_id] != event.venue_id
      venue = Venue.find_by(id: params[:venue_id], group_id: group.id)
      raise AppError.new("group venue not exists") unless venue

      if venue.require_approval && !group.is_manager(profile.id)
        status = "pending"
        send_approval_email_to_manager = true
      end
    end

    old_start_time = event.start_time
    old_end_time = event.end_time
    old_location = event.location

    event.update(event_params)

    if old_start_time != event.start_time || old_end_time != event.end_time || old_location != event.location
      event.participants.each do |participant|
        if participant.profile.email.present?
          recipient = participant.profile.email
          event.send_mail_update_event(recipient)
        end
      end
    end

    render json: { result: "ok", event: event.as_json }
  end

  def unpublish
    profile = current_profile!

    event = Event.find(params[:id])
    authorize event, :update?

    event.update(status: "cancelled")
    event.group.decrement!(:events_count)

    event.participants.each do |participant|
      participant.email_notify!(:cancel)
    end

    render json: { result: "ok", event: event.as_json }
  end

  def check_group_permission
    profile = current_profile!
    event = Event.find(params[:id])
    group = event.group
    tz = group.timezone

    if !group.group_ticket_enabled
      return render json: { result: "ok", check: true, message: "action allowed" }
    end

    if event.owner_id == profile.id || group.is_manager(profile.id) ||
        EventRole.find_by(event_id: event.id, profile_id: profile.id) ||
        EventRole.find_by(event_id: event.id, email: profile.email)

      return render json: { result: "ok", check: true, message: "action allowed" }
    end

    event_period = (event.start_time.in_time_zone(tz).to_date..event.end_time.in_time_zone(tz).to_date)

    TicketItem.where(ticket_type: "group", group_id: group.id, profile_id: profile.id).each do |ticket_item|
      ticket = ticket_item.ticket
      ok = false

      if ticket.start_date.present?
        ok = (ticket.start_date..ticket.end_date).overlaps?(event_period)
      elsif ticket.days_allowed.present?
        ok = ticket.days_allowed.any? { |day| event_period.include?(day) }
      else
        ok = true
      end

      ok = if ticket.tracks_allowed.present?
        ok && ticket.tracks_allowed.intersect?(event.tags)
      else
        ok
      end

      return render json: { result: "ok", check: true, message: "action allowed" } if ok
    end

    render json: { result: "ok", check: false, message: "action not allowed" } if ok
  end

  def join
    profile = current_profile!
    event = Event.find(params[:id])
    status = "attending"

    if event.venue && event.venue.capacity && event.venue.capacity > 0 && event.participants_count >= event.venue.capacity
      raise AppError.new("exceed venue capacity")
    end

    if event.tickets.present?
      raise AppError.new("need processing tickets, use rsvp instead")
    end

    participant = Participant.find_by(event_id: event.id, profile_id: profile.id)
    if !participant
      participant = Participant.new(
        profile: profile,
        event: event,
        status: status,
        register_time: DateTime.now,
      )
    else
      participant.status = status
      participant.register_time = DateTime.now
    end

    participant.save

    event.increment!(:participants_count)

    if profile.email.present?
      recipient = profile.email
      event.send_mail_new_event(recipient)
    end

    render json: { participant: participant.as_json }
  end

  def check
    profile = current_profile!
    event = Event.find(params[:id])

    participant = Participant.find_by(event_id: params[:id], profile_id: params[:profile_id])
    authorize event, :update?
    participant.status = "checked"
    participant.check_time = DateTime.now
    participant.save

    render json: { participant: participant.as_json }
  end

  def cancel
    profile = current_profile!
    event = Event.find(params[:id])

    participant = Participant.find_by(event_id: params[:id], profile_id: profile.id)
    authorize participant, :update?

    # todo : refund or require more action when cancelling paid participants
    participant.update(status: "cancelled")
    event.decrement!(:participants_count)

    if profile.email.present?
      # event.notify_event_registration(profile.email, "You have calcelled an event")
    end

    render json: { participant: participant.as_json }
  end

  private

  def event_params
    params.require(:event).permit(
      :event_type,
      :title,
      :start_time,
      :end_time,
      :timezone,
      :meeting_url,
      :venue_id,
      :location,
      :formatted_address,
      :location_viewport,
      :geo_lat,
      :geo_lng,
      :cover_url,
      :require_approval,
      :content,
      :tags,
      :max_participant,
      :min_participant,
      :participants_count,
      :badge_class_id,
      :external_url,
      :notes,
      tags: [],
      extra: {},
      tickets_attributes: [
        :id,
        :title,
        :content,
        :ticket_type,
        :group_id,
        :event_id,
        :check_badge_class_id,
        :quantity,
        :end_time,
        :need_approval,
        :status,
        :zupass_event_id,
        :zupass_product_id,
        :zupass_product_name,
        :start_date,
        :end_date,
        :days_allowed,
        :tracks_allowed,
        :_destroy,
        payment_methods_attributes: [
          :id,
          :item_type,
          :item_id,
          :chain,
          :kind,
          :token_name,
          :token_address,
          :receiver_address,
          :price,
          :_destroy
        ]
      ],
      promo_codes_attributes: [ :id, :selector, :label, :code, :receiver_address, :discount_type, :discount, :event_id, :applicable_ticket_ids, :ticket_item_ids, :expiry_time, :max_allowed_usages, :order_usage_count, :_destroy ],
      event_roles_attributes: [ :id, :role, :group_id, :event_id, :profile_id, :email, :nickname, :image_url, :_destroy ],
      )
  end
end
