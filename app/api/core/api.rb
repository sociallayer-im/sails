module Core
  class AppError < StandardError; end
  class AuthTokenError < StandardError; end

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
  end
end
