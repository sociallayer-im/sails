class MarkerPolicy < ApplicationPolicy
  attr_reader :profile, :marker

  def initialize(profile, marker)
    @profile = profile
    @marker = marker
  end

  def update?
    @marker.owner_id == @profile.id || @marker.group && @marker.group.status != "freezed" && @marker.group.is_manager(@profile.id)
  end

end
