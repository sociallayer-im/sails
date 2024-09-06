require "test_helper"

class Api::GroupControllerTest < ActionDispatch::IntegrationTest

  test "api#group/create" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token

    post api_group_create_url,
      params: { auth_token: auth_token, handle: "newworld", group: {
        timezone: "asia/shanghai",
        can_publish_event: "all",
        can_join_event: "all",
        can_view_event: "all",
      } }
    assert_response :success
    group = Group.find_by(handle: "newworld")
    assert group
    assert group.active?
    assert group.is_owner(profile.id)
    assert group.memberships_count == 1
  end

  test "api#group/update" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    post api_group_update_url,
      params: { auth_token: auth_token, id: group.id, group: {
        timezone: "asia/hongkong",
      } }
    assert_response :success
    group = Group.find_by(handle: "guildx")
    assert group.timezone == "asia/hongkong"
  end

  test "api#group/transfer_owner fails for non-member recipient" do
    profile = Profile.find_by(handle: "cookie")
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    post api_group_transfer_owner_url,
      params: { auth_token: auth_token, id: group.id, new_owner_username: "mooncake" }
    assert JSON.parse(response.body)["message"] == "new_owner membership not exists"
  end

  test "api#group/transfer_owner" do
    profile = Profile.find_by(handle: "cookie")
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    Membership.create(profile: profile2, group: group, role: "member", status: "active")

    post api_group_transfer_owner_url,
      params: { auth_token: auth_token, id: group.id, new_owner_username: "mooncake" }
    assert_response :success
    group = Group.find_by(handle: "guildx")
    assert group.is_owner(profile2.id)
    assert group.get_owner == profile2
  end

  test "api#group/freeze_group" do
    profile = Profile.find_by(handle: "cookie")
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    post api_group_freeze_group_url,
      params: { auth_token: auth_token, id: group.id }

    group = Group.find_by(handle: "guildx")
    assert group.status == "freezed"
  end

  test "api#group/is_manager" do
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile2.gen_auth_token
    group = Group.find_by(handle: "guildx")

    Membership.create(profile: profile2, group: group, role: "manager", status: "active")

    get api_group_is_manager_url,
      params: { profile_id: profile2.id, group_id: group.id }

    assert group.is_manager(profile2.id)
  end

  test "api#group/is_operator" do
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile2.gen_auth_token
    group = Group.find_by(handle: "guildx")

    Membership.create(profile: profile2, group: group, role: "operator", status: "active")

    get api_group_is_operator_url,
      params: { profile_id: profile2.id, group_id: group.id }

    assert group.is_operator(profile2.id)
  end

  test "api#group/is_member" do
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile2.gen_auth_token
    group = Group.find_by(handle: "guildx")

    Membership.create(profile: profile2, group: group, role: "member", status: "active")

    get api_group_is_member_url,
      params: { profile_id: profile2.id, group_id: group.id }

    assert group.is_member(profile2.id)
  end

  test "api#group/remove_member" do
    profile = Profile.find_by(handle: "cookie")
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    Membership.create(profile: profile2, group: group, role: "member", status: "active")

    post api_group_remove_member_url,
      params: { auth_token: auth_token, profile_id: profile2.id, group_id: group.id }
    assert_response :success

    assert_nil group.is_member(profile2.id)
  end

  test "api#group/remove_operator" do
    profile = Profile.find_by(handle: "cookie")
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    Membership.create(profile: profile2, group: group, role: "operator", status: "active")

    post api_group_remove_operator_url,
      params: { auth_token: auth_token, profile_id: profile2.id, group_id: group.id }
    assert_response :success

    assert_nil group.is_operator(profile2.id)
    assert group.is_member(profile2.id)
  end

  test "api#group/remove_manager" do
    profile = Profile.find_by(handle: "cookie")
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    Membership.create(profile: profile2, group: group, role: "manager", status: "active")

    post api_group_remove_manager_url,
      params: { auth_token: auth_token, profile_id: profile2.id, group_id: group.id }
    assert_response :success

    assert_nil group.is_manager(profile2.id)
    assert group.is_member(profile2.id)
  end

  test "api#group/remove_manager fails by manager" do
    profile = Profile.find_by(handle: "cookie")
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    Membership.find_by(profile: profile, group: group).update(role: "manager")
    Membership.create(profile: profile2, group: group, role: "manager", status: "active")

    post api_group_remove_manager_url,
      params: { auth_token: auth_token, profile_id: profile2.id, group_id: group.id }
    assert_response 403

    assert group.is_manager(profile2.id)
  end

  test "api#group/add_manager for member" do
    profile = Profile.find_by(handle: "cookie")
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    Membership.create(profile: profile2, group: group, role: "member", status: "active")

    post api_group_add_manager_url,
      params: { auth_token: auth_token, profile_id: profile2.id, group_id: group.id }
    assert_response :success

    assert group.is_manager(profile2.id)
  end

  test "api#group/add_manager for member by manager" do
    profile = Profile.find_by(handle: "cookie")
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    Membership.find_by(profile: profile, group: group).update(role: "manager")
    Membership.create(profile: profile2, group: group, role: "member", status: "active")

    post api_group_add_manager_url,
      params: { auth_token: auth_token, profile_id: profile2.id, group_id: group.id }
    assert_response :success

    assert group.is_manager(profile2.id)
  end

  # test "api#group/add_manager for non-member" do
  #   profile = Profile.find_by(handle: "cookie")
  #   profile2 = Profile.find_by(handle: "mooncake")
  #   auth_token = profile.gen_auth_token
  #   group = Group.find_by(handle: "guildx")

  #   Membership.create(profile: profile2, group: group, role: "member", status: "active")

  #   post api_group_add_manager_url,
  #     params: { auth_token: auth_token, profile_id: profile2.id, group_id: group.id }
  #   assert_response :success

  #   assert group.is_manager(profile2.id)
  # end

  test "api#group/add_operator for member" do
    profile = Profile.find_by(handle: "cookie")
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    Membership.create(profile: profile2, group: group, role: "member", status: "active")

    post api_group_add_operator_url,
      params: { auth_token: auth_token, profile_id: profile2.id, group_id: group.id }
    assert_response :success

    assert group.is_operator(profile2.id)
  end

  # test "api#group/add_operator for non-member" do
  #   profile = Profile.find_by(handle: "cookie")
  #   profile2 = Profile.find_by(handle: "mooncake")
  #   auth_token = profile.gen_auth_token
  #   group = Group.find_by(handle: "guildx")

  #   Membership.create(profile: profile2, group: group, role: "member", status: "active")

  #   post api_group_add_operator_url,
  #     params: { auth_token: auth_token, profile_id: profile2.id, group_id: group.id }
  #   assert_response :success

  #   assert group.is_operator(profile2.id)
  # end

  test "api#group/leave for member" do
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile2.gen_auth_token
    group = Group.find_by(handle: "guildx")

    Membership.create(profile: profile2, group: group, role: "member", status: "active")

    post api_group_leave_url,
      params: { auth_token: auth_token, profile_id: profile2.id, group_id: group.id }
    assert_response :success

    assert_nil group.is_member(profile2.id)
  end

  test "api#group/send_invite" do
    profile = Profile.find_by(handle: "cookie")
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile.gen_auth_token
    auth_token2 = profile2.gen_auth_token
    group = Group.find_by(handle: "guildx")

    post api_group_send_invite_url,
      params: { auth_token: auth_token, group_id: group.id,
      receivers: [profile2.handle], role: 'member', message: "welcome" }
    assert_response :success

    group_invite = GroupInvite.find_by(receiver: profile2)

    post api_group_accept_invite_url, params: { auth_token: auth_token2, group_invite_id: group_invite.id }
    assert_response :success
    assert response.body == "{\"result\":\"ok\"}"

    assert group.is_member(profile2.id)
  end

end
