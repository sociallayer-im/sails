class Api::RecurringController < ApiController
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

  def event_params
      params.require(:event).permit(
        :title, :start_time, :end_time, :timezone, :meeting_url, :external_url,
        :venue_id, :location, :formatted_address, :location_viewport, :geo_lat, :geo_lng,
        :cover_url, :require_approval, :extra, :content, :notes, :display, :tags, :operators, :max_participant, :min_participant,
        tickets: [
          :title, :content, :check_badge_class_id, :quantity, :end_time, :need_approval, :status,
          :payment_chain, :payment_token_name, :payment_token_address,
          :payment_target_address, :payment_token_price, :payment_metadata, :_destroy,
          payment_methods_attributes: [ :id, :chain, :kind, :token_name, :token_address, :receiver_address, :price, :_destroy ] ],
        event_roles: [ :id, :role, :group_id, :event_id, :profile_id, :email, :nickname, :image_url, :_destroy ],
        )
    end
end
