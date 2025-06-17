require 'csv'

module Core
  class AppError < StandardError; end
  class AuthTokenError < StandardError; end

  class ProfileEntity < Grape::Entity
    expose :id, :handle, :nickname, :phone, :sol_address, :far_fid, :far_address, :fuel_address, :mina_address, :zupass, :image_url, :social_links, :created_at, :updated_at
  end

  class ProfileDetailEntity < Grape::Entity
    expose :id, :handle, :email, :nickname, :phone, :sol_address, :far_fid, :far_address, :fuel_address, :mina_address, :zupass, :image_url, :social_links, :created_at, :updated_at
  end

  class VenueEntity < Grape::Entity
    expose :id, :title, :about, :location, :location_viewport, :location_data, :formatted_address, :link, :capacity, :geo_lat, :geo_lng, :tags
  end

  class GroupEntity < Grape::Entity
    expose :id, :handle, :username, :nickname, :timezone
  end

  class TicketEntity < Grape::Entity
    expose :id, :title, :content, :ticket_type, :quantity, :end_time, :need_approval, :status, :zupass_event_id, :zupass_product_id, :zupass_product_name, :start_date, :end_date, :days_allowed, :tracks_allowed
  end

  class EventRoleEntity < Grape::Entity
    expose :id, :role, :item_id, :item_type, :nickname, :image_url
  end

  class FormFieldEntity < Grape::Entity
    expose :id, :label, :description, :field_type, :field_options, :required, :position
  end

  class CustomFormEntity < Grape::Entity
    expose :id, :title, :description, :status
    expose :form_fields, using: Core::FormFieldEntity
  end

  class EventEntity < Grape::Entity
    expose :id, :title, :event_type, :track_id, :start_time, :end_time, :local_start_time, :local_end_time, :timezone,  :status, :display, :pinned, :theme, :meeting_url, :location,:location_data,  :formatted_address, :geo_lat, :geo_lng, :cover_url, :require_approval, :tags, :max_participant, :min_participant, :participants_count, :badge_class_id, :external_url, :recurring_id
    expose :owner, using: Core::ProfileEntity
    expose :group, using: Core::GroupEntity
    expose :venue, using: Core::VenueEntity
    expose :event_roles, using: Core::EventRoleEntity
    expose :tickets, using: Core::TicketEntity, if: { type: :full }
    expose :custom_form, using: Core::CustomFormEntity, if: { type: :full }
    expose :is_starred, as: :is_starred, if: lambda { |instance, options|
      instance.is_starred = options[:with_stars].present? && options[:stars].find {|x| x == instance.id }.present?
      options[:with_stars]
    }
    expose :is_attending, as: :is_attending, if: lambda { |instance, options|
      instance.is_attending = options[:with_attending].present? && options[:attendings].find {|x| x == instance.id }.present?
      options[:with_attending]
    }
  end

  class PopupCityEntity < Grape::Entity
    expose :id, :title, :location, :start_date, :end_date, :group_tags, :website, :image_url
    expose :group, using: Core::GroupEntity
  end

  class Api < Grape::API
    format :json

    rescue_from AuthTokenError do |e|
      error!({ result: 'error', message: "invalid auth_token: #{e.message}" }, 403)
    end

    rescue_from AppError do |e|
      error!({ result: 'error', message: e.message }, 400)
    end



    helpers do
      include Pagy::Backend

      def fetch_bearer_token
        headers['Authorization']&.split(' ')[1]
      end

      def current_profile
        return Profile.find_by(address: @address) if @address

        begin
          token = params[:auth_token] || fetch_bearer_token
          fetched_token = Doorkeeper::AccessToken.find_by(token: token, revoked_at: nil)
          if fetched_token
            @profile_id = fetched_token.resource_owner_id
            @profile = Profile.find_by(id: @profile_id)
          else
            decoded_token = JWT.decode token, $hmac_secret, true, { algorithm: 'HS256' }
            @profile_id = decoded_token[0]['id']
            @profile = Profile.find_by(id: @profile_id)
          end
        rescue Exception => e
          Rails.logger.info e.message
          nil
        end
      end

      def current_profile!
        return Profile.find_by(address: @address) if @address

        raise AuthTokenError.new('missing auth_token') unless params[:auth_token] || fetch_bearer_token

        begin
          token = params[:auth_token] || fetch_bearer_token
          fetched_token = Doorkeeper::AccessToken.find_by(token: token, revoked_at: nil)
          if fetched_token
            @profile_id = fetched_token.resource_owner_id
            @profile = Profile.find_by(id: @profile_id)
          else
            decoded_token = JWT.decode token, $hmac_secret, true, { algorithm: 'HS256' }
            @profile_id = decoded_token[0]['id']
            @profile = Profile.find_by(id: @profile_id)
          end
        rescue Exception => e
          Rails.logger.info e.message
          raise AuthTokenError.new(e.message)
        end

        @profile = Profile.find_by(id: @profile_id)
        raise AppError.new('profile is not found') unless @profile

        @profile
      end
    end

    get :hello do
      { hello: 'world' }
    end

    get "profile/me" do
      current_profile
    end

    get "profile/get_by_email" do
      profile = Profile.find_by(email: params[:email])
      present :profile, profile, with: Core::ProfileEntity
    end

    get "profile/get_by_handle" do
      profile = Profile.find_by(handle: params[:handle])
      present :profile, profile, with: Core::ProfileEntity
    end

    get "profile/get" do
      profile = Profile.find_by(id: params[:id]) || Profile.find_by(handle: params[:id])
      present :profile, profile, with: Core::ProfileEntity
    end

    get "event/themes" do
      themes = Event.where(group_id: params[:group_id]).distinct(:theme).pluck(:theme)
      { themes: themes }
    end

    get "event/get" do
      @event = Event.includes(:owner).find(params[:id])
      present :event, @event, with: Core::EventEntity
    end

    get "event/discover" do
      @events = Event.includes(:owner, :event_roles).where(status: ["open", "published", "closed"], display: ["normal", "pinned", "public"]).where("tags @> ARRAY[?]::varchar[]", [":featured"]).where("end_time >= ?", DateTime.now).order(start_time: :desc)
      @featured_popups = PopupCity.includes(:group).where("group_tags @> ARRAY[?]::varchar[]", [":featured"]).order(start_date: :desc)
      @popups = PopupCity.includes(:group).order(start_date: :desc)
      @groups = Group.includes(:owner).where("group_tags @> ARRAY[?]::varchar[]", [":top"]).order(handle: :desc)

      present :events, @events, with: Core::EventEntity
      present :featured_popups, @featured_popups, with: Core::PopupCityEntity
      present :popups, @popups, with: Core::PopupCityEntity
      present :groups, @groups, with: Core::GroupEntity
    end

    get "event/my_starred" do
      profile = current_profile!
      @stars = Comment.where(profile_id: profile.id, comment_type: "star", item_type: "Event").pluck(:item_id)
      @events = Event.where(id: @stars).order(start_time: :desc)
      @with_stars = true

      limit = params[:limit] ? params[:limit].to_i : 40
      limit = 1000 if limit > 1000
      @events = @events.page(params[:page]).per(limit)

      @stars = @events.ids

      if profile && params[:with_attending]
        @with_attending = true
        @attendings = Participant.where(profile_id: profile.id, status: ["attending", "checked"]).pluck(:event_id)
      end

      present :events, @events, with: Core::EventEntity, with_stars: @with_stars, stars: @stars, with_attending: @with_attending, attendings: @attendings
    end

    get "event/attending" do
      profile = Profile.find_by(id: params[:profile_id]) || Profile.find_by(handle: params[:profile_id])

      @events = Event.joins(:participants).where(participants: { profile_id: profile.id, status: ["attending", "checked"] })
      if params[:collection] == "upcoming"
        @events = @events.where("end_time >= ?", DateTime.now)
      elsif params[:collection] == "past"
        @events = @events.where("end_time < ?", DateTime.now)
      end
      @events = @events.order(created_at: :desc)

      limit = params[:limit] ? params[:limit].to_i : 40
      limit = 1000 if limit > 1000
      @events = @events.page(params[:page]).per(limit)

      if profile && params[:with_stars]
        @with_stars = true
        @stars = Comment.where(item_id: @events.ids, profile_id: profile.id, comment_type: "star", item_type: "Event").pluck(:item_id)
      end

      if profile && params[:with_attending]
        @with_attending = true
        @attendings = Participant.where(profile_id: profile.id, status: ["attending", "checked"]).pluck(:event_id)
      end

      present :events, @events, with: Core::EventEntity, with_stars: @with_stars, stars: @stars, with_attending: @with_attending, attendings: @attendings
    end

    get "event/my_attending" do
      profile = current_profile!

      @events = Event.joins(:participants).where(participants: { profile_id: profile.id, status: ["attending", "checked"] })
      if params[:collection] == "upcoming"
        @events = @events.where("end_time >= ?", DateTime.now)
      elsif params[:collection] == "past"
        @events = @events.where("end_time < ?", DateTime.now)
      end
      @events = @events.order(created_at: :desc)

      limit = params[:limit] ? params[:limit].to_i : 40
      limit = 1000 if limit > 1000
      @events = @events.page(params[:page]).per(limit)

      if profile && params[:with_stars]
        @with_stars = true
        @stars = Comment.where(item_id: @events.ids, profile_id: profile.id, comment_type: "star", item_type: "Event").pluck(:item_id)
      end

      if profile && params[:with_attending]
        @with_attending = true
        @attendings = Participant.where(profile_id: profile.id, status: ["attending", "checked"]).pluck(:event_id)
      end

      present :events, @events, with: Core::EventEntity, with_stars: @with_stars, stars: @stars, with_attending: @with_attending, attendings: @attendings
    end

    get "event/my_created" do
      profile = current_profile!
      @events = Event.where(owner: profile).order(created_at: :desc)

      limit = params[:limit] ? params[:limit].to_i : 40
      limit = 1000 if limit > 1000
      @events = @events.page(params[:page]).per(limit)

      if profile && params[:with_stars]
        @with_stars = true
        @stars = Comment.where(item_id: @events.ids, profile_id: profile.id, comment_type: "star", item_type: "Event").pluck(:item_id)
      end

      if profile && params[:with_attending]
        @with_attending = true
        @attendings = Participant.where(profile_id: profile.id, status: ["attending", "checked"]).pluck(:event_id)
      end

      present :events, @events, with: Core::EventEntity, with_stars: @with_stars, stars: @stars, with_attending: @with_attending, attendings: @attendings
    end

    get "event/my_private" do
      profile = current_profile!
      group_ids = Membership.where(profile_id: profile.id, role: ["owner", "manager"]).pluck(:target_id)

      owned_events = Event.where(owner: profile)
      group_events = Event.where(group_id: group_ids)
      role_event_ids = EventRole.where(item_type: "Profile", item_id: profile.id).select(:event_id)
      role_events = Event.where(id: role_event_ids)

      @events = owned_events
        .or(group_events)
        .or(role_events)
        .where(status: "published").where(display: ["hidden"]).order(start_time: :desc)

        limit = params[:limit] ? params[:limit].to_i : 40
        limit = 1000 if limit > 1000
        @events = @events.page(params[:page]).per(limit)

        if profile && params[:with_stars]
          @with_stars = true
          @stars = Comment.where(item_id: @events.ids, profile_id: profile.id, comment_type: "star", item_type: "Event").pluck(:item_id)
        end

        if profile && params[:with_attending]
          @with_attending = true
          @attendings = Participant.where(profile_id: profile.id, status: ["attending", "checked"]).pluck(:event_id)
        end

        present :events, @events, with: Core::EventEntity, with_stars: @with_stars, stars: @stars, with_attending: @with_attending, attendings: @attendings
    end

    get "event/my_private_track" do
      profile = current_profile!
      @group = Group.find_by(id: params[:group_id]) || Group.find_by(handle: params[:group_id])
      group_id = @group.id

      my_tracks = Track.where(group_id: group_id, kind: "public").ids + TrackRole.where(group_id: group_id, profile_id: profile.id).pluck(:track_id)
      my_tracks << nil
      @events = Event.where(group_id: group_id).where(status: ["open", "published", "closed"]).where(display: ["normal", "pinned", "public"])
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

      limit = params[:limit] ? params[:limit].to_i : 40
      limit = 1000 if limit > 1000
      @events = @events.page(params[:page]).per(limit)

      if profile && params[:with_stars]
        @with_stars = true
        @stars = Comment.where(item_id: @events.ids, profile_id: profile.id, comment_type: "star", item_type: "Event").pluck(:item_id)
      end

      if profile && params[:with_attending]
        @with_attending = true
        @attendings = Participant.where(profile_id: profile.id, status: ["attending", "checked"]).pluck(:event_id)
      end

      present :events, @events, with: Core::EventEntity, with_stars: @with_stars, stars: @stars, with_attending: @with_attending, attendings: @attendings
    end

    get "event/pending" do
      group_ids = Membership.where(profile_id: current_profile.id, role: ["owner", "manager"]).pluck(:target_id)
      @events = Event.includes(:owner, :event_roles).where(status: "pending").where(group_id: group_ids).order(created_at: :desc)

      limit = params[:limit] ? params[:limit].to_i : 40
      limit = 1000 if limit > 1000
      @events = @events.page(params[:page]).per(limit)

      if profile && params[:with_stars]
        @with_stars = true
        @stars = Comment.where(item_id: @events.ids, profile_id: profile.id, comment_type: "star", item_type: "Event").pluck(:item_id)
      end

      if profile && params[:with_attending]
        @with_attending = true
        @attendings = Participant.where(profile_id: profile.id, status: ["attending", "checked"]).pluck(:event_id)
      end

      present :events, @events, with: Core::EventEntity, with_stars: @with_stars, stars: @stars, with_attending: @with_attending, attendings: @attendings
    end

    get "event/list" do
      @group = Group.find_by(id: params[:group_id]) || Group.find_by(handle: params[:group_id])
      group_id = @group.id

      if @group.status == "freezed"
        error!({ result: 'error', message: "group is freezed" }, 400)
      end

      profile = current_profile
      if profile
        if @group.is_manager(profile.id)
          pub_tracks = Track.where(group_id: group_id).ids
          pub_tracks << nil
        elsif @group.group_union.present?
          managing_groups = Membership.where(profile_id: profile.id, role: ["owner", "manager", "operator"], id: @group.group_union).ids
          pub_tracks = Track.where(group_id: managing_groups).ids + Track.where(group_id: @group.group_union, kind: "public").ids + TrackRole.where(group_id: @group.group_union, profile_id: profile.id).pluck(:track_id)
          pub_tracks = pub_tracks.compact
          pub_tracks << nil
        else
          pub_tracks = Track.where(group_id: group_id, kind: "public").ids + TrackRole.where(group_id: group_id, profile_id: profile.id).pluck(:track_id)
          pub_tracks << nil
        end
      else
        pub_tracks = Track.where(group_id: group_id, kind: "public").ids
        pub_tracks << nil
      end

      if params[:track_id] && !pub_tracks.include?(params[:track_id].to_i)
        error!({ result: 'error', message: "track not found" }, 400)
      end

      event_group_ids = @group.group_union.present? ? [@group.id] + @group.group_union : [@group.id]

      @timezone = @group.timezone || params[:timezone] || 'UTC'
      @events = Event.includes(:group, :venue, :owner, :event_roles).where(status: ["open", "published", "closed"]).where(group_id: event_group_ids)
      if @group.can_view_event == "member"
        if (profile.blank? || !@group.is_member(profile.id))
          @events = @events.where("events.tags @> ARRAY[?]::varchar[]", ["public"])
        end
      elsif params[:private_event].present? && profile && @group.is_manager(profile.id)
        @events = @events.where(display: "private")
      elsif params[:private_event].present?
        @events = @events.where(display: "none")
      else
        @events = @events.where(display: ["normal", "pinned", "public"])
      end

      if params[:track_id]
        @events = @events.where(track_id: params[:track_id])
      else
        @events = @events.where(track_id: pub_tracks)
      end
      if params[:tags]
        tags = params[:tags].split(",")
        @events = @events.where("events.tags && ARRAY[:options]::varchar[]", options: tags)
        # @events = @events.where("tags @> ARRAY[?]::varchar[]", tags)
      end
      if params[:search_title]
        @events = @events.where("events.title Ilike ?", "%#{params[:search_title]}%")
      end
      if params[:venue_id]
        @events = @events.where(venue_id: params[:venue_id])
      end
      if params[:theme]
        @events = @events.where(theme: params[:theme])
      end
      if params[:pinned].present?
        @events = @events.where(pinned: true)
      end

      if params[:skip_multiday].present?
        @events =  @events.where("end_time - start_time <= interval '1 day'")
      end
      if params[:skip_recurring].present?
        @events = @events.where(recurring_id: nil)
      end

      if params[:start_date].present? && params[:end_date].present?
        start_time = Date.parse(params[:start_date]).in_time_zone(@timezone).at_beginning_of_day
        end_time = Date.parse(params[:end_date]).in_time_zone(@timezone).at_end_of_day
        @events = @events.where("start_time <= ? AND end_time >= ?", end_time, start_time)
      elsif params[:start_time].present? && params[:end_time].present?
        start_time = params[:start_time]
        end_time = params[:end_time]
        @events = @events.where("start_time <= ? AND end_time >= ?", end_time, start_time)
      elsif params[:collection] == "upcoming"
        @events = @events.where("end_time >= ?", DateTime.now)
      elsif params[:collection] == "past"
        @events = @events.where("end_time < ?", DateTime.now)
      elsif params[:collection] == "pinned"
        @events = @events.where(pinned: true)
      end
      @events = @events.order(start_time: :asc)

      limit = params[:limit] ? params[:limit].to_i : 40
      limit = 1000 if limit > 1000
      @events = @events.page(params[:page]).per(limit)

      if profile && params[:with_stars]
        @with_stars = true
        @stars = Comment.where(item_id: @events.ids, profile_id: profile.id, comment_type: "star", item_type: "Event").pluck(:item_id)
      end

      if profile && params[:with_attending]
        @with_attending = true
        @attendings = Participant.where(profile_id: profile.id, status: ["attending", "checked"]).pluck(:event_id)
      end

      # puts "--------------------------------"
      # p @events.pluck(:id, :title, :start_time, :end_time)
      # puts "--------------------------------"

      # @events.pluck(:id, :title, :start_time, :end_time).as_json

      present :events, @events, with: Core::EventEntity, with_stars: @with_stars, stars: @stars, with_attending: @with_attending, attendings: @attendings
    end

    get "participant/csv" do
      group = Group.find_by(id: params[:group_id]) || Group.find_by(handle: params[:group_id])
      evs = group.events.where.not(status: "cancelled")

      if params[:start_date].present? && params[:end_date].present?
        timezone = group.timezone || params[:timezone] || 'UTC'
        start_time = Date.parse(params[:start_date]).in_time_zone(timezone).at_beginning_of_day
        end_time = Date.parse(params[:end_date]).in_time_zone(timezone).at_end_of_day
        evs = evs.where("start_time <= ? AND end_time >= ?", end_time, start_time)
      end

      participants = Participant.includes(:event, :profile).where(event: evs).where.not(status: "cancelled").order(:event_id)

      fields = ['event_id', 'event_title', 'handle', 'nickname', 'email', 'created_at']
      csv_data = CSV.generate do |csv|
        csv << fields
        participants.each do |participant|
          csv << [participant.event_id, participant.event.title, participant.profile.handle, participant.profile.nickname, participant.profile.email, participant.created_at]
        end
      end

      header['Content-Type'] = 'text/csv'
      header['Content-Disposition'] = 'attachment; filename=participants.csv'
      env['api.format'] = :binary
      body csv_data
    end

    get "event/csv" do
      group = Group.find_by(id: params[:group_id]) || Group.find_by(handle: params[:group_id])
      evs = group.events.includes(:owner)


      if params[:start_date].present? && params[:end_date].present?
        timezone = group.timezone || params[:timezone] || 'UTC'
        start_time = Date.parse(params[:start_date]).in_time_zone(timezone).at_beginning_of_day
        end_time = Date.parse(params[:end_date]).in_time_zone(timezone).at_end_of_day
        evs = evs.where("start_time <= ? AND end_time >= ?", end_time, start_time)
      end

      evs = evs.where.not(status: "cancelled").order(start_time: :asc)

      fields = ['event_id', 'event_title', 'start_time', 'end_time', 'owner_id', 'owner_handle', 'owner_email', 'owner_nickname', 'owner_image_url']
      csv_data = CSV.generate do |csv|
        csv << fields
        evs.each do |event|
          csv << [event.id, event.title, event.start_time, event.end_time, event.owner.id, event.owner.handle, event.owner.email, event.owner.nickname, event.owner.image_url]
        end
      end

      header['Content-Type'] = 'text/csv'
      header['Content-Disposition'] = 'attachment; filename=events.csv'
      env['api.format'] = :binary
      body csv_data
    end

    get "profile/organizers" do
      group = Group.find_by(id: params[:group_id]) || Group.find_by(handle: params[:group_id])
      events = Event.includes(:owner).where(group_id: group.id, status: "published", display: ["normal", "pinned", "public"]).order(owner_id: :asc, created_at: :desc).limit(100).all
      # @organizers = events.map(&:owner).uniq

      items = []
      events.each do |event|
        items << {
          id: event.id,
          title: event.title,
          start_time: event.start_time,
          end_time: event.end_time,
          owner_id: event.owner.id,
          owner_handle: event.owner.handle,
          owner_email: event.owner.email,
          owner_nickname: event.owner.nickname,
          owner_image_url: event.owner.image_url,
        }
      end

      items
    end

  end
end
