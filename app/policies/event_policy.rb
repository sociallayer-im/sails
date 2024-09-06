class EventPolicy < ApplicationPolicy
  attr_reader :profile, :event

  def initialize(profile, event)
    @profile = profile
    @event = event
  end

  def update?
    @event.owner_id == @profile.id || @event.group.is_manager(@profile.id) ||
    EventRole.find_by(event_id: @event.id, profile_id: @profile.id) ||
    EventRole.find_by(event_id: @event.id, email: @profile.email)
    # todo : limiting role as host, co-host, speaker
  end

  def join?
    group = @event.group
    group.can_join_event == "all" || group.is_member(@profile.id)
  end
end
