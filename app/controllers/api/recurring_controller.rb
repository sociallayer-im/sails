class Api::RecurringController < ApiController

  def get
    recurring = Recurring.find(params[:id])
    render json: { recurring: recurring.as_json(only: [:id, :start_time, :end_time, :timezone, :interval, :event_count]) }
  end

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

    recurring = Recurring.create(
      start_time: params[:start_time],
      interval: params[:interval],
      event_count: params[:event_count],
      timezone: params[:timezone],
    )

    events = []
    event_count = params[:event_count].to_i
    event_time = DateTime.parse(params[:start_time])
    duration = DateTime.parse(params[:end_time]) - event_time

    if params[:venue_id]
      check_time = event_time
      event_count.times do
        check_start = check_time
        check_end   = check_time + duration
        if Event.where(venue_id: params[:venue_id])
                .where("start_time < ? AND end_time > ?", check_end, check_start)
                .where.not(status: "cancelled").any?
          return render json: { result: "error", message: "time overlaped in the same venue" }
        end
        if venue
          available, message = venue.check_availability(check_start, check_end, group.timezone)
          return render json: { result: "error", message: message } unless available
        end
        case params[:interval]
        when "day"   then check_time = check_time.advance(days: 1)
        when "week"  then check_time = check_time.advance(weeks: 1)
        when "month" then check_time = check_time.advance(months: 1)
        end
      end
    end

    event_time = DateTime.parse(params[:start_time])
    duration = DateTime.parse(params[:end_time]) - event_time

    event_count.times do
      event = Event.new(event_params)
      event.update(
        start_time: event_time,
        end_time: (event_time + duration),
        recurring_id: recurring.id,
        status: status,
        owner: profile,
        group: group,
        display: event_params[:display] || "normal",
        event_type: "event",
      )

      events << event

      case params[:interval]
      when "day"
        event_time = event_time.advance(days: 1)
      when "week"
        event_time = event_time.advance(weeks: 1)
      when "month"
        event_time = event_time.advance(months: 1)
      end

    end
    group.increment!(:events_count, event_count) if group

    # if @send_approval_email_to_manager
    #   Membership.includes(:profile).where(profile_id: group.id, role: [ "owner", "manager" ]).each do |membership|
    #     if membership.data.present? && membership.data.include?("venue") && membership.profile.email.present?
    #       group_name = group ? (group.nickname || group.handle) : ""
    #       mailer = GroupMailer.with(group_name: group_name, event_id: event.id, recipient: membership.profile.email).venue_review_email
    #       mailer.deliver_later
    #     end
    #   end
    # end

    render json: { result: "ok", recurring: recurring.as_json }
  end

  def update
    recurring = Recurring.find(params[:recurring_id])
    events = Event.where(recurring_id: params[:recurring_id])
    if params[:selector] == 'after'
      events = events.where('id >= ?', params[:after_event_id])
    # elsif params[:selector] == 'all'
    end

    profile = current_profile!
    # todo : recurring owner column
    # authorize event, :update?

    # if params[:venue_id] != event.venue_id
    #   venue = Venue.find_by(id: params[:venue_id], group_id: group.id)
    #   raise AppError.new("group venue not exists") unless venue

    #   if venue.require_approval && !group.is_manager(profile.id)
    #     status = "pending"
    #     send_approval_email_to_manager = true
    #   end
    # end

    if params[:venue_id]
      check_venue = Venue.find_by(id: params[:venue_id])
      check_group = events.first&.group
      event_ids = events.pluck(:id)
      events.each do |event|
        check_start = event.start_time + params[:start_time_diff].to_i.seconds
        check_end   = event.end_time   + params[:end_time_diff].to_i.seconds

        if Event.where(venue_id: params[:venue_id])
                .where("start_time < ? AND end_time > ?", check_end, check_start)
                .where.not(id: event_ids)
                .where.not(status: "cancelled").any?
          return render json: { result: "error", message: "time overlaped in the same venue" }
        end
        if check_venue && check_group
          available, message = check_venue.check_availability(check_start, check_end, check_group.timezone, event.id)
          return render json: { result: "error", message: message } unless available
        end
      end
    end

    events.each do |event|
      update_params = event_params.dup
      if params[:start_time_diff]
        update_params[:start_time] = event.start_time + params[:start_time_diff].to_i.seconds
      end
      if params[:end_time_diff]
        update_params[:end_time] = event.end_time + params[:end_time_diff].to_i.seconds
      end

      # Handle event_roles: destroy previous ones not in new request and ignore _destroy flagged items
      if params[:event_roles_attributes].present?
        # Filter out items with _destroy flag
        new_event_roles = params[:event_roles_attributes].reject { |er| er[:_destroy].present? }

        # Destroy all existing event_roles for this event
        event.event_roles.destroy_all

        # Remove event_roles_attributes from update_params to handle manually
        update_params.delete(:event_roles_attributes)

        # Create new event_roles
        new_event_roles.each do |role_attrs|
          event.event_roles.create(
            role: role_attrs[:role],
            item_type: role_attrs[:item_type],
            item_id: role_attrs[:item_id],
            email: role_attrs[:email],
            nickname: role_attrs[:nickname],
            image_url: role_attrs[:image_url]
          )
        end
      end

      event.update(update_params)
    end

    render json: { result: "ok" }
  end

  def cancel_event
    profile = current_profile!

    events = Event.where(recurring_id: params[:recurring_id])
    if params[:selector] == "after"
      events = events.where("id >= ?", params[:event_id])
    end

    # todo : check only once for each recurring
    events.each do |event|
      authorize event, :update?
      event.update(status: "cancelled")
    end

    render json: { result: "ok" }
  end

  private

  def event_params
    params.permit(
      :title,
      :start_time,
      :end_time,
      :timezone,
      :display,
      :theme,
      :meeting_url,
      :track_id,
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
      requirement_tags: [],
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
          :protocol,
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
      event_roles_attributes: [ :id, :role, :event_id, :item_type, :item_id, :email, :nickname, :image_url, :_destroy ],
      )
  end
end
