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

    if event_params[:venue_id] && Event.where(venue_id: event_params[:venue_id]).where("start_time < ? AND end_time > ?", event_params[:end_time], event_params[:start_time]).any?
      return render json: { result: "error", message: "time overlaped in the same venue" }
    end

    event = Event.new(event_params)
    event.pinned = params[:pinned] if event.group && event.group.is_manager(profile.id)
    event.update(
      status: status,
      owner: profile,
      group: group,
      display: event_params[:display] || "normal",
      event_type: event_params[:event_type] || "event", # todo : could be "group_ticket"
    )

    if event_params[:event_type] == 'group_ticket'
      group.update(group_ticket_event_id: event.id)
    end

    group.increment!(:events_count) if group

    if @send_approval_email_to_manager
      Membership.includes(:profile).where(target_id: group.id, role: [ "owner", "manager" ]).each do |membership|
        if membership.cap.present? && membership.cap.include?("venue") && membership.profile.email.present?
          group_name = group ? (group.nickname || group.handle) : ""
          mailer = GroupMailer.with(group_name: group_name, event_id: event.id, recipient: membership.profile.email).venue_review_email
          mailer.deliver_later
        end
      end
    end

    event.create_event_webhook

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

    if Event.where(venue_id: event_params[:venue_id]).where("start_time < ? AND end_time > ?", event_params[:end_time], event_params[:start_time]).where.not(id: event.id).any?
      return render json: { result: "error", message: "time overlaped in the same venue" }
    end

    if event_params[:venue_id] != event.venue_id
      venue = Venue.find_by(id: params[:venue_id], group_id: group.id)
      raise AppError.new("group venue not exists") unless venue

      if venue.require_approval && !group.is_manager(profile.id)
        status = "pending"
        send_approval_email_to_manager = true
      end
    end

    event.assign_attributes(event_params)
    event.pinned = params[:pinned] if event.group && event.group.is_manager(profile.id)
    if (["start_time", "end_time", "location"] - event.changed).present?
      @send_update_email = true
    else
      @send_update_email = false
    end
    event.save

    if @send_update_email
      event.participants.each do |participant|
        participant.profile.send_mail_update_event(event)
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
      participant.profile.send_mail_cancel_event(event)
    end

    render json: { result: "ok", event: event.as_json }
  end

  # todo test
  def check_group_permission
    profile = current_profile!
    event = Event.find(params[:id])
    group = event.group
    tz = group.timezone

    if !group.group_ticket_event_id
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

    if event.group.can_join_event == "ticket" && !event.check_group_event_permission(profile)
      raise AppError.new("group ticket check failed")
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

    profile.send_mail_new_event(event)

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

    profile.send_mail_cancel_event(event)

    render json: { participant: participant.as_json }
  end

  def remove_participant
    profile = current_profile!
    participant = Participant.find_by(event_id: params[:id], profile_id: params[:profile_id])
    authorize participant, :update?
    participant.update(status: "cancelled")
    participant.event.decrement!(:participants_count)
    render json: { participant: participant.as_json }
  end

  def set_notes
    profile = current_profile!
    event = Event.find(params[:id])
    authorize event, :update?
    event.update(notes: params[:notes])
    render json: { event: event.as_json }
  end

  def get
    @event = Event.includes(:owner).find(params[:id])
    render template: "api/event/show"
  end

  def list
    auth_profile = Profile.find_by(id: params[:source_profile_id]) || current_profile

    @group = Group.find_by(id: params[:group_id]) || Group.find_by(handle: params[:group_id])
    group_id = @group.id

    if auth_profile && @group.is_manager(auth_profile.id)
      pub_tracks = Track.where(group_id: group_id).ids
      pub_tracks << nil
    elsif auth_profile && @group.group_union.present?
      managing_groups = Membership.where(profile_id: auth_profile.id, role: ["owner", "manager", "operator"], id: @group.group_union).ids
      pub_tracks = Track.where(group_id: managing_groups).ids + Track.where(group_id: @group.group_union, kind: "public").ids + TrackRole.where(group_id: @group.group_union, profile_id: auth_profile.id).pluck(:track_id)
      pub_tracks = pub_tracks.compact
      pub_tracks << nil
    elsif auth_profile
      pub_tracks = Track.where(group_id: group_id, kind: "public").ids + TrackRole.where(group_id: group_id, profile_id: auth_profile.id).pluck(:track_id)
      pub_tracks << nil
    else
      pub_tracks = Track.where(group_id: group_id, kind: "public").ids
      pub_tracks << nil
    end

    if params[:track_id] && !pub_tracks.include?(params[:track_id].to_i)
      return render json: { result: "error", message: "track not found" }
    end

    event_group_ids = @group.group_union.present? ? [@group.id] + @group.group_union : [@group.id]

    @timezone = @group.timezone || params[:timezone] || 'UTC'
    @events = Event.includes(:group, :venue, :owner, :event_roles).where(status: ["open", "published"]).where(group_id: event_group_ids)
    if @group.can_view_event == "member"
      if (auth_profile.blank? || !@group.is_member(auth_profile.id))
        @events = @events.where("tags @> ARRAY[?]::varchar[]", ["public"])
      end
    elsif params[:private_event].present? && auth_profile && @group.is_manager(auth_profile.id)
      @events = @events.where(display: "private")
    elsif params[:private_event].present?
      @events = @events.where(display: "none")
    else
      @events = @events.where(display: ["normal", "pinned", "public"])
    end

    # if ["3477", "3502", "lovepunkschiangmai", "auraverse"].include?(params[:group_id])
    #   @group = Group.where(id: [3477, 3502]).all
    #   group_id = [3477, 3502]
    #   @events = Event.includes(:group, :venue, :owner, :event_roles).where(status: ["open", "published"]).where(display: ["normal", "pinned", "public"]).where(group_id: group_id)
    # end

    if params[:track_id]
      @events = @events.where(track_id: params[:track_id])
    else
      @events = @events.where(track_id: pub_tracks)
    end
    if params[:tags]
      @events = @events.where("tags && ARRAY[:options]::varchar[]", options: params[:tags].split(","))
      # @events = @events.where("tags @> ARRAY[?]::varchar[]", params[:tags].split(","))
    end
    if params[:search_title]
      @events = @events.where("title like ?", "%#{params[:search_title]}%")
      # @events = @events.where("tags @> ARRAY[?]::varchar[]", params[:tags].split(","))
    end
    if params[:venue_id]
      @events = @events.where(venue_id: params[:venue_id])
    end
    if params[:theme]
      @events = @events.where(theme: params[:theme])
    end
    if params[:my_event].present?
      return { reuslt: "error", message: "authentication required" } unless auth_profile
      @events = @events.joins(:participants).where(participants: { profile_id: auth_profile.id, status: "attending" })
    end
    if params[:my_event].present?
      return { reuslt: "error", message: "authentication required" } unless auth_profile
      @events = @events.joins(:participants).where(participants: { profile_id: auth_profile.id, status: "attending" })
    end

    if params[:skip_multiday].present?
      @events = @events.where("start_time >= ?", DateTime.now - 1.days)
    end
    if params[:skip_recurring].present?
      @events = @events.where(recurring_id: nil)
    end

    if params[:start_date].present? && params[:end_date].present?
      start_time = Date.parse(params[:start_date]).in_time_zone(@timezone).at_beginning_of_day
      end_time = Date.parse(params[:end_date]).in_time_zone(@timezone).at_end_of_day
      @events = @events.where("start_time <= ? AND end_time >= ?", end_time, start_time)
      @events = @events.order(start_time: :asc)
    elsif params[:start_time].present? && params[:end_time].present?
      start_time = params[:start_time]
      end_time = params[:end_time]
      @events = @events.where("start_time <= ? AND end_time >= ?", end_time, start_time)
      @events = @events.order(start_time: :asc)
    elsif params[:collection] == "currentweek"
      @events = @events.where("end_time >= ?", DateTime.now)
      @events = @events.order(start_time: :asc)
    elsif params[:collection] == "upcoming"
      @events = @events.where("end_time >= ?", DateTime.now)
      @events = @events.order(start_time: :asc)
    elsif params[:collection] == "pinned"
      @events = @events.where(pinned: true)
      @events = @events.order(start_time: :asc)
    elsif params[:collection] == "past"
      @events = @events.where("end_time < ?", DateTime.now)
      @events = @events.order(start_time: :desc)
    elsif params[:created_by].present?
      profile = Profile.find_by(handle: params[:created_by])
      @events = Event.where(owner: auth_profile)
    elsif params[:collection] == "created_by_me"
      return { reuslt: "error", message: "authentication required" } unless auth_profile
      @events = Event.where(owner: auth_profile)
    elsif params[:collection] == "my_stars"
      return { reuslt: "error", message: "authentication required" } unless auth_profile
      @stars = Comment.where(profile_id: auth_profile.id, comment_type: "star", item_type: "Event")
      @events = @events.where(id: @stars.pluck(:item_id))
    elsif params[:collection] == "my_event"
      return { reuslt: "error", message: "authentication required" } unless auth_profile
      @events = @events.joins(:participants).where(participants: { profile_id: auth_profile.id, status: ["attending","checked"] })
      @events = @events.where("end_time >= ?", DateTime.now)
      @events = @events.order(start_time: :asc)
    else
      @events = @events.order(start_time: :asc)
    end

    if auth_profile && params[:with_stars]
      @with_stars = true
      @stars = Comment.where(item_id: @events.ids, profile_id: auth_profile.id, comment_type: "star", item_type: "Event").all
    end

    # if ["3477", "3502", "lovepunkschiangmai", "auraverse"].include?(params[:group_id])
    #   @group = Group.find_by(id: params[:group_id]) || Group.find_by(handle: params[:group_id])
    # end

    limit = params[:limit] ? params[:limit].to_i : 40
    limit = 1000 if limit > 1000
    @pagy, @events = pagy(@events, limit: limit)
    render template: "api/event/index"
  end

  def discover
    @events = Event.where(status: ["open", "published"], display: ["normal", "pinned"]).where("tags @> ARRAY[?]::varchar[]", [":featured"]).order(start_time: :desc)
    @featured_popups = PopupCity.includes(:group).where("group_tags @> ARRAY[?]::varchar[]", [":featured"]).order(start_date: :desc)
    @cnx_popups = PopupCity.includes(:group).where("group_tags @> ARRAY[?]::varchar[]", [":cnx"]).order(start_date: :desc)
    @popups = PopupCity.includes(:group).where.not("group_tags @> ARRAY[?]::varchar[]", [":cnx"]).order(start_date: :desc)
    @groups = Group.includes(:owner).where("group_tags @> ARRAY[?]::varchar[]", [":top"]).order(handle: :desc)

    render template: "api/event/discover"
  end

  def private_track_list
    profile = current_profile!
    group_id = params[:group_id]
    group = Group.find(group_id)
    @group = group
    my_tracks = Track.where(group_id: group_id, kind: "public").ids + TrackRole.where(group_id: group_id, profile_id: profile.id).pluck(:track_id)
    my_tracks << nil
    @events = Event.where(status: ["open", "published"]).where(group_id: group_id)
    @events = @events.where(display: ["normal", "pinned"])
    @events = @events.where(track_id: my_tracks)

    if params[:start_date].present? && params[:end_date].present?
      start_time = Date.parse(params[:start_date]).in_time_zone(@timezone).at_beginning_of_day
      end_time = Date.parse(params[:end_date]).in_time_zone(@timezone).at_end_of_day
      @events = @events.where("start_time >= ?", start_time).where("end_time <= ?", end_time)
      @events = @events.order(start_time: :asc)
    elsif params["collection"] == "upcoming"
      @events = @events.where("end_time >= ?", DateTime.now)
      @events = @events.order(start_time: :asc)
    elsif params["collection"] == "past"
      @events = @events.where("end_time < ?", DateTime.now)
      @events = @events.order(start_time: :desc)
    else
      @events = @events.order(start_time: :asc)
    end

    limit = params[:limit] || 40
    limit = 500 if limit > 500
    @pagy, @events = pagy(@events, limit: limit)
    render template: "api/event/index"
  end

  def private_list
    profile = current_profile!
    group_id = params[:group_id]
    @events = Event.where(group_id: group_id)

    @events = @events.where(owner: profile)
    .or(@events.where(group_id: Membership.where(profile_id: profile.id, role: ["owner", "manager"]).pluck(:target_id)))
    .or(@events.where(id: EventRole.where(item_type: "Profile", item_id: profile.id).pluck(:event_id)))

    @events = @events.where(status: "published").where(display: ["hidden"])
    @events = @events.order(start_time: :desc).limit(10)
    render json: @events, status: :ok
  end

  def my_event_list
    profile = current_profile!
    if params[:collection] == "my_stars"
      @stars = Comment.where(profile_id: profile.id, comment_type: "star", item_type: "Event")
      @events = Event.where(id: @stars.pluck(:item_id))
      @with_stars = true
    else
      @events = Event.joins(:participants).where(participants: { profile_id: profile.id, status: "attending" })
    end

    @events = @events.order(start_time: :desc)

    limit = params[:limit] ? params[:limit].to_i : 40
    limit = 1000 if limit > 1000
    @pagy, @events = pagy(@events, limit: limit)
    render template: "api/event/index_without_group"
  end

  def starred_event_list
    profile = current_profile!
    @stars = Comment.where(profile_id: profile.id, comment_type: "star", item_type: "Event")
    @events = Event.where(id: @stars.pluck(:item_id))
    @events = @events.order(start_time: :desc)
    @with_stars = true

    limit = params[:limit] ? params[:limit].to_i : 40
    limit = 1000 if limit > 1000
    @pagy, @events = pagy(@events, limit: limit)
    render template: "api/event/index_without_group"
  end

  def created_by_me
    profile = current_profile!
    @events = Event.where(owner: profile)
    @events = @events.order(start_time: :desc).limit(10)
    render json: @events, status: :ok
  end

  def latest_changed
    @events = Event.includes(:group, :venue, :owner).where(status: ["open", "published"]).order(updated_at: :desc)
    @with_stars = false
    limit = params[:limit] ? params[:limit].to_i : 40
    limit = 1000 if limit > 1000
    @pagy, @events = pagy(@events, limit: limit)
    p @events
    render template: "api/event/index_without_group"
  end

  private

  def event_params
    params.require(:event).permit(
      :event_type,
      :title,
      :start_time,
      :end_time,
      :timezone,
      :display,
      :theme,
      :meeting_url,
      :venue_id,
      :location,
      :formatted_address,
      :location_viewport,
      :location_data,
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
      extras: {},
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
      coupons_attributes: [ :id, :selector_type, :label, :code, :receiver_address, :discount_type, :discount, :event_id, :applicable_ticket_ids, :ticket_item_ids, :expires_at, :max_allowed_usages, :order_usage_count, :_destroy ],
      event_roles_attributes: [ :id, :role, :group_id, :event_id, :item_type, :item_id, :email, :nickname, :image_url, :_destroy ],
      )
  end
end
