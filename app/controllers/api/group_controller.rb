class Api::GroupController < ApiController
  def create
    profile = current_profile!

    handle = params[:handle]
    unless check_profile_handle_and_length(handle)
      render json: { result: "error", message: "invalid handle" }
      return
    end

    if Profile.find_by(handle: handle) || Group.find_by(handle: handle)
      render json: { result: "error", message: "group profile handle exists" }
      return
    end

    group = Group.new(group_params)
    ActiveRecord::Base.transaction do
      group.update(
        handle: handle,
        username: handle,
        can_publish_event: group_params[:can_publish_event] || "all",
        can_join_event: group_params[:can_join_event] || "all",
        can_view_event: group_params[:can_view_event] || "all",
      )
      Domain.create(handle: handle, fullname: "#{handle}.sola.day", item_type: "Group", item_id: group.id)
    end

    group.add_member(profile.id, "owner")
    render json: { result: "ok", group: group }
  end

  def update
    profile = current_profile!
    group = Group.find(params[:id])
    authorize group, :manage?, policy_class: GroupPolicy

    group.update(group_params)
    render json: { result: "ok", group: group }
  end

  def update_track
    profile = current_profile!
    track = Track.find(params[:track_id])
    authorize track.group, :manage?, policy_class: GroupPolicy

    track.update(track_params)
    render json: { result: "ok", track: track }
  end

  def transfer_owner
    profile = current_profile!
    group = Group.find(params[:id])
    authorize group, :own?, policy_class: GroupPolicy

    old_membership = Membership.find_by(role: "owner", target_id: group.id)
    old_owner = old_membership.profile

    new_owner = Profile.find_by(handle: params[:new_owner_handle])
    raise AppError.new("new_owner not exists") unless new_owner

    membership = Membership.find_by(profile_id: new_owner.id, target_id: group.id)
    return render json: { result: "error", message: "new_owner membership not exists" } if membership.nil?
    return render json: { result: "error", message: "new_owner is owner of the group" } if membership.role == "owner"

    old_membership.update(role: "member")
    membership.update(role: "owner")

    render json: { result: "ok", group: group }
  end

  def freeze_group
    profile = current_profile!
    group = Group.find(params[:id])
    authorize group, :own?, policy_class: GroupPolicy

    group.update(status: "freezed")
    render json: { result: "ok", group: group }
  end

  def is_manager
    profile = Profile.find(params[:profile_id])
    group = Group.find(params[:group_id])

    membership = group.is_manager(profile.id)
    render json: { is_member: !!membership, role: membership.try(:role) }
  end

  def is_operator
    profile = Profile.find(params[:profile_id])
    group = Group.find(params[:group_id])

    membership = group.is_operator(profile.id)
    render json: { is_member: !!membership, role: membership.try(:role) }
  end

  def is_member
    profile = Profile.find(params[:profile_id])
    group = Group.find(params[:group_id])

    membership = group.is_member(profile.id)
    render json: { is_member: !!membership, role: membership.try(:role) }
  end

  def remove_member
    profile = Profile.find(params[:profile_id])
    group = Group.find(params[:group_id])
    authorize group, :manage?, policy_class: GroupPolicy

    membership = group.is_member(profile.id)
    membership.destroy
    render json: { result: "ok" }
  end

  def remove_operator
    profile = Profile.find(params[:profile_id])
    group = Group.find(params[:group_id])
    authorize group, :manage?, policy_class: GroupPolicy

    membership = group.is_operator(profile.id)
    membership.update(role: "member")
    render json: { result: "ok" }
  end

  def remove_manager
    profile = Profile.find(params[:profile_id])
    group = Group.find(params[:group_id])
    authorize group, :own?, policy_class: GroupPolicy

    membership = group.is_manager(profile.id)
    membership.update(role: "member")
    render json: { result: "ok" }
  end

  def add_manager
    profile = Profile.find(params[:profile_id])
    group = Group.find(params[:group_id])
    authorize group, :manage?, policy_class: GroupPolicy

    membership = group.is_member(profile.id)
    membership.update(role: "manager")

    render json: { result: "ok" }
  end

  def add_operator
    profile = Profile.find(params[:profile_id])
    group = Group.find(params[:group_id])
    authorize group, :manage?, policy_class: GroupPolicy

    membership = group.is_member(profile.id)
    membership.update(role: "operator")
    render json: { result: "ok" }
  end

  def leave
    profile = Profile.find(params[:profile_id])
    group = Group.find(params[:group_id])
    raise AppError.new("no membership") unless (current_profile!).id == profile.id

    membership = group.is_member(profile.id)
    raise AppError.new("owner cannot leave") if membership.role == "owner"
    membership.destroy
    render json: { result: "ok" }
  end

  private

  def group_params
    params.require(:group).permit(
          :chain, :image_url, :nickname, :about, :status, :group_ticket_enabled,
          :tags, :event_taglist, :venue_taglist, :can_publish_event, :can_join_event, :can_view_event,
          :customizer, :logo_url, :banner_link_url, :banner_image_url,
          :timezone, :location, :metadata, :social_links,
          tracks_attributes: [ :id, :tag, :title, :kind, :icon_url, :about, :start_date, :end_date, :_destroy ],
          )
  end

  def track_params
    params.require(:track).permit(
      :tag, :title, :kind, :icon_url, :about, :start_date, :end_date,
      track_roles_attributes: [ :id, :role, :receiver_address, :profile_id, :_destroy ],
    )
    # todo : auto track role detect with receiver_address/email
  end
end
