class Api::ActivityController < ApiController
  def list
    profile_id = params[:profile_id]
    activities = Activity.includes(:initiator, :item)
                         .where(receiver_id: profile_id)
                         .where(action: ["voucher/send_badge", "group_invite/send"])
                         .order(created_at: :desc)
                         .limit(params[:limit] || 20)
    render json: {
      activities: activities.as_json(
        only: [:id, :action, :has_read, :created_at, :item_type, :item_id],
        include: { initiator: { only: [:id, :handle, :nickname, :image_url] } }
      )
    }
  end

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
