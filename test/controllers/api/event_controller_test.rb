require "test_helper"

class Api::EventControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "api#event/create for group" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    post api_event_create_url,
      params: { auth_token: auth_token, group_id: group.id,
        title: "new meetup",
        tags: %w[live private_track],
        start_time: DateTime.new(2024, 8, 8, 10, 20, 30),
        end_time: DateTime.new(2024, 8, 8, 12, 20, 30),
        location: "central park",
        content: "wonderful",
        display: "normal",
        event_type: "event"
      }
    assert_response :success
    event = Event.find_by(title: "new meetup")
    assert event
    assert event.status == "published"
    assert event.display == "normal"
    assert event.owner == profile
    assert (Group.find_by(handle: "guildx").events_count - group.events_count) == 1
  end

  test "api#event/create with event roles and email" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    post api_event_create_url,
      params: {
        auth_token: auth_token,
        group_id: group.id,
        title: "Event with Roles",
        tags: %w[live workshop],
        start_time: DateTime.new(2024, 9, 1, 10, 0, 0),
        end_time: DateTime.new(2024, 9, 1, 12, 0, 0),
        location: "Community Center",
        content: "Workshop with various roles",
        display: "normal",
        event_type: "event",
        event_roles_attributes: [
          { role: "host", email: "host@example.com" },
          { role: "speaker", email: "speaker@example.com" },
          { role: "moderator", email: "moderator@example.com" }
        ]
      }

    assert_response :success
    event = Event.find_by(title: "Event with Roles")
    assert event
    assert_equal "published", event.status
    assert_equal "normal", event.display
    assert_equal profile, event.owner

    # Check if event roles were created
    assert_equal 3, event.event_roles.count
    assert event.event_roles.exists?(role: "host", email: "host@example.com")
    assert event.event_roles.exists?(role: "speaker", email: "speaker@example.com")
    assert event.event_roles.exists?(role: "moderator", email: "moderator@example.com")
  end

  test "api#event/create with event roles and item_id as profile_id" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    # Create a profile to be assigned a role
    role_profile = Profile.create(handle: "role_user", email: "role_user@example.com")

    post api_event_create_url,
      params: {
        auth_token: auth_token,
        group_id: group.id,
        title: "Event with Profile Roles",
        tags: %w[conference networking],
        start_time: DateTime.new(2024, 10, 1, 9, 0, 0),
        end_time: DateTime.new(2024, 10, 1, 17, 0, 0),
        location: "Convention Center",
        content: "Annual tech conference",
        display: "normal",
        event_type: "event",
        event_roles_attributes: [
          { role: "host", item_type: "Profile", item_id: profile.id },
          { role: "speaker", item_type: "Profile", item_id: role_profile.id },
          { role: "moderator", email: "moderator@example.com" }
        ]
      }

    assert_response :success
    event = Event.find_by(title: "Event with Profile Roles")
    assert event
    assert_equal "published", event.status
    assert_equal "normal", event.display
    assert_equal profile, event.owner

    # Check if event roles were created correctly
    assert_equal 3, event.event_roles.count
    assert event.event_roles.exists?(role: "host", item_type: "Profile", item_id: profile.id)
    assert event.event_roles.exists?(role: "speaker", item_type: "Profile", item_id: role_profile.id)
    assert event.event_roles.exists?(role: "moderator", email: "moderator@example.com")

    # Verify that profiles are correctly associated
    host_role = event.event_roles.find_by(role: "host")
    assert_equal profile, host_role.item

    speaker_role = event.event_roles.find_by(role: "speaker")
    assert_equal role_profile, speaker_role.item
  end

  test "api#event/create with webhook" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")

    url = ENV["TEST_EVENT_WEBHOOK_URL"]
    Config.create(group_id: group.id, name: "event_webhook_url", value: url)

    post api_event_create_url,
      params: { auth_token: auth_token, group_id: group.id,
        title: "new meetup",
        tags: %w[live art],
        start_time: DateTime.new(2024, 8, 8, 10, 20, 30),
        end_time: DateTime.new(2024, 8, 8, 12, 20, 30),
        location: "central park",
        content: "wonderful",
        display: "normal",
        event_type: "event"
      }
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
      params: { auth_token: auth_token,
        title: "new meetup",
        tags: %w[live art],
        start_time: DateTime.new(2024, 8, 8, 10, 20, 30),
        end_time: DateTime.new(2024, 8, 8, 12, 20, 30),
        location: "central park",
        content: "wonderful",
        display: "normal",
        event_type: "event"
      }
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
      params: { auth_token: auth_token, group_id: group.id,
        title: "new meetup",
        tags: %w[live art],
        start_time: DateTime.new(2024, 8, 8, 10, 20, 30),
        end_time: DateTime.new(2024, 8, 8, 12, 20, 30),
        location: venue.location,
        content: "wonderful",
        display: "normal",
        event_type: "event",
        venue_id: venue.id
      }
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
      params: { auth_token: auth_token, group_id: group.id, venue_id: venue.id,
        title: "new meetup",
        tags: %w[live art],
        start_time: DateTime.new(2024, 8, 8, 10, 20, 30),
        end_time: DateTime.new(2024, 8, 8, 12, 20, 30),
        location: venue.location,
        content: "wonderful",
        display: "normal",
        event_type: "event"
      }
    assert_response :success
    event = Event.find_by(title: "new meetup")
    assert event
    assert event.status == "pending"
    assert event.display == "normal"
    assert event.owner == profile2
    assert (Group.find_by(handle: "guildx").events_count - group.events_count) == 1

    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token

    get api_event_pending_approval_list_url, params: { auth_token: auth_token }
    assert_response :success
    assert_equal 1, JSON.parse(response.body)["events"].count
    assert JSON.parse(response.body)["events"].first["id"] == event.id

    post api_event_approve_event_url, params: { auth_token: auth_token, id: event.id }
    assert_response :success
    assert Event.find(event.id).status == "published"
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
      params: { auth_token: auth_token, id: event.id,
        title: "new meetup",
        tags: %w[science],
        end_time: DateTime.parse("2024-08-10T10:20:30+00:00"),
        extras: { message: "random" }
    }
    assert_response :success
    event.reload
    assert event.title == "new meetup"
    assert event.tags == [ "science" ]

    perform_enqueued_jobs
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
    travel_to Date.new(2024, 8, 8)
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

  test "api#event/approve_participant" do
    profile = Profile.find_by(handle: "cookie")
    attendee = Profile.find_by(handle: "mooncake")
    auth_token = profile.gen_auth_token
    attendee_auth_token = attendee.gen_auth_token

    event = Event.find_by(title: "my meetup")
    event.update(require_approval: true)

    post api_event_join_url,
      params: { auth_token: attendee_auth_token, id: event.id }
    assert_response :success
    assert Participant.find_by(event: event).status == "pending"

    participant = Participant.find_by(event: event, profile: attendee)

    post api_event_approve_participant_url, params: { auth_token: auth_token, id: event.id, participant_id: participant.id }
    assert_response :success
    assert Participant.find_by(event: event).status == "attending"
  end

  test "api#event/join with ticket restriction and valid for specific date" do
    travel_to Date.new(2024, 8, 8)
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
    travel_to Date.new(2024, 8, 8)
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

    perform_enqueued_jobs
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

    response_events = JSON.parse(response.body)["events"]
    assert_equal 4, response_events.count
  end

  test "api#event/my_event_list" do
    travel_to Date.new(2024, 8, 8)
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token

    # Test my_stars collection
    post api_comment_create_url, params: {
      auth_token: auth_token,
      comment: {
        item_type: "Event",
        item_id: Event.first.id,
        comment_type: "star"
      }
    }
    assert_response :success

    get api_event_my_event_list_url, params: { auth_token: auth_token, collection: "my_stars" }
    assert_response :success
    response_events = JSON.parse(response.body)["events"]
    assert_equal 1, response_events.count
    assert_equal Event.first.id, response_events.first["id"]

    # Test attending events
    event = Event.last
    post api_event_join_url, params: { auth_token: auth_token, id: event.id }
    assert_response :success

    get api_event_my_event_list_url, params: { auth_token: auth_token }
    assert_response :success
    response_events = JSON.parse(response.body)["events"]
    assert_equal 1, response_events.count
    assert_equal event.id, response_events.first["id"]

    # Test pagination
    get api_event_my_event_list_url, params: { auth_token: auth_token, limit: 1 }
    assert_response :success
    response_body = JSON.parse(response.body)["events"]
    assert_equal 1, response_body.count
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

    response_events = JSON.parse(response.body)["events"]
    assert_equal 3, response_events.count
  end

  test "api#event/private_track_list with track role" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    track = Track.find(2)

    TrackRole.create(
      group_id: 1,
      profile_id: profile.id,
      track_id: track.id,
      role: "member"
    )

    get api_event_list_url, params: { auth_token: auth_token, group_id: 1, track_id: track.id }
    assert_response :success

    response_events = JSON.parse(response.body)["events"]
    assert_equal Event.where(display: "normal", track_id: track.id).all.count, response_events.count

    # Test event update for track manager
    event = Event.find_by(title: "private track event")
    # Test that a non-track manager cannot update the event
    other_profile = Profile.create(handle: "non_manager")
    other_auth_token = other_profile.gen_auth_token

    post api_event_update_url, params: {
      auth_token: other_auth_token,
      id: event.id,
      event: {
        title: "Unauthorized Update"
      }
    }
    assert_response :forbidden

    other_profile = Profile.create(handle: "is_manager")
    other_auth_token = other_profile.gen_auth_token

    track.manager_ids = [other_profile.id]
    track.save

    post api_event_update_url, params: {
      auth_token: other_auth_token,
      id: event.id,
      event: {
        title: "Updated Track Manager Event"
      }
    }
    assert_response :success
  end

  test "api#event/list with group_union" do
    # Create profiles and generate auth tokens
    profile1 = Profile.find_by(handle: "cookie")
    auth_token1 = profile1.gen_auth_token
    profile2 = Profile.find_by(handle: "mooncake")
    auth_token2 = profile2.gen_auth_token

    # Create groups
    group1 = Group.create(nickname: "Group 1", handle: "group1")
    group2 = Group.create(nickname: "Group 2", handle: "group2")

    # Create group union
    group1.update(group_union: [group2.id])

    # Create events for each group
    event1 = Event.create(title: "Event 1", group: group1, owner: profile1, start_time: DateTime.now, end_time: DateTime.now + 1.hour, status: "published", display: "normal", event_type: "event")
    event2 = Event.create(title: "Event 2", group: group2, owner: profile2, start_time: DateTime.now, end_time: DateTime.now + 1.hour, status: "published", display: "normal", event_type: "event")

    # Test event list for group_union
    get api_event_list_url, params: { auth_token: auth_token1, group_id: group1.handle }
    assert_response :success

    response_events = JSON.parse(response.body)["events"]
    assert_equal 2, response_events.count
    assert_includes response_events.map { |e| e["title"] }, "Event 1"
    assert_includes response_events.map { |e| e["title"] }, "Event 2"
  end

  test "api#event/join, cancel, and rejoin" do
    travel_to Date.new(2024, 8, 7)
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    event = Event.find_by(title: "my meetup")

    # Join event
    assert_difference 'Participant.count', 1 do
      post api_event_join_url, params: { auth_token: auth_token, id: event.id }
    end
    assert_response :success
    participant = Participant.last
    assert_equal "attending", participant.status
    assert_equal profile.id, participant.profile_id
    assert_equal event.id, participant.event_id
    register_time = participant.register_time

    # Cancel joining event
    assert_no_difference 'Participant.count' do
      post api_event_cancel_url, params: { auth_token: auth_token, id: event.id }
    end
    assert_response :success
    participant.reload
    assert_equal "cancelled", participant.status

    travel_to Date.new(2024, 8, 8)
    # Rejoin event
    assert_no_difference 'Participant.count' do
      post api_event_join_url, params: { auth_token: auth_token, id: event.id }
    end
    assert_response :success
    participant.reload
    assert_equal "attending", participant.status
    assert_not_equal register_time, participant.register_time
  end

  test "api#event/remove_participant" do
    travel_to Date.new(2024, 8, 8)
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    event = Event.find_by(title: "my meetup")

    # Join event
    post api_event_join_url, params: { auth_token: auth_token, id: event.id }
    assert_response :success

    # Ensure the event owner is different from the participant
    event_owner = Profile.find_by(handle: "mooncake")
    event.update(owner: event_owner)
    owner_auth_token = event_owner.gen_auth_token

    post api_event_remove_participant_url, params: {
      auth_token: owner_auth_token,
      id: event.id,
      profile_id: profile.id
    }
    assert_response :success

    participant = Participant.find_by(event_id: event.id, profile_id: profile.id)
    assert_equal "cancelled", participant.status
  end

  # todo : test set_notes
  test "api#event/set_notes" do
    travel_to Date.new(2024, 8, 8)
    profile = Profile.find_by(handle: "cookie")

    auth_token = profile.gen_auth_token
    event = Event.find_by(title: "my meetup")

    # Join event
    post api_event_join_url, params: { auth_token: auth_token, id: event.id }
    assert_response :success

    # Set notes
    notes = "Bringing snacks for everyone"
    post api_event_set_notes_url, params: {
      auth_token: auth_token,
      id: event.id,
      notes: notes
    }
    assert_response :success

    # Update notes
    updated_notes = "Changed my mind, bringing drinks instead"
    post api_event_set_notes_url, params: {
      auth_token: auth_token,
      id: event.id,
      notes: updated_notes
    }
    assert_response :success

    # Clear notes
    post api_event_set_notes_url, params: {
      auth_token: auth_token,
      id: event.id,
      notes: ""
    }
    assert_response :success

  end

  test "api#event/send_badge" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    event = Event.find_by(title: "my meetup")
    badge_class = badge_classes(:one)

    profile2 = Profile.find_by(handle: "mooncake")
    auth_token2 = profile2.gen_auth_token
    group = Group.find_by(username: "guildx")

    post api_event_set_badge_url,
params: { auth_token: auth_token, id: event.id, badge_class_id: badge_class.id }
    assert_response :success

    assert event.reload.badge_class_id == badge_class.id

    post api_event_join_url,
params: { auth_token: auth_token2, id: event.id }
    assert_response :success

    post api_event_check_url,
params: { auth_token: auth_token, id: event.id, profile_id: profile2.id }
    assert_response :success

    post api_event_send_badge_url,
params: { auth_token: auth_token, id: event.id }
    assert_response :success

    assert Voucher.last.receiver_id == profile2.id
    assert Voucher.last.counter == 1

    post api_voucher_use_url, params: { auth_token: auth_token2, id: Voucher.last.id }
    assert_response :success

    assert Voucher.last.counter == 0
  end

  test "api#event/update with new venue" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    event = Event.find_by(title: "my meetup")
    venue = venues(:yuanmingyuan)

    post api_event_update_url,
      params: { auth_token: auth_token, id: event.id,
        venue_id: venue.id,
        location: venue.location
    }
    assert_response :success
    event.reload
    assert_equal venue.id, event.venue_id
    assert_equal venue.location, event.location
  end
end
