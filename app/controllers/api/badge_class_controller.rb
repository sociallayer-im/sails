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
    p "badge_class.errors.full_messages", badge_class.errors.full_messages
    # need domain
    render json: { result: "ok", badge_class: badge_class.as_json }
  end

  def get
    badge_class = BadgeClass.find(params[:id])
    render json: { badge_class: badge_class.as_json }
  end

  def list
    badge_classes = BadgeClass.all
    badge_classes = badge_classes.where(group_id: params[:group_id]) if params[:group_id].present?
    badge_classes = badge_classes.where(badge_type: params[:badge_type]) if params[:badge_type].present?
    badge_classes = badge_classes.joins(:creator).where(profiles: { handle: params[:creator_handle] }) if params[:creator_handle].present?
    badge_classes = badge_classes.joins(:group).where(groups: { handle: params[:group_handle] }) if params[:group_handle].present?
    limit = [params[:limit].to_i, 200].min
    limit = 20 if limit <= 0
    badge_classes = badge_classes.limit(limit)
    render json: { badge_classes: badge_classes.as_json }
  end

  def invites
    group = Group.find_by!(handle: params[:group_handle])
    badge_classes = BadgeClass.where(group_id: group.id)
    invites = GroupInvite.where(group_id: group.id).where("expires_at > ? OR expires_at IS NULL", Time.now).includes(:receiver, :sender)
    render json: {
      badge_classes: badge_classes.as_json(only: [:id, :title, :image_url, :metadata, :content, :transferable, :badge_type, :display, :permissions]),
      invites: invites.map { |i|
        i.as_json(only: [:id, :status, :role, :expires_at, :message, :receiver_id, :sender_id]).merge(
          receiver: i.receiver&.as_json(only: [:id, :handle, :nickname, :image_url]),
          sender: i.sender&.as_json(only: [:id, :handle, :nickname, :image_url])
        )
      }
    }
  end

  def by_user
    profile = Profile.find_by!(handle: params[:handle])
    group_ids = Membership.where(profile_id: profile.id).pluck(:group_id)
    badge_classes = BadgeClass.where(group_id: group_ids)
    render json: { badge_classes: badge_classes.as_json }
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
        :badge_type,
        :display,
      )
  end
end
