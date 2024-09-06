class GroupInvitePolicy < ApplicationPolicy
  attr_reader :profile, :group_invite

  def initialize(profile, group_invite)
    @profile = profile
    @group_invite = group_invite
  end

  def accept?
    @group_invite.group.status != "freezed" && (@group_invite.receiver_id == @profile.id ||
      @group_invite.receiver_address_type == 'email' && @group_invite.receiver_address == @profile.email)
  end

  def revoke?
    @group_invite.group.status != "freezed" && @group_invite.group.is_manager(@profile.id)
  end
end
