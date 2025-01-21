class Api::GroupInviteController < ApiController
  def request_invite
    profile = current_profile!
    group = Group.find(params[:group_id])

    if Membership.find_by(profile_id: profile.id, target_id: group.id, role: params[:role])
      raise AppError.new("membership exists")
    end

    if GroupInvite.find_by(receiver_id: profile.id, group_id: group.id, role: params[:role], status: "requesting")
      raise AppError.new("group invite exists")
    end

    invite = GroupInvite.create(
      receiver_id: profile.id,
      group_id: group.id,
      message: params[:message],
      role: params[:role],
      expires_at: (DateTime.now + 30.days),
      status: "requesting",
    )
    render json: { group_invite: invite }
  end

  def accept_request
    profile = current_profile!
    group_invite = GroupInvite.find_by(id: params[:group_invite_id])
    group = Group.find(group_invite.group_id)
    authorize group, :manage?, policy_class: GroupPolicy

    raise AppError.new("invalid status") unless group_invite.status == "requesting"
    raise AppError.new("invite expired") unless DateTime.now < group_invite.expires_at

    unless group.is_owner(profile.id) && [ "member", "operator", "manager" ].include?(group_invite.role) || [ "member", "operator" ].include?(group_invite.role)
      raise AppError.new("invalid role")
    end

    group_invite.update(status: "accepted")
    membership = group.add_member(group_invite.receiver_id, group_invite.role)

    render json: { result: "ok", membership: membership.as_json }
  end

  # todo : should test on duplicated invite and updating existing members, downgrading members
  def send_invite
    profile = current_profile!
    group = Group.find(params[:group_id])
    authorize group, :manage?, policy_class: GroupPolicy
    role = params[:role]
    expires_at = (DateTime.now + 30.days)

    group_invites = []
    params[:receivers].map do |receiver_address|
      receiver = Profile.find_by(address: receiver_address) || Profile.find_by(handle: receiver_address) || Profile.find_by(email: receiver_address)

      if receiver
        receiver_id = receiver.id

        membership = Membership.find_by(profile_id: receiver.id, target_id: group.id)
        if membership && membership.role == "member" && role != "member"
          membership.update(role: role)
          activity = Activity.create(initiator_id: profile.id, action: "group_invite/update_role", receiver_type: "id", receiver_id: receiver.id)
          invite = { receiver_id: receiver_id, result: "ok", message: "membership updated", receiver_address: receiver_address }
        elsif membership
          invite = { receiver_id: receiver_id, result: "error", message: "membership exists", receiver_address: receiver_address }
        else
          invite = GroupInvite.create(
            sender_id: profile.id,
            group_id: group.id,
            message: params[:message],
            role: role,
            expires_at: expires_at,
            receiver_id: receiver_id,
          )
          activity = Activity.create(item: invite, initiator_id: profile.id, action: "group_invite/send", receiver_type: "id", receiver_id: receiver.id)
        end

        # todo : update memberships_count
        # todo : membership uniqueness
        # todo : test existing member and new member
        # todo : test existing member with manager or owner role
      elsif receiver_address.include? "@"

        invite = GroupInvite.create(
          sender_id: profile.id,
          group_id: group.id,
          message: params[:message],
          role: role,
          expires_at: expires_at,
          receiver_address_type: "email",
          receiver_address: receiver_address,
        )

        mailer = GroupMailer.with(group: group, recipient: invite.receiver_address).group_invite
        mailer.deliver_later
      else
        invite = { receiver: receiver, result: "error", message: "invalid receiver handle", receiver_address: receiver_address }
      end

      group_invites << invite
    end

    render json: { group_invites: group_invites.as_json }
  end

  def accept_invite
    profile = current_profile!
    group_invite = GroupInvite.find_by(id: params[:group_invite_id], status: "sending")
    group = Group.find(group_invite.group_id)
    authorize group_invite, :accept?
    raise AppError.new("invalid status") unless group_invite.status == "sending"

    group_invite.update(status: "accepted")
    raise AppError.new("invite expired") unless DateTime.now < group_invite.expires_at

    group.add_member(profile.id, group_invite.role)
    render json: { result: "ok" }
  end

  def cancel_invite
    profile = current_profile!
    group_invite = GroupInvite.find(params[:group_invite_id])
    group = Group.find(group_invite.group_id)
    authorize group_invite, :accept?

    group_invite.update(status: "cancelled")
    render json: { result: "ok" }
  end

  def revoke_invite
    profile = current_profile!
    group_invite = GroupInvite.find(params[:group_invite_id])
    group = Group.find(group_invite.group_id)
    authorize group_invite, :revoke?

    group_invite.update(status: "cancelled")
    render json: { result: "ok" }
  end
end
