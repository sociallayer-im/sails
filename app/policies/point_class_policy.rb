class PointClassPolicy < ApplicationPolicy
  attr_reader :profile, :point

  def initialize(profile, point_class)
    @profile = profile
    @point_class = point_class
  end

  def send?
    if @point_class.group_id
      @point_class.group.is_manager(@profile.id)
    else
      @point_class.creator_id == @profile.id
    end
  end
end
