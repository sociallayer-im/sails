class GroupPolicy < ApplicationPolicy
  attr_reader :profile, :group

  def initialize(profile, group)
    @profile = profile
    @group = group
  end

  def own?
    @group.is_owner(@profile.id)
  end

  def manage?
    @group.status != "freezed" && @group.is_manager(@profile.id)
  end

  def manage_marker?
    @group.status != "freezed" && @group.is_manager(@profile.id)
  end

  def manage_venue?
    @group.status != "freezed" && @group.is_manager(@profile.id)
  end

  def create_event?
    @group.status != "freezed" && (@group.can_publish_event == 'all' || @group.is_member(@profile.id))
  end

  def create_vote?
    @group.status != "freezed" && (@group.can_publish_event == 'all' || @group.is_member(@profile.id))
  end

end
