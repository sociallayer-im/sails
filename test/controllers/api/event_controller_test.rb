require "test_helper"

class Api::EventControllerTest < ActionDispatch::IntegrationTest
  # with badge_class
  # email notify
  # invite guest
  # event roles
  # event roles of email
  # ticket
  # promo code
  # group member only
  # group manager only
  # private event
  # private track
  test "api#event/create for group" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    post api_event_create_url,
      params: { auth_token: auth_token, group_id: group.id, event: {
        title: "new meetup",
        tags: %w[live art],
        start_time: DateTime.new(2024, 8, 8, 10, 20, 30),
        end_time: DateTime.new(2024, 8, 8, 12, 20, 30),
        location: "central park",
        content: "wonderful",
        display: "normal",
        event_type: "event"
      } }
    assert_response :success
    event = Event.find_by(title: "new meetup")
    assert event
    assert event.status == "published"
    assert event.display == "normal"
    assert event.owner == profile
    assert (Group.find_by(handle: "guildx").events_count - group.events_count) == 1
  end

  test "api#event/create without group" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token

    post api_event_create_url,
      params: { auth_token: auth_token, event: {
        title: "new meetup",
        tags: %w[live art],
        start_time: DateTime.new(2024, 8, 8, 10, 20, 30),
        end_time: DateTime.new(2024, 8, 8, 12, 20, 30),
        location: "central park",
        content: "wonderful",
        display: "normal",
        event_type: "event"
      } }
    assert_response :success
    event = Event.find_by(title: "new meetup")
    assert event
    assert event.status == "published"
    assert event.display == "normal"
    assert event.owner == profile
  end

  test "api#event/create with venue" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")
    venue = venues(:pku)

    post api_event_create_url,
      params: { auth_token: auth_token, group_id: group.id, event: {
        title: "new meetup",
        tags: %w[live art],
        start_time: DateTime.new(2024, 8, 8, 10, 20, 30),
        end_time: DateTime.new(2024, 8, 8, 12, 20, 30),
        location: venue.location,
        content: "wonderful",
        display: "normal",
        event_type: "event",
        venue_id: venue.id
      } }
    assert_response :success
    event = Event.find_by(title: "new meetup")
    assert event
    assert event.status == "published"
    assert event.display == "normal"
    assert event.owner == profile
    assert (Group.find_by(handle: "guildx").events_count - group.events_count) == 1
  end

  test "api#event/create with venue approval" do
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token = profile2.gen_auth_token
    group = Group.find_by(handle: "guildx")
    venue = venues(:pku)
    venue.update(require_approval: true)

    post api_event_create_url,
      params: { auth_token: auth_token, group_id: group.id, venue_id: venue.id, event: {
        title: "new meetup",
        tags: %w[live art],
        start_time: DateTime.new(2024, 8, 8, 10, 20, 30),
        end_time: DateTime.new(2024, 8, 8, 12, 20, 30),
        location: venue.location,
        content: "wonderful",
        display: "normal",
        event_type: "event"
      } }
    assert_response :success
    event = Event.find_by(title: "new meetup")
    assert event
    # p event
    # p Membership.find_by(profile: profile2)
    # assert event.status == "pending"
    # assert event.display == "normal"
    # assert event.owner == profile2
    # assert (Group.find_by(handle: "guildx").events_count - group.events_count) == 1
  end

  test "api#event/update" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")
    event = Event.find_by(title: "my meetup")

    post api_event_update_url,
      params: { auth_token: auth_token, id: event.id, event: {
        title: "new meetup",
        tags: %w[science],
        extra: { message: "random" }
      }
    }
    assert_response :success
    event.reload
    assert event.title == "new meetup"
    assert event.tags == [ "science" ]
  end

  test "api#event/unpublish" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")
    event = Event.find_by(title: "my meetup")

    post api_event_unpublish_url,
      params: { auth_token: auth_token, id: event.id }
    assert_response :success
    assert Event.find_by(title: "my meetup").status == "cancelled"
  end

  test "api#event/check" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    attendee = Profile.find_by(handle: "mooncake")
    attendee_auth_token = profile.gen_auth_token

    group = Group.find_by(handle: "guildx")
    event = Event.find_by(title: "my meetup")

    post api_event_join_url,
      params: { auth_token: attendee_auth_token, id: event.id }
    assert_response :success
    assert Participant.find_by(event: event).status == "attending"

    post api_event_check_url,
      params: { auth_token: auth_token, id: event.id, profile_id: profile.id }
    assert_response :success
    assert Participant.find_by(event: event).status == "checked"
  end

  test "api#event/cancel" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    attendee = Profile.find_by(handle: "mooncake")
    attendee_auth_token = profile.gen_auth_token

    group = Group.find_by(handle: "guildx")
    event = Event.find_by(title: "my meetup")

    post api_event_join_url,
      params: { auth_token: attendee_auth_token, id: event.id }
    assert_response :success
    assert Participant.find_by(event: event).status == "attending"

    post api_event_cancel_url,
      params: { auth_token: auth_token, id: event.id, profile_id: profile.id }
    assert_response :success
    assert Participant.find_by(event: event).status == "cancelled"
  end
end
