class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  include Pagy::Backend
  allow_browser versions: :modern

  before_action :set_current

  private
    def set_current
      Current.user_agent = request.user_agent
      Current.ip_address = request.ip
      Current.session = Profile.find_by_id(cookies.signed[:profile_id])
    end
end
