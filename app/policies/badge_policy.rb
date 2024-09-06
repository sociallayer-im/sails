class BadgePolicy < ApplicationPolicy
  attr_reader :profile, :badge

  def initialize(profile, badge)
    @profile = profile
    @badge = badge
  end

  def update?
    @badge.creator_id == @profile.id
  end

  def send?
    if @badge.badge.group
      @badge.badge.group.is_manager(@profile.id)
    else
      @badge.creator_id == @profile.id
    end
  end

  def own?
    @badge.owner_id == @profile.id
  end
end
