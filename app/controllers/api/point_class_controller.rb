class Api::PointClassController < ApiController
  def create
    profile = current_profile!
    if params[:group_id]
      group = Group.find(params[:group_id])
      authorize group, :manage?, policy_class: GroupPolicy
    end

    point_class = PointClass.new(point_class_params)
    if point_class.update(
      group: group,
      creator: profile,
    )
      render json: { result: "ok", point_class: point_class.as_json }
    else
      render json: { result: "error", message: point_class.errors.full_messages.join(", ") },
        status: :unprocessable_entity
    end
  end


  private

  def point_class_params
    params.require(:point_class).permit(
      :name, :title, :sym, :metadata, :content, :image_url,
      :transferable, :revocable
    )
  end
end
