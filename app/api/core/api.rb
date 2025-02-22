module Core
  class AppError < StandardError; end
  class AuthTokenError < StandardError; end

  class ProfileEntity < Grape::Entity
    expose :id, :handle, :nickname, :phone, :sol_address, :far_fid, :far_address, :fuel_address, :mina_address, :zupass, :image_url, :social_links, :created_at, :updated_at
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
    expose :id, :title, :event_type, :track_id, :start_time, :end_time, :timezone,  :status, :display, :pinned, :theme, :meeting_url, :location,:location_data,  :formatted_address, :geo_lat, :geo_lng, :cover_url, :require_approval, :tags, :max_participant, :min_participant, :participants_count, :badge_class_id, :external_url, :recurring_id
    expose :owner, using: Core::ProfileEntity
    expose :group, using: Core::GroupEntity
    expose :event_roles, using: Core::EventRoleEntity
    expose :tickets, using: Core::TicketEntity, if: { type: :full }
    expose :custom_form, using: Core::CustomFormEntity, if: { type: :full }
  end


  class Api < Grape::API
    version 'v1', using: :header, vendor: 'sola'
    format :json

    rescue_from AuthTokenError do |e|
      error!({ result: 'error', message: "invalid auth_token: #{e.message}" }, 403)
    end

    rescue_from AppError do |e|
      error!({ result: 'error', message: e.message }, 400)
    end

    helpers do
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

    get "event/get" do
      @event = Event.includes(:owner).find(params[:id])
      present @event, with: Core::EventEntity
    end

    get "event/discover" do
      @events = Event.includes(:owner, :event_roles).where(status: ["open", "published", "closed"], display: ["normal", "pinned", "public"]).where("tags @> ARRAY[?]::varchar[]", [":featured"]).where("end_time >= ?", DateTime.now).order(start_time: :desc)
      @featured_popups = PopupCity.includes(:group).where("group_tags @> ARRAY[?]::varchar[]", [":featured"]).order(start_date: :desc)
      @popups = PopupCity.includes(:group).where.not("group_tags @> ARRAY[?]::varchar[]", [":cnx", ":bkk"]).order(start_date: :desc)
      @groups = Group.includes(:owner).where("group_tags @> ARRAY[?]::varchar[]", [":top"]).order(handle: :desc)

    end

    # get "event/get", to: "event#get"
    # get "event/discover", to: "event#discover"
    # get "event/list", to: "event#list"
    # get "event/themes_list", to: "event#themes_list"
    # get "event/my_stars", to: "event#my_stars"
    # get "event/list_for_calendar", to: "event#list"
    # get "event/private_list", to: "event#private_list"
    # get "event/private_track_list", to: "event#private_track_list"
    # get "event/my_event_list", to: "event#my_event_list"
    # get "event/starred_event_list", to: "event#starred_event_list"
    # get "event/created_by_me", to: "event#created_by_me"
    # get "event/latest_changed", to: "event#latest_changed"
    # get "event/pending_approval_list", to: "event#pending_approval_list"


  # def get
  #   @event = Event.includes(:owner).find(params[:id])
  #   render template: "api/event/show"
  # end



  end
end
