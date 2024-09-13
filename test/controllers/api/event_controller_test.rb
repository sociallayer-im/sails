require "test_helper"

class Api::EventControllerTest < ActionDispatch::IntegrationTest
  # with badge_class
  # invite guest
  # event roles
  # event roles of email
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

  test "api#event/create with webhook" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    url = nil
    Config.create(group_id: group.id, name: "event_webhook_url", value: url)

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
    assert event.status == "pending"
    assert event.display == "normal"
    assert event.owner == profile2
    assert (Group.find_by(handle: "guildx").events_count - group.events_count) == 1
  end

  test "api#event/update" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")
    event = Event.find_by(title: "my meetup")

    participant = Participant.create(
      profile_id: profile.id,
      event_id: event.id,
      status: "attending",
      register_time: DateTime.now
    )

    post api_event_update_url,
      params: { auth_token: auth_token, id: event.id, event: {
        title: "new meetup",
        tags: %w[science],
        end_time: DateTime.parse("2024-08-10T10:20:30+00:00"),
        extra: { message: "random" }
      }
    }
    assert_response :success
    event.reload
    assert event.title == "new meetup"
    assert event.tags == [ "science" ]

    email = ActionMailer::Base.deliveries.last
    assert_equal [profile.email], email.to
    assert_equal 'Social Layer Event Updated', email.subject
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
    attendee_auth_token = attendee.gen_auth_token

    group = Group.find_by(handle: "guildx")
    event = Event.find_by(title: "my meetup")

    assert_emails 1 do
      post api_event_join_url,
        params: { auth_token: attendee_auth_token, id: event.id }
      assert_response :success
    end
    assert Participant.find_by(event: event).status == "attending"

    event = Event.find_by(title: "my meetup")

    email = ActionMailer::Base.deliveries.last
    assert_equal [attendee.email], email.to
    assert_equal 'Social Layer Event', email.subject

    post api_event_check_url,
      params: { auth_token: auth_token, id: event.id, profile_id: attendee.id }
    assert_response :success
    assert Participant.find_by(event: event).status == "checked"
  end

  test "api#event/join with ticket restriction and valid for specific date" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    attendee = Profile.find_by(handle: "mooncake")
    attendee_auth_token = attendee.gen_auth_token

    group = Group.find_by(handle: "guildx")

    group_ticket_event = Event.create!(
      title: "group ticket meetup",
      owner: profile,
      group: group,
      start_time: DateTime.new(2024, 8, 8, 10, 20, 30),
      end_time: DateTime.new(2024, 8, 8, 12, 20, 30),
      status: "published",
      event_type: "group_ticket"
    )
    group.update(group_ticket_event_id: group_ticket_event.id, can_join_event: "ticket")

    event = Event.create!(
      title: "restricted meetup",
      owner: profile,
      group: group,
      start_time: DateTime.new(2024, 8, 18, 10, 20, 30),
      end_time: DateTime.new(2024, 8, 18, 12, 20, 30),
      status: "published",
      event_type: "event"
    )

    ticket = Ticket.create!(
      title: "valid ticket",
      group: group,
      event: group_ticket_event,
      start_date: Date.new(2024, 8, 8),
      end_date: Date.new(2024, 8, 10),
      ticket_type: "group"
    )

    TicketItem.create!(
      profile: attendee,
      ticket: ticket,
      event: group_ticket_event,
      group: group,
      status: "succeeded",
      ticket_type: "group"
    )

    post api_event_join_url,
    params: { auth_token: attendee_auth_token, id: event.id }
    assert_response 400
    assert response.body == "{\"result\":\"error\",\"message\":\"group ticket check failed\"}"
  end

  test "api#event/cancel" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    attendee = Profile.find_by(handle: "mooncake")
    attendee_auth_token = attendee.gen_auth_token

    group = Group.find_by(handle: "guildx")
    event = Event.find_by(title: "my meetup")

    post api_event_join_url,
      params: { auth_token: attendee_auth_token, id: event.id }
    assert_response :success
    assert Participant.find_by(event: event).status == "attending"

    post api_event_cancel_url,
      params: { auth_token: attendee_auth_token, id: event.id, profile_id: attendee.id }

    assert_response :success
    assert Participant.find_by(event: event).status == "cancelled"

    email = ActionMailer::Base.deliveries.last
    assert_equal [attendee.email], email.to
    assert_equal 'Social Layer Event Updated', email.subject
  end

  test "api#event/get" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token

    event = Event.find_by(title: "my meetup")

    get api_event_get_url(id: event.id), params: { auth_token: auth_token }
    assert_response :success

    response_event = JSON.parse(response.body)
    assert_equal event.id, response_event["id"]
    assert_equal event.title, response_event["title"]
    assert_equal event.start_time.as_json, response_event["start_time"]
    assert_equal event.end_time.as_json, response_event["end_time"]
    assert_equal event.location, response_event["location"]
  end

  test "api#event/list" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token

    get api_event_list_url, params: { auth_token: auth_token, group_id: 1 }
    assert_response :success

    response_events = JSON.parse(response.body)
    assert_equal Event.where(display: "normal").all.count - 1, response_events.count
  end 

  test "api#event/private_list" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token

    get api_event_private_list_url, params: { auth_token: auth_token, group_id: 1 }
    assert_response :success

    response_events = JSON.parse(response.body)
    assert_equal 1, response_events.count
  end

  test "api#event/private_track_list" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token

    get api_event_private_track_list_url, params: { auth_token: auth_token, group_id: 1 }
    assert_response :success

    response_events = JSON.parse(response.body)
    assert_equal Event.where(display: "normal").all.count - 1, response_events.count
  end

  test "api#event/private_track_list with track role" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token

    TrackRole.create(
      group_id: 1,
      profile_id: profile.id,
      track_id: 2,
      role: "member"
    )

    get api_event_private_track_list_url, params: { auth_token: auth_token, group_id: 1 }
    assert_response :success

    response_events = JSON.parse(response.body)
    assert_equal Event.where(display: "normal").all.count, response_events.count
  end
end
