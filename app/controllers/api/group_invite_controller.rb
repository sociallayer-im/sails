class Api::GroupInviteController < ApiController
  def get
    invite = GroupInvite.includes(:receiver, :sender, :group, :ticket).find(params[:id])
    group = invite.group
    ticket = invite.ticket
    render json: {
      group_invite: invite.as_json(only: [:id, :status, :role, :expires_at, :created_at, :message,
                                          :receiver_id, :sender_id, :group_id,
                                          :receiver_address, :receiver_address_type,
                                          :badge_class_id, :badge_id, :accepted, :ticket_id]).merge(
        receiver: invite.receiver&.as_json(only: [:id, :handle, :nickname, :image_url]),
        sender: invite.sender&.as_json(only: [:id, :handle, :nickname, :image_url]),
        group: group ? group.as_json(only: [:id, :handle, :nickname, :image_url]) : nil,
        ticket: ticket ? ticket.as_json(only: [:id, :title, :ticket_type, :start_date, :end_date, :days_allowed, :tracks_allowed, :status]) : nil
      )
    }
  end

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
    raise AppError.new("invite expired") if group_invite.expires_at && DateTime.now >= group_invite.expires_at

    unless group.is_owner(profile.id) && [ "member", "manager" ].include?(group_invite.role) || [ "member" ].include?(group_invite.role)
      raise AppError.new("invalid role")
    end

    ActiveRecord::Base.transaction do
      group_invite.update(status: "accepted")
      membership = group.add_member(group_invite.receiver_id, group_invite.role)
      render json: { result: "ok", membership: membership.as_json } and return
    end

    render json: { result: "error" }
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
          activity = Activity.create(initiator_id: profile.id, action: "group_invite/update_role", receiver_type: "id", receiver_id: receiver.id, memo: params[:message] || "membership updated")
          invite = { receiver_id: receiver_id, result: "ok", message: "membership updated", receiver_address: receiver_address }
        elsif membership
          invite = { receiver_id: receiver_id, result: "error", message: "membership exists", receiver_address: receiver_address }
        else
          # invite = GroupInvite.create(
          #   sender_id: profile.id,
          #   group_id: group.id,
          #   message: params[:message],
          #   role: role,
          #   expires_at: expires_at,
          #   receiver_id: receiver_id,
          # )
          group.add_member(receiver_id, role)
          activity = Activity.create(item: invite, initiator_id: profile.id, action: "group_invite/send", receiver_type: "id", receiver_id: receiver.id, memo: params[:message] || "membership created")
          invite = { receiver_id: receiver_id, result: "ok", message: "membership created", receiver_address: receiver_address }
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
    raise AppError.new("invite expired") if group_invite.expires_at && DateTime.now >= group_invite.expires_at

    ActiveRecord::Base.transaction do
      group_invite.update(status: "accepted")
      group.add_member(profile.id, group_invite.role)
      create_ticket_item_for_invite(group_invite, profile)
    end

    render json: { result: "ok" }
  end


  def send_invite_with_code
    profile = current_profile!
    group = Group.find(params[:group_id])
    authorize group, :manage?, policy_class: GroupPolicy
    role = params[:role]
    expires_at = (DateTime.now + 30.days)
    code = rand(10_0000..100_0000).to_s

    group_invite = GroupInvite.create(
      sender_id: profile.id,
      group_id: group.id,
      message: params[:message],
      role: role,
      expires_at: expires_at,
      receiver_address_type: "code",
      receiver_address: code,
    )

    render json: { group_invite: group_invite }
  end

  def accept_invite_with_code
    profile = current_profile!
    group_invite = GroupInvite.find_by(id: params[:group_invite_id])
    raise AppError.new("invite not found") if group_invite.nil?
    raise AppError.new("invalid code") unless group_invite.receiver_address == params[:code]
    raise AppError.new("invite has been cancelled") unless group_invite.status == "sending"
    raise AppError.new("invite expired") if group_invite.expires_at && DateTime.now >= group_invite.expires_at
    group = Group.find(group_invite.group_id)
    # Code invites are reusable (anyone with the link can join), so never flip status to "accepted"
    membership = Membership.find_by(profile_id: profile.id, target_id: group.id)
    if membership && membership.role == "member" && group_invite.role != "member"
      membership.update(role: group_invite.role)
      Activity.create(initiator_id: profile.id, action: "group_invite/update_role", receiver_type: "id", receiver_id: profile.id, memo: "membership updated")
    elsif membership.blank?
      ActiveRecord::Base.transaction do
        group.add_member(profile.id, group_invite.role)
        create_ticket_item_for_invite(group_invite, profile)
      end
      Activity.create(initiator_id: profile.id, action: "group_invite/add_member", receiver_type: "id", receiver_id: profile.id, memo: "membership created")
    end
    render json: { result: "ok" }
  end


  def my_pending_invites
    profile = current_profile!
    return render json: { group_invites: [] } unless profile.email.present?

    invites = GroupInvite.includes(:group, :sender, :ticket)
      .where(receiver_address: profile.email, receiver_address_type: "email", status: "sending")
      .where("expires_at > ?", DateTime.now)

    render json: {
      group_invites: invites.as_json(
        only: [:id, :status, :role, :expires_at, :created_at, :message, :receiver_id, :sender_id, :group_id,
               :receiver_address, :receiver_address_type, :badge_class_id, :badge_id, :accepted, :ticket_id],
        include: {
          sender: { only: [:id, :handle, :nickname, :image_url] },
          group: { only: [:id, :handle, :nickname, :image_url] },
          ticket: { only: [:id, :title, :ticket_type, :start_date, :end_date, :days_allowed, :tracks_allowed, :status] }
        }
      )
    }
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

  private

  def create_ticket_item_for_invite(group_invite, profile)
    return unless group_invite.ticket_id.present?

    ticket = group_invite.ticket
    return unless ticket.present?

    ticket_item = TicketItem.create!(
      ticket_id: ticket.id,
      profile_id: profile.id,
      group_id: ticket.group_id,
      ticket_type: "group",
      status: "succeeded",
      auth_type: "invite",
      amount: 0,
      original_price: 0,
      tracks_allowed: ticket.tracks_allowed,
    )
    ticket_item.update!(order_number: (ticket_item.id + 1_000_000).to_s)
  end
end
