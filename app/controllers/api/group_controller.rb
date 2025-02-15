class Api::GroupController < ApiController
  def create
    profile = current_profile!

    handle = params[:handle]
    unless check_profile_handle_and_length(handle)
      raise AppError.new("invalid handle")
    end

    if Profile.find_by(handle: handle) || Group.find_by(handle: handle)
      raise AppError.new("group profile handle exists")
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

  def add_track
    profile = current_profile!
    group = Group.find(params[:id])
    authorize group, :manage?, policy_class: GroupPolicy

    group.tracks.create(track_params)
    render json: { result: "ok", group: group }
  end

  def remove_track
    profile = current_profile!
    track = Track.find(params[:track_id])
    authorize track.group, :manage?, policy_class: GroupPolicy

    track.destroy
    render json: { result: "ok", group: track.group }
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
    raise AppError.new("new_owner membership not exists") if membership.nil?
    raise AppError.new("new_owner is owner of the group") if membership.role == "owner"

    ActiveRecord::Base.transaction do
      old_membership.update(role: "member")
      membership.update(role: "owner")
    end

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

  def get
    @group = Group.find(params[:id])
  end

  def icalendar
    group = Group.find_by(username: params[:group_name]) || Group.find(params[:group_id])
    pub_tracks = Track.where(group_id: params[:group_id], kind: "public").ids
    pub_tracks << nil

    cal = Icalendar::Calendar.new
    events = Event.where(group_id: group.id)
    events = events.where('start_time > ? and start_time < ?', DateTime.now - 7.days, DateTime.now + 14.days)
    events = events.where(track_id: pub_tracks)
    events.each do |ev|
        cal.event do |e|
          e.dtstart     = Icalendar::Values::DateTime.new(ev.start_time.in_time_zone("Etc/UTC"))
          e.dtend       = Icalendar::Values::DateTime.new(ev.end_time.in_time_zone("Etc/UTC"))
          e.summary     = ev.title || ""
          e.uid         = "sola-#{ev.id}"
          e.status      = "CONFIRMED"
          e.organizer   = Icalendar::Values::CalAddress.new("mailto:send@app.sola.day", cn: group.username)
          e.url         = "https://app.sola.day/event/detail/#{ev.id}"
          e.location    = ev.meeting_url || "https://app.sola.day/event/detail/#{ev.id}"
        end
    end
    ics = cal.to_ical

    response.headers['Content-Disposition'] = 'attachment; filename="sola.ics"'
    render plain: ics
  end

  private

  def group_params
    params.require(:group).permit(
          :chain, :image_url, :nickname, :about, :status, :group_ticket_enabled,
          :tags, :event_taglist, :venue_taglist, :can_publish_event, :can_join_event, :can_view_event,
          :customizer, :logo_url, :banner_link_url, :banner_image_url,
          :timezone, :location, :metadata,
          :event_enabled, :map_enabled,
          event_tags: [],
          group_tags: [],
          # {social_links: [:twitter, :github, :discord, :telegram, :ens, :lens, :nostr]},
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
