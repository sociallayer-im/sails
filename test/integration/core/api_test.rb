require "test_helper"

module Core
  class ApiTest < ActionDispatch::IntegrationTest
    test "GET /api/hello returns hello world" do
      get "/api/hello"

      assert_response :success
      assert_equal({ "hello" => "world" }, JSON.parse(@response.body))
    end

    test "GET /api/profile/me returns current profile" do
      profile = profiles(:one)
      auth_token = profile.gen_auth_token
      get "/api/profile/me", headers: { "Authorization" => "Bearer #{auth_token}" }

      assert_response :success
      assert_equal(profile.id, JSON.parse(@response.body)["id"])
      end

      test "GET /api/event/get returns event" do
        event = events(:one)
        get "/api/event/get", params: { id: event.id }, headers: { "Authorization" => "Bearer #{event.owner.gen_auth_token}" }

        assert_response :success
        assert_equal(event.id, JSON.parse(@response.body)["event"]["id"])
        # p @response.body
      end

      test "GET /api/event/discover returns featured events and popups" do
        travel_to DateTime.new(2024, 2, 22, 10, 0, 0, "+00:00")
        get "/api/event/discover"

        assert_response :success
        assert_equal(1, JSON.parse(@response.body)["events"].count)
        assert_equal(1, JSON.parse(@response.body)["featured_popups"].count)
      end

      test "GET /api/event/my_starred returns my starred events" do
        travel_to DateTime.new(2024, 2, 22, 10, 0, 0, "+00:00")
        profile = profiles(:one)
        auth_token = profile.gen_auth_token
        Comment.create(profile: profile, comment_type: "star", item_type: "Event", item_id: events(:one).id)

        get "/api/event/my_starred", headers: { "Authorization" => "Bearer #{auth_token}" }

        assert_response :success
        assert_equal(1, JSON.parse(@response.body)["events"].count)
        assert_equal(events(:one).id, JSON.parse(@response.body)["events"][0]["id"], JSON.parse(@response.body)["events"][0]["id"])
      end

      test "GET /api/event/my_attending returns my attending events" do
        travel_to DateTime.new(2024, 2, 22, 10, 0, 0, "+00:00")
        profile = profiles(:one)
        auth_token = profile.gen_auth_token
        event = events(:one)
        Participant.create(profile: profile, event: event, status: "attending")

        get "/api/event/my_attending", headers: { "Authorization" => "Bearer #{auth_token}" }

        assert_response :success
        assert_equal(1, JSON.parse(@response.body)["events"].count)
        assert_equal(event.id, JSON.parse(@response.body)["events"][0]["id"])
      end

      test "GET /api/event/my_created returns events I created" do
        travel_to DateTime.new(2024, 2, 22, 10, 0, 0, "+00:00")
        profile = profiles(:two)
        auth_token = profile.gen_auth_token
        event = events(:one)
        event.update(owner: profile)

        get "/api/event/my_created", headers: { "Authorization" => "Bearer #{auth_token}" }

        assert_response :success
        assert_equal(1, JSON.parse(@response.body)["events"].count)
        assert_equal(event.id, JSON.parse(@response.body)["events"][0]["id"])
      end

      test "GET /api/event/my_private returns private events I have access to" do
        travel_to DateTime.new(2024, 2, 22, 10, 0, 0, "+00:00")
        group = groups(:two)
        owner = profiles(:one)
        profile = profiles(:two)
        auth_token = profile.gen_auth_token

        # Create event owned by profile
        owned_event = Event.create(
          owner: profile,
          status: "published",
          display: "hidden",
          title: "My Private Event",
          start_time: DateTime.new(2024, 2, 22, 10, 0, 0, "+00:00"),
          end_time: DateTime.new(2024, 2, 22, 11, 0, 0, "+00:00"),
          group: groups(:two),
          event_type: "event"
        )

        # Create event in group where profile is manager
        Membership.create(profile: profile, target: group, role: "manager")
        group_event = Event.create(
          owner: owner,
          group: group,
          status: "published",
          display: "hidden",
          title: "Group Private Event",
          start_time: DateTime.new(2024, 2, 22, 10, 0, 0, "+00:00"),
          end_time: DateTime.new(2024, 2, 22, 11, 0, 0, "+00:00"),
          group: group,
          event_type: "event"
        )

        # Create event where profile has event role
        other_event = Event.create(
          owner: owner,
          status: "published",
          display: "hidden",
          title: "Role Private Event",
          start_time: DateTime.new(2024, 2, 22, 10, 0, 0, "+00:00"),
          end_time: DateTime.new(2024, 2, 22, 11, 0, 0, "+00:00"),
          group: group,
          event_type: "event"
        )
        EventRole.create(
          event: other_event,
          item_type: "Profile",
          item_id: profile.id,
          role: "speaker"
        )

        get "/api/event/my_private", headers: { "Authorization" => "Bearer #{auth_token}" }

        assert_response :success
        events = JSON.parse(@response.body)["events"]
        assert_equal 3, events.count
        event_ids = events.map { |e| e["id"] }
        assert_includes event_ids, owned_event.id
        assert_includes event_ids, group_event.id
        assert_includes event_ids, other_event.id
      end

      test "event/my_private_track" do
        profile = profiles(:one)
        auth_token = profile.gen_auth_token
        group = groups(:two)

        # Create public track
        public_track = Track.create(group: group, kind: "public")
        public_track_event = Event.create(
          owner: profile,
          status: "published",
          display: "normal",
          title: "Public Track Event",
          start_time: DateTime.new(2024, 2, 22, 10, 0, 0, "+00:00"),
          end_time: DateTime.new(2024, 2, 22, 11, 0, 0, "+00:00"),
          group: group,
          track: public_track,
          event_type: "event"
        )

        # Create private track
        private_track = Track.create(group: group, kind: "private")
        private_track_event = Event.create(
          owner: profile,
          status: "published",
          display: "normal",
          title: "Private Track Event",
          start_time: DateTime.new(2024, 2, 22, 10, 0, 0, "+00:00"),
          end_time: DateTime.new(2024, 2, 22, 11, 0, 0, "+00:00"),
          group: group,
          track: private_track,
          event_type: "event"
        )

        # Give profile access to private track
        TrackRole.create(group: group, profile: profile, track: private_track)

        # Create event with no track
        no_track_event = Event.create(
          owner: profile,
          status: "published",
          display: "normal",
          title: "No Track Event",
          start_time: DateTime.new(2024, 2, 22, 10, 0, 0, "+00:00"),
          end_time: DateTime.new(2024, 2, 22, 11, 0, 0, "+00:00"),
          group: group,
          event_type: "event"
        )

        get "/api/event/my_private_track", params: { group_id: group.id }, headers: { "Authorization" => "Bearer #{auth_token}" }

        assert_response :success
        events = JSON.parse(@response.body)["events"]
        # assert_equal 3, events.count
        event_ids = events.map { |e| e["id"] }
        assert_includes event_ids, public_track_event.id
        assert_includes event_ids, private_track_event.id
        assert_includes event_ids, no_track_event.id
      end

      test "event/list returns events based on track access" do
        profile = profiles(:one)
        auth_token = profile.gen_auth_token
        group = groups(:two)
        Membership.find_by(profile: profile, target: group).update(role: "member")

        # Create public track
        public_track = Track.create(group: group, kind: "public")
        public_track_event = Event.create(
          owner: profile,
          status: "published",
          display: "normal",
          title: "Public Track Event",
          start_time: DateTime.new(2024, 2, 22, 10, 0, 0, "+00:00"),
          end_time: DateTime.new(2024, 2, 22, 11, 0, 0, "+00:00"),
          group: group,
          track: public_track,
          event_type: "event"
        )

        # Create private track
        private_track = Track.create(group: group, kind: "private")
        private_track_event = Event.create(
          owner: profile,
          status: "published",
          display: "normal",
          title: "Private Track Event",
          start_time: DateTime.new(2024, 2, 22, 10, 0, 0, "+00:00"),
          end_time: DateTime.new(2024, 2, 22, 11, 0, 0, "+00:00"),
          group: group,
          track: private_track,
          event_type: "event"
        )

        # Create event with no track
        no_track_event = Event.create(
          owner: profile,
          status: "published",
          display: "normal",
          title: "No Track Event",
          start_time: DateTime.new(2024, 2, 22, 10, 0, 0, "+00:00"),
          end_time: DateTime.new(2024, 2, 22, 11, 0, 0, "+00:00"),
          group: group,
          event_type: "event"
        )

        # Test without auth - should only see public track and no track events
        get "/api/event/list", params: { group_id: group.id }
        assert_response :success
        events = JSON.parse(@response.body)["events"]
        event_ids = events.map { |e| e["id"] }
        assert_includes event_ids, public_track_event.id
        assert_includes event_ids, no_track_event.id
        assert_not_includes event_ids, private_track_event.id

        # Test with auth but no track role - same as without auth
        get "/api/event/list", params: { group_id: group.id }, headers: { "Authorization" => "Bearer #{auth_token}" }
        assert_response :success
        events = JSON.parse(@response.body)["events"]
        event_ids = events.map { |e| e["id"] }
        assert_includes event_ids, public_track_event.id
        assert_includes event_ids, no_track_event.id
        assert_not_includes event_ids, private_track_event.id

        # Give access to private track
        TrackRole.create(group: group, profile: profile, track: private_track)

        # Test with auth and track role - should see all events
        Comment.create(profile: profile, comment_type: "star", item_type: "Event", item_id: public_track_event.id)

        get "/api/event/list", params: { group_id: group.id, with_stars: 1 }, headers: { "Authorization" => "Bearer #{auth_token}" }
        assert_response :success
        events = JSON.parse(@response.body)["events"]
        event_ids = events.map { |e| e["id"] }
        assert_includes event_ids, public_track_event.id
        assert_includes event_ids, private_track_event.id
        assert_includes event_ids, no_track_event.id

        assert events.first["is_starred"]

        # Test filtering by track
        get "/api/event/list", params: { group_id: group.id, track_id: private_track.id }, headers: { "Authorization" => "Bearer #{auth_token}" }
        assert_response :success
        events = JSON.parse(@response.body)["events"]
        event_ids = events.map { |e| e["id"] }
        assert_equal [private_track_event.id], event_ids
      end
  end
end