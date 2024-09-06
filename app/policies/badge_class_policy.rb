class BadgeClassPolicy < ApplicationPolicy
  attr_reader :profile, :badge_class

  def initialize(profile, badge_class)
    @profile = profile
    @badge_class = badge_class
  end

  def update?
    send?
  end

  def manage?
    send?
  end

  def send?
    if @badge_class.group_id && @badge_class.permissions.include?("group_member_send")
      @badge_class.group.is_member(@profile.id)
    elsif @badge_class.group_id
      @badge_class.group.is_manager(@profile.id)
    else
      @badge_class.creator_id == @profile.id
    end
  end
end
