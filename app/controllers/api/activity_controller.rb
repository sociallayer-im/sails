class Api::ActivityController < ApiController
  def set_read_status
    profile = current_profile!

    Activity.where(id: params[:ids]).each do |activity|
      if activity.receiver_id == profile.id || activity.receiver_type == "email" && activity.receiver_address == profile.email
        activity.update(has_read: true)
      else
        raise AppError.new("invalid receiver")
      end
    end

    render json: { result: "ok" }
  end
end
