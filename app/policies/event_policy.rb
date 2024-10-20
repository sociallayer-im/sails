class EventPolicy < ApplicationPolicy
  attr_reader :profile, :event

  def initialize(profile, event)
    @profile = profile
    @event = event
  end

  def update?
    profile_id = @profile.id
    @event.owner_id == profile_id || @event.group.is_manager(profile_id) ||
    EventRole.find_by(event_id: @event.id, item_type: "Profile", item_id: profile_id) ||
    EventRole.find_by(event_id: @event.id, email: @profile.email) ||
    @event.track && @event.track.manager_ids &&@event.track.manager_ids.include?(profile_id)
    # todo : limiting role as host, co-host, speaker
  end

  def join?
    group = @event.group
    group.can_join_event == "all" || group.is_member(@profile.id)
  end
end
