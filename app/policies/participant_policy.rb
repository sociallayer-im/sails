class ParticipantPolicy < ApplicationPolicy
  attr_reader :profile, :participant

  def initialize(profile, participant)
    @profile = profile
    @participant = participant
  end

  def update?
    @participant.event.owner_id == @profile.id || @participant.event.group.is_manager(@profile.id) ||
    @participant.profile_id == @profile.id
  end
end
