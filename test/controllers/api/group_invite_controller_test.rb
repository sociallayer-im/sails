require "test_helper"

class Api::GroupInviteControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "api#group/send_invite" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    assert_difference "GroupInvite.count", 1 do
    post api_group_send_invite_url, params: {
      auth_token: auth_token,
      group_id: group.id,
      role: "member",
      receivers: [ "mooncake" ],
      message: "please join the group"
     }
    end
    assert_response :success
    group_invite = GroupInvite.find_by(group: group, sender: profile)
    assert group_invite.status == "sending"
  end

  test "api#group/send_invite to existing member for upgrading" do
    profile = Profile.find_by(handle: "cookie")
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    Membership.create(profile_id: profile2.id, group_id: group.id, role: "member", status: "active")

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
    assert Membership.find_by(profile_id: profile2.id, group_id: group.id).role == "manager"
  end

  test "api#group/send_invite to existing manager without downgrading" do
    profile = Profile.find_by(handle: "cookie")
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    Membership.create(profile_id: profile2.id, group_id: group.id, role: "manager", status: "active")

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
    assert Membership.find_by(profile_id: profile2.id, group_id: group.id).role == "manager"
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
    assert_equal ["dimsum@mail.com"], email.to
    assert_equal 'Social Layer Group Invite', email.subject

    profile2.update(email: "dimsum@mail.com")
    auth_token2 = profile2.gen_auth_token
    invite = GroupInvite.find_by(group: group, sender: profile)

    post api_group_accept_invite_url, params: {
      auth_token: auth_token2,
      group_invite_id: invite.id
    }
    assert_response :success

    group_member = Membership.find_by(group: group, profile: profile2)
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

    group_member = Membership.find_by(group: group, profile: profile)
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

    membership = Membership.find_by(profile_id: requester.id, group_id: group.id)
    assert membership
    assert_equal "member", membership.role
  end
end
