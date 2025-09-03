require "test_helper"

class Api::GroupControllerTest < ActionDispatch::IntegrationTest
  test "api#group/create" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token

    post api_group_create_url,
      params: { auth_token: auth_token, handle: "newworld", group: {
        timezone: "asia/shanghai",
      } }
    assert_response :success
    group = Group.find_by(handle: "newworld")
    assert group
    assert group.active?
    assert group.is_owner(profile.id)
    assert group.memberships_count == 1
    assert Domain.find_by(handle: "newworld", item_type: "Group", item_id: group.id).present?
  end

  test "api#group/get" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    get api_group_get_url, params: { auth_token: auth_token, group_id: group.id }
    assert_response :success
    assert JSON.parse(response.body)["group"]["id"] == group.id
  end

  test "api#group/create with track" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token

    post api_group_create_url,
      params: { auth_token: auth_token, handle: "newworld", group: {
        timezone: "asia/shanghai",
        tracks_attributes: [
          { tag: "track1", title: "Track 1", kind: "public", icon_url: "https://example.com/icon1.png", about: "About Track 1", start_date: "2024-01-01", end_date: "2024-12-31" }
        ]
      } }
    assert_response :success
    group = Group.find_by(handle: "newworld")
    assert group
    assert group.active?
    assert group.is_owner(profile.id)
    assert group.memberships_count == 1
    assert Domain.find_by(handle: "newworld", item_type: "Group", item_id: group.id).present?
    assert group.tracks.count == 1
    track = group.tracks.first
    assert_equal "track1", track.tag
    assert_equal "Track 1", track.title
    assert_equal "public", track.kind
    assert_equal "https://example.com/icon1.png", track.icon_url
    assert_equal "About Track 1", track.about
    assert_equal Date.parse("2024-01-01"), track.start_date
    assert_equal Date.parse("2024-12-31"), track.end_date
  end

  test "api#group/update_track" do
    profile = Profile.find_by(handle: "cookie")
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")
    track = group.tracks.create(tag: "track1", title: "Track 1", kind: "public", icon_url: "https://example.com/icon1.png", about: "About Track 1", start_date: "2024-01-01", end_date: "2024-12-31")

    post api_group_update_track_url,
      params: { auth_token: auth_token, track_id: track.id, track: {
        title: "Updated Track 1", kind: "private", icon_url: "https://example.com/icon1_updated.png", about: "Updated About Track 1", start_date: "2024-02-01", end_date: "2024-11-30"
      } }
    assert_response :success

    track.reload
    assert_equal "Updated Track 1", track.title
    assert_equal "private", track.kind
    assert_equal "https://example.com/icon1_updated.png", track.icon_url
    assert_equal "Updated About Track 1", track.about
    assert_equal Date.parse("2024-02-01"), track.start_date
    assert_equal Date.parse("2024-11-30"), track.end_date
    assert track.track_roles.count == 0
  end

  test "api#group/add_track" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")
    post api_group_add_track_url,
      params: { auth_token: auth_token, group_id: group.id, track: {
        tag: "track1", title: "New Track 1", kind: "public", icon_url: "https://example.com/icon1.png", about: "About Track 1", start_date: "2024-01-01", end_date: "2024-12-31"
      } }
    assert_response :success
    track = group.tracks.find_by(tag: "track1")
    assert track.present?
    assert_equal "track1", track.tag
    assert_equal "New Track 1", track.title
    assert_equal "public", track.kind
    assert_equal "https://example.com/icon1.png", track.icon_url
    assert_equal "About Track 1", track.about
    assert_equal Date.parse("2024-01-01"), track.start_date
    assert_equal Date.parse("2024-12-31"), track.end_date
  end

  test "api#group/remove_track" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")
    track = group.tracks.create(tag: "track1", title: "Track 1", kind: "public", icon_url: "https://example.com/icon1.png", about: "About Track 1", start_date: "2024-01-01", end_date: "2024-12-31")
    post api_group_remove_track_url,
      params: { auth_token: auth_token, track_id: track.id }
    assert_response :success
  end

  test "api#group/add_track_role" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")
    track = group.tracks.create(tag: "track1", title: "Track 1", kind: "public", icon_url: "https://example.com/icon1.png", about: "About Track 1", start_date: "2024-01-01", end_date: "2024-12-31")
    post api_group_add_track_role_url,
      params: { auth_token: auth_token, track_id: track.id, track_role: {
        role: "manager", profile_id: profile.id
      } }
    assert_response :success
    track.reload
    assert track.track_roles.count == 1
    assert track.track_roles.first.role == "manager"
    assert track.track_roles.first.profile_id == profile.id
  end

  test "api#group/add_track_members" do
    profile = Profile.find_by(handle: "cookie")
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")
    track = group.tracks.create(tag: "track1", title: "Track 1", kind: "public", icon_url: "https://example.com/icon1.png", about: "About Track 1", start_date: "2024-01-01", end_date: "2024-12-31")
    post api_group_add_track_members_url,
      params: { auth_token: auth_token, track_id: track.id, track_member_emails: ["cookie@gmail.com", "mooncake@gmail.com" ] }
    assert_response :success
    assert track.track_roles.count == 2
    assert track.track_roles.first.role == "member"
    assert track.track_roles.first.profile_id == profile.id
    assert track.track_roles.second.role == "member"
    assert track.track_roles.second.profile_id == profile2.id
  end

  test "api#group/remove_track_role" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")
    track = group.tracks.create(tag: "track1", title: "Track 1", kind: "public", icon_url: "https://example.com/icon1.png", about: "About Track 1", start_date: "2024-01-01", end_date: "2024-12-31")
    TrackRole.create(track_id: track.id, profile_id: profile.id, role: "manager")
    post api_group_remove_track_role_url,
      params: { auth_token: auth_token, track_id: track.id, profile_id: profile.id }
    assert_response :success
    assert track.track_roles.count == 0
  end

  test "api#group/update" do # optimize this test function
    assert_changes "Group.find_by(handle: 'guildx').timezone" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    post api_group_update_url,
      params: { auth_token: auth_token, id: group.id, group: {
        timezone: "asia/hongkong"
      } }
    assert_response :success
    end
  end

  test "api#group/transfer_owner fails for non-member recipient" do
    profile = Profile.find_by(handle: "cookie")
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    post api_group_transfer_owner_url,
      params: { auth_token: auth_token, id: group.id, new_owner_handle: "mooncake" }
    assert JSON.parse(response.body)["message"] == "new_owner membership not exists"
  end

  test "api#group/transfer_owner" do
    profile = Profile.find_by(handle: "cookie")
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    Membership.create(profile: profile2, target: group, role: "member", status: "active")

    post api_group_transfer_owner_url,
      params: { auth_token: auth_token, id: group.id, new_owner_handle: "mooncake" }
    assert_response :success
    group = Group.find_by(handle: "guildx")
    assert group.is_owner(profile2.id)
    assert group.get_owner == profile2

    # Transfer ownership back to original owner
    post api_group_transfer_owner_url,
      params: { auth_token: profile2.gen_auth_token, id: group.id, new_owner_handle: "cookie" }
    assert_response :success

    group = Group.find_by(handle: "guildx")
    assert group.is_owner(profile.id)
    assert group.get_owner == profile
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

    Membership.create(profile: profile2, target: group, role: "manager", status: "active")

    get api_group_is_manager_url,
      params: { profile_id: profile2.id, group_id: group.id }

    assert group.is_manager(profile2.id)
  end

  test "api#group/is_operator" do
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile2.gen_auth_token
    group = Group.find_by(handle: "guildx")

    Membership.create(profile: profile2, target: group, role: "operator", status: "active")

    get api_group_is_operator_url,
      params: { profile_id: profile2.id, group_id: group.id }

    assert group.is_operator(profile2.id)
  end

  test "api#group/is_member" do
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile2.gen_auth_token
    group = Group.find_by(handle: "guildx")

    Membership.create(profile: profile2, target: group, role: "member", status: "active")

    get api_group_is_member_url,
      params: { profile_id: profile2.id, group_id: group.id }

    assert group.is_member(profile2.id)
  end

  test "api#group/remove_member" do
    profile = Profile.find_by(handle: "cookie")
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    Membership.create(profile: profile2, target: group, role: "member", status: "active")

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

    Membership.create(profile: profile2, target: group, role: "operator", status: "active")

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

    Membership.create(profile: profile2, target: group, role: "manager", status: "active")

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

    group.is_member(profile.id).update(role: "manager")
    Membership.create(profile: profile2, target: group, role: "manager", status: "active")

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

    Membership.create(profile: profile2, target: group, role: "member", status: "active")

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

    group.is_member(profile.id).update(role: "manager")
    Membership.create(profile: profile2, target: group, role: "member", status: "active")

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

    Membership.create(profile: profile2, target: group, role: "member", status: "active")

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

    Membership.create(profile: profile2, target: group, role: "member", status: "active")

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
      receivers: [ profile2.handle ], role: "member", message: "welcome" }
    assert_response :success

    # group_invite = GroupInvite.find_by(receiver: profile2)

    # post api_group_accept_invite_url, params: { auth_token: auth_token2, group_invite_id: group_invite.id }
    # assert_response :success
    # assert response.body == "{\"result\":\"ok\"}"

    assert group.is_member(profile2.id)
  end

  test "api#group/update_popup_admin" do
    profile = Profile.find_by(handle: "cookie")
    profile.update(status: "admin")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")
    popup = group.popup_cities.create(title: "Popup 1", image_url: "https://example.com/image1.png", location: "Location 1", website: "https://example.com/website1.com", start_date: "2024-01-01", end_date: "2024-12-31")
    post api_group_update_popup_admin_url,
      params: { auth_token: auth_token, id: popup.id,
        title: "Updated Popup 1", image_url: "https://example.com/image1_updated.png", location: "Location 1", website: "https://example.com/website1_updated.com", start_date: "2024-01-01", end_date: "2024-12-31", group_tags: ["tag1", "tag2"] }
    assert_response :success
    popup.reload
    assert_equal "Updated Popup 1", popup.title
    assert_equal ["tag1", "tag2"], popup.group_tags
  end

  test "api#group/delete_popup_admin" do
    profile = Profile.find_by(handle: "cookie")
    profile.update(status: "admin")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")
    popup = group.popup_cities.create(title: "Popup 1", image_url: "https://example.com/image1.png", location: "Location 1", website: "https://example.com/website1.com", start_date: "2024-01-01", end_date: "2024-12-31")
    post api_group_delete_popup_admin_url,
      params: { auth_token: auth_token, id: popup.id }
    assert_response :success
    assert_nil PopupCity.find_by(id: popup.id)
  end
end
