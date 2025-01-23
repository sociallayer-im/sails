class Api::BadgeClassController < ApiController
  def create
    profile = current_profile!

    # need test
    if params[:group_id]
      group = Group.find(params[:group_id])
      authorize group, :manage?, policy_class: GroupPolicy
    end

    content = Sanitize.fragment(params[:content], Sanitize::Config::RELAXED)

    badge_class = BadgeClass.new(badge_class_params)
    badge_class.update(
      creator_id: profile.id,
      content: content,
    )
    # need domain
    render json: { result: "ok", badge_class: badge_class.as_json }
  end

  private

  def badge_class_params
      params.permit(
        :name,
        :title,
        :group_id,
        :metadata,
        :image_url,
        :transferable,
        :revocable,
        :weighted,
        :encrypted,
      )
  end
end
