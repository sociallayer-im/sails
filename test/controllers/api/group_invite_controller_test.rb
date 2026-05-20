require "test_helper"

class Api::GroupInviteControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "api#group/send_invite" do
    profile = Profile.find_by(handle: "cookie")
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    post api_group_send_invite_url, params: {
      auth_token: auth_token,
      group_id: group.id,
      role: "member",
      receivers: [ "mooncake" ],
      message: "please join the group"
     }
    assert_response :success
    assert group.is_member(profile2.id)
  end

  test "api#group/send_invite to existing member for upgrading" do
    profile = Profile.find_by(handle: "cookie")
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    Membership.create(profile_id: profile2.id, target_id: group.id, role: "member", status: "active")

    assert_difference "GroupInvite.count", 0 do
    post api_group_send_invite_url, params: {
      auth_token: auth_token,
      group_id: group.id,
      role: "manager",
      receivers: [ "mooncake" ],
      message: "please join the group"
     }
    end
    assert_response :success
    assert Membership.find_by(profile_id: profile2.id, target_id: group.id).role == "manager"
  end

  test "api#group/send_invite to existing manager without downgrading" do
    profile = Profile.find_by(handle: "cookie")
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    Membership.create(profile_id: profile2.id, target_id: group.id, role: "manager", status: "active")

    assert_difference "GroupInvite.count", 0 do
    post api_group_send_invite_url, params: {
      auth_token: auth_token,
      group_id: group.id,
      role: "member",
      receivers: [ "mooncake" ],
      message: "please join the group"
     }
    end
    assert_response :success
    assert group.is_manager(profile2.id)
  end

  test "api#group/send_invite to new email and accept" do
    profile = Profile.find_by(handle: "cookie")
    profile2 = Profile.find_by(handle: "dimsum")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    assert_difference "GroupInvite.count", 1 do
    post api_group_send_invite_url, params: {
      auth_token: auth_token,
      group_id: group.id,
      role: "manager",
      receivers: [ "dimsum@mail.com" ],
      message: "please join the group"
     }
    end
    assert_response :success

    perform_enqueued_jobs
    email = ActionMailer::Base.deliveries.last
    assert_equal [ "dimsum@mail.com" ], email.to
    assert_equal "Social Layer Group Invite", email.subject

    profile2.update(email: "dimsum@mail.com")
    auth_token2 = profile2.gen_auth_token
    invite = GroupInvite.find_by(group: group, sender: profile)

    post api_group_accept_invite_url, params: {
      auth_token: auth_token2,
      group_invite_id: invite.id
    }
    assert_response :success

    group_member = group.is_member(profile2.id)
    assert group_member
    assert_equal "manager", group_member.role
  end

  test "api#group/accept_invite" do
    profile = Profile.find_by(handle: "mooncake")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")
    invite = GroupInvite.create!(group: group, sender: profiles(:one), receiver: profile, expires_at: DateTime.now + 30.days, role: "member", message: "please join the group")

    post api_group_accept_invite_url, params: {
      auth_token: auth_token,
      group_invite_id: invite.id
    }
    assert_response :success

    group_member = group.is_member(profile.id)
    assert group_member
    assert_equal "member", group_member.role
  end

  test "api#group/cancel_invite" do
    profile = Profile.find_by(handle: "mooncake")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")
    invite = GroupInvite.create!(group: group, sender: profiles(:one), receiver: profile, expires_at: DateTime.now + 30.days, role: "member", message: "please join the group")

    post api_group_cancel_invite_url, params: {
      auth_token: auth_token,
      group_invite_id: invite.id
    }
    assert_response :success

    group_invite = GroupInvite.find_by(group: group, receiver: profile)
    assert group_invite.status == "cancelled"
  end

  test "api#group/revoke_invite" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")
    invite = GroupInvite.create!(group: group, sender: profiles(:one), receiver: profile, expires_at: DateTime.now + 30.days, role: "member", message: "please join the group")

    post api_group_revoke_invite_url, params: {
      auth_token: auth_token,
      group_invite_id: invite.id
    }
    assert_response :success

    group_invite = GroupInvite.find_by(group: group, receiver: profile)
    assert group_invite.status == "cancelled"
  end

  test "api#group/request_invite" do
    profile = Profile.find_by(handle: "mooncake")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    post api_group_request_invite_url, params: {
      auth_token: auth_token,
      group_id: group.id,
      role: "member",
      message: "I would like to join the group"
    }
    assert_response :success

    group_invite = GroupInvite.find_by(group: group, receiver: profile)
    assert group_invite
    assert_equal "requesting", group_invite.status
    assert_equal "member", group_invite.role
    assert_equal "I would like to join the group", group_invite.message
  end

  test "api#group/accept_request" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")
    requester = profiles(:two)
    group_invite = GroupInvite.create!(group: group, sender: profile, receiver: requester, expires_at: DateTime.now + 30.days, role: "member", message: "please join the group", status: "requesting")

    post api_group_accept_request_url, params: {
      auth_token: auth_token,
      group_invite_id: group_invite.id
    }
    assert_response :success

    group_invite.reload
    assert_equal "accepted", group_invite.status

    assert group.is_member(requester.id)
    assert_equal "member", group.is_member(requester.id).role
  end

  # --- ticket_id on invite ---

  test "accept_invite with ticket_id creates a TicketItem" do
    profile = profiles(:two)
    auth_token = profile.gen_auth_token
    group = groups(:one)

    ticket = Ticket.create!(
      title: "group pass", ticket_type: "group", group_id: group.id,
      event_id: events(:with_ticket).id,
      start_date: Date.today, end_date: Date.today + 30.days,
      tracks_allowed: [ 1, 2 ], quantity: 100, status: "normal"
    )
    invite = GroupInvite.create!(
      group: group, sender: profiles(:one), receiver: profile,
      expires_at: DateTime.now + 30.days, role: "member", ticket_id: ticket.id
    )

    assert_difference "TicketItem.count", 1 do
      post api_group_accept_invite_url, params: { auth_token: auth_token, group_invite_id: invite.id }
    end
    assert_response :success

    ti = TicketItem.last
    assert_equal ticket.id, ti.ticket_id
    assert_equal profile.id, ti.profile_id
    assert_equal group.id, ti.group_id
    assert_equal "group", ti.ticket_type
    assert_equal "succeeded", ti.status
    assert_equal "invite", ti.auth_type
    assert_equal 0, ti.amount
    assert_equal [ "1", "2" ], ti.tracks_allowed
    assert_equal (ti.id + 1_000_000).to_s, ti.order_number
  end

  test "accept_invite without ticket_id does not create a TicketItem" do
    profile = profiles(:two)
    auth_token = profile.gen_auth_token
    group = groups(:one)
    invite = GroupInvite.create!(
      group: group, sender: profiles(:one), receiver: profile,
      expires_at: DateTime.now + 30.days, role: "member"
    )

    assert_no_difference "TicketItem.count" do
      post api_group_accept_invite_url, params: { auth_token: auth_token, group_invite_id: invite.id }
    end
    assert_response :success
  end

  test "accept_invite_with_code with ticket_id creates a TicketItem on first join" do
    profile = profiles(:two)
    auth_token = profile.gen_auth_token
    group = groups(:one)

    ticket = Ticket.create!(
      title: "code pass", ticket_type: "group", group_id: group.id,
      event_id: events(:with_ticket).id,
      days_allowed: [ Date.today, Date.today + 1 ],
      tracks_allowed: [ 3 ], quantity: 100, status: "normal"
    )
    invite = GroupInvite.create!(
      group: group, sender: profiles(:one),
      expires_at: DateTime.now + 30.days, role: "member",
      receiver_address_type: "code", receiver_address: "123456",
      ticket_id: ticket.id
    )

    assert_difference "TicketItem.count", 1 do
      post api_group_accept_invite_with_code_url, params: {
        auth_token: auth_token, group_invite_id: invite.id, code: "123456"
      }
    end
    assert_response :success

    ti = TicketItem.last
    assert_equal ticket.id, ti.ticket_id
    assert_equal profile.id, ti.profile_id
    assert_equal "invite", ti.auth_type
    assert_equal "succeeded", ti.status
    assert_equal [ "3" ], ti.tracks_allowed
  end

  test "accept_invite_with_code does not create duplicate TicketItem on re-join" do
    profile = profiles(:two)
    auth_token = profile.gen_auth_token
    group = groups(:one)

    ticket = Ticket.create!(
      title: "code pass 2", ticket_type: "group", group_id: group.id,
      event_id: events(:with_ticket).id,
      start_date: Date.today, end_date: Date.today + 30.days,
      quantity: 100, status: "normal"
    )
    invite = GroupInvite.create!(
      group: group, sender: profiles(:one),
      expires_at: DateTime.now + 30.days, role: "member",
      receiver_address_type: "code", receiver_address: "999999",
      ticket_id: ticket.id
    )

    # First join — creates membership + TicketItem
    post api_group_accept_invite_with_code_url, params: {
      auth_token: auth_token, group_invite_id: invite.id, code: "999999"
    }
    assert_response :success

    # Second join — already a member, no new TicketItem
    assert_no_difference "TicketItem.count" do
      post api_group_accept_invite_with_code_url, params: {
        auth_token: auth_token, group_invite_id: invite.id, code: "999999"
      }
    end
    assert_response :success
  end

  test "api#group/send_invite_with_code" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")
    requester = profiles(:two)
    profile2 = Profile.find_by(handle: "dimsum")
    auth_token2 = profile2.gen_auth_token

    post api_group_send_invite_with_code_url, params: {
      auth_token: auth_token,
      group_id: group.id,
      role: "member",
      message: "please join the group"
    }
    assert_response :success
    resp = JSON.parse(response.body)
    invite_id = resp["group_invite"]["id"]
    code = resp["group_invite"]["receiver_address"]

    p code

    post api_group_accept_invite_with_code_url, params: {
      auth_token: auth_token2,
      group_invite_id: invite_id,
      code: code
    }
    assert_response :success
    p response.body

    group_invite = GroupInvite.find_by(group: group, receiver_address: code)
    assert_equal "sending", group_invite.status  # code invites stay "sending" (reusable)

    assert group.is_member(profile2.id)
    assert_equal "member", group.is_member(profile2.id).role
  end
end
