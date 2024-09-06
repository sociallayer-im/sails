class Api::PointClassController < ApiController
  def create
    profile = current_profile!
    name = params[:name]

    # todo : verify label in model callback
    unless check_badge_domain_label(name)
      render json: { result: "error", message: "invalid name" }
      return
    end
    if params[:group_id]
      group = Group.find(params[:group_id])
      authorize group, :manage?, policy_class: GroupPolicy
    end

    params.permit(
      :name, :title, :sym, :metadata, :content, :image_url,
      :transferable, :revocable
    )
    point_class = PointClass.new(params)
    point_class.update(
      group: group,
      creator: profile,
    )
    render json: { result: "ok", point_class: point_class.as_json }
  end
end
