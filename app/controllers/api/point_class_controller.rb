class Api::PointClassController < ApiController
  def create
    profile = current_profile!
    name = params[:point_class][:name]

    # todo : verify label in model callback
    unless check_badge_domain_label(name)
      render json: { result: "error", message: "invalid name" }
      return
    end
    if params[:group_id]
      group = Group.find(params[:group_id])
      authorize group, :manage?, policy_class: GroupPolicy
    end

    # todo : check sym and name

    point_class = PointClass.new(point_class_params)
    point_class.update(
      group: group,
      creator: profile,
    )

    render json: { result: "ok", point_class: point_class.as_json }
  end


  private

  def point_class_params
    params.require(:point_class).permit(
      :name, :title, :sym, :metadata, :content, :image_url,
      :transferable, :revocable
    )
  end
end
