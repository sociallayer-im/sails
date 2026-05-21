require "test_helper"

class Api::RecurringControllerTest < ActionDispatch::IntegrationTest
  test "api#recurring/create" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")
    profile2 = Profile.find_by(handle: "mooncake")
    profile3 = Profile.find_by(handle: "biscuit")

    assert_difference "Event.count", 5 do
      post api_recurring_create_url, params: {
        auth_token: auth_token,
        group_id: group.id,
        event_count: 5,
        interval: "week",
        timezone: "Asia/Shanghai",
        title: "Weekly Meeting",
        content: "Team weekly sync-up meeting",
        start_time: DateTime.new(2024, 7, 8, 10, 20, 30).to_s,
        end_time: DateTime.new(2024, 7, 8, 12, 20, 30).to_s,
        location: "central park",
        event_roles_attributes: [ { role: "co_host", item_type: "Profile", item_id: profile2.id } ]
      }
    end
    assert_response :success

    recurring_id = JSON.parse(response.body)["recurring"]["id"]
    recurring = Recurring.find(recurring_id)

    # p recurring.events.order("start_time").map {|ev| [ev.start_time.to_s, ev.end_time.to_s]}

    assert_equal recurring.events.order("start_time").map { |ev| [ ev.start_time.to_s, ev.end_time.to_s ] },
    [ [ "2024-07-08 10:20:30 UTC", "2024-07-08 12:20:30 UTC" ], [ "2024-07-15 10:20:30 UTC", "2024-07-15 12:20:30 UTC" ], [ "2024-07-22 10:20:30 UTC", "2024-07-22 12:20:30 UTC" ], [ "2024-07-29 10:20:30 UTC", "2024-07-29 12:20:30 UTC" ], [ "2024-08-05 10:20:30 UTC", "2024-08-05 12:20:30 UTC" ] ]

    # verify initial event_roles for first event
    assert_equal [["co_host", "Profile", profile2.id]], recurring.events.order("start_time").second.event_roles.map { |er| [ er.role, er.item_type, er.item_id ] }
    event_roles_before_update = recurring.events.order("start_time").second.event_roles
    p "event_roles_before_update"
    p event_roles_before_update

    after_event_id = Event.find_by(recurring_id: recurring_id, start_time: DateTime.parse("2024-07-15 10:20:30 UTC")).id
    post api_recurring_update_url,
      params: { auth_token: auth_token,
        recurring_id: recurring_id,
        start_time_diff: 3600,
        end_time_diff: 7200,
        selector: "after",
        after_event_id: after_event_id,
        title: "New Weekly Meeting",
        event_roles_attributes: [ { role: "co_host", item_type: "Profile", item_id: profile3.id }, { id: event_roles_before_update.first.id, role: "co_host", item_type: "Profile", item_id: profile2.id, _destroy: true } ]
        # event_roles_attributes: [ { role: "co_host", item_type: "Profile", item_id: profile3.id } ]
    }
    assert_response :success

    assert_equal recurring.events.order("start_time").map { |ev| [ ev.start_time.to_s, ev.end_time.to_s ] },
    [ [ "2024-07-08 10:20:30 UTC", "2024-07-08 12:20:30 UTC" ], [ "2024-07-15 11:20:30 UTC", "2024-07-15 14:20:30 UTC" ], [ "2024-07-22 11:20:30 UTC", "2024-07-22 14:20:30 UTC" ], [ "2024-07-29 11:20:30 UTC", "2024-07-29 14:20:30 UTC" ], [ "2024-08-05 11:20:30 UTC", "2024-08-05 14:20:30 UTC" ] ]

    post api_recurring_cancel_event_url, params: { auth_token: auth_token, recurring_id: recurring_id, selector: "after", event_id: after_event_id }
    assert_response :success

    assert_equal recurring.events.order("start_time").map { |ev| [ ev.status, ev.start_time.to_s ] },
    [["published", "2024-07-08 10:20:30 UTC"], ["cancelled", "2024-07-15 11:20:30 UTC"], ["cancelled", "2024-07-22 11:20:30 UTC"], ["cancelled", "2024-07-29 11:20:30 UTC"], ["cancelled", "2024-08-05 11:20:30 UTC"]]

    # verify event_roles updated only for events after the selected one
    events_ordered = recurring.events.order("start_time")
    assert_equal [["co_host", "Profile", profile3.id]], events_ordered.second.event_roles.map { |er| [ er.role, er.item_type, er.item_id ] }

  end

  # ── Venue availability & overlap for recurring events ────────────────────

  # All dates below are Mondays (UTC+8 / Asia/Shanghai used by group "guildx"):
  #   2025-01-06 = Mon,  2025-01-13 = Mon,  2025-01-20 = Mon
  # start_time "2025-01-06T02:00:00Z" = 10:00 CST on Mon 6 Jan (same date in CST)

  def build_venue(attrs = {})
    Venue.create!({
      title: "recurring test venue #{SecureRandom.hex(4)}",
      location: "test loc",
      group_id: 1,
      visibility: "all"
    }.merge(attrs))
  end

  test "recurring/create with venue: no overlap, no availability rules → allowed" do
    profile = Profile.find_by(handle: "cookie")
    venue = build_venue

    assert_difference "Event.count", 3 do
      post api_recurring_create_url, params: {
        auth_token: profile.gen_auth_token,
        group_id: 1,
        event_count: 3,
        interval: "week",
        timezone: "Asia/Shanghai",
        title: "weekly venue ok",
        start_time: "2025-01-06T02:00:00Z",
        end_time:   "2025-01-06T04:00:00Z",
        venue_id: venue.id,
        location: "x", display: "normal", event_type: "event"
      }
    end
    assert_equal "ok", JSON.parse(response.body)["result"]
  end

  test "recurring/create with venue: overlap on first occurrence → rejected" do
    profile = Profile.find_by(handle: "cookie")
    venue = build_venue
    Event.create!(
      group_id: 1, owner_id: 1, venue: venue, status: "published",
      title: "blocker wk1", display: "normal", event_type: "event",
      start_time: "2025-01-06T01:00:00Z", end_time: "2025-01-06T05:00:00Z",
      key: SecureRandom.hex(8)
    )

    assert_no_difference "Event.count" do
      post api_recurring_create_url, params: {
        auth_token: profile.gen_auth_token,
        group_id: 1, event_count: 3, interval: "week",
        timezone: "Asia/Shanghai", title: "weekly venue overlap1",
        start_time: "2025-01-06T02:00:00Z", end_time: "2025-01-06T04:00:00Z",
        venue_id: venue.id, location: "x", display: "normal", event_type: "event"
      }
    end
    assert_equal "error", JSON.parse(response.body)["result"]
  end

  test "recurring/create with venue: overlap on non-first occurrence → rejected" do
    profile = Profile.find_by(handle: "cookie")
    venue = build_venue
    # week 1 is free; block week 2
    Event.create!(
      group_id: 1, owner_id: 1, venue: venue, status: "published",
      title: "blocker wk2", display: "normal", event_type: "event",
      start_time: "2025-01-13T01:00:00Z", end_time: "2025-01-13T05:00:00Z",
      key: SecureRandom.hex(8)
    )

    assert_no_difference "Event.count" do
      post api_recurring_create_url, params: {
        auth_token: profile.gen_auth_token,
        group_id: 1, event_count: 3, interval: "week",
        timezone: "Asia/Shanghai", title: "weekly venue overlap2",
        start_time: "2025-01-06T02:00:00Z", end_time: "2025-01-06T04:00:00Z",
        venue_id: venue.id, location: "x", display: "normal", event_type: "event"
      }
    end
    assert_equal "error", JSON.parse(response.body)["result"]
  end

  test "recurring/create with venue: overlap only with cancelled event → allowed" do
    profile = Profile.find_by(handle: "cookie")
    venue = build_venue
    Event.create!(
      group_id: 1, owner_id: 1, venue: venue, status: "cancelled",
      title: "cancelled blocker", display: "normal", event_type: "event",
      start_time: "2025-01-13T01:00:00Z", end_time: "2025-01-13T05:00:00Z",
      key: SecureRandom.hex(8)
    )

    assert_difference "Event.count", 3 do
      post api_recurring_create_url, params: {
        auth_token: profile.gen_auth_token,
        group_id: 1, event_count: 3, interval: "week",
        timezone: "Asia/Shanghai", title: "weekly venue cancelled ok",
        start_time: "2025-01-06T02:00:00Z", end_time: "2025-01-06T04:00:00Z",
        venue_id: venue.id, location: "x", display: "normal", event_type: "event"
      }
    end
    assert_equal "ok", JSON.parse(response.body)["result"]
  end

  test "recurring/create with venue: event outside weekly timeslot → rejected" do
    profile = Profile.find_by(handle: "cookie")
    venue = build_venue
    Availability.create!(item: venue, day_of_week: "monday", intervals: [["09:00", "11:00"]], role: "all")

    assert_no_difference "Event.count" do
      post api_recurring_create_url, params: {
        auth_token: profile.gen_auth_token,
        group_id: 1, event_count: 3, interval: "week",
        timezone: "Asia/Shanghai", title: "weekly venue outside slot",
        # 10:00–13:00 CST — ends after 11:00 slot closes
        start_time: "2025-01-06T02:00:00Z", end_time: "2025-01-06T05:00:00Z",
        venue_id: venue.id, location: "x", display: "normal", event_type: "event"
      }
    end
    assert_equal "error", JSON.parse(response.body)["result"]
  end

  test "recurring/create with venue: availability violation on non-first occurrence → rejected" do
    profile = Profile.find_by(handle: "cookie")
    venue = build_venue
    # Monday OK, but week 2 Mon has a closed-day override
    Availability.create!(item: venue, day_of_week: "monday", intervals: [["09:00", "18:00"]], role: "all")
    Availability.create!(item: venue, day: "2025-01-13", intervals: [], role: "all")

    assert_no_difference "Event.count" do
      post api_recurring_create_url, params: {
        auth_token: profile.gen_auth_token,
        group_id: 1, event_count: 3, interval: "week",
        timezone: "Asia/Shanghai", title: "weekly venue avail violation wk2",
        start_time: "2025-01-06T02:00:00Z", end_time: "2025-01-06T04:00:00Z",
        venue_id: venue.id, location: "x", display: "normal", event_type: "event"
      }
    end
    assert_equal "error", JSON.parse(response.body)["result"]
  end

  test "recurring/update with venue: shift applies once, not double (double-shift bug)" do
    profile = Profile.find_by(handle: "cookie")
    venue = build_venue
    Availability.create!(item: venue, day_of_week: "monday", intervals: [["09:00", "18:00"]], role: "all")

    # Create 3 weekly events at 10:00–12:00 CST
    post api_recurring_create_url, params: {
      auth_token: profile.gen_auth_token,
      group_id: 1, event_count: 3, interval: "week",
      timezone: "Asia/Shanghai", title: "shift me recurring",
      start_time: "2025-01-06T02:00:00Z", end_time: "2025-01-06T04:00:00Z",
      venue_id: venue.id, location: "x", display: "normal", event_type: "event"
    }
    assert_equal "ok", JSON.parse(response.body)["result"]
    recurring_id = JSON.parse(response.body)["recurring"]["id"]

    # Shift all events by 1 hour (3600s) while keeping same venue
    post api_recurring_update_url, params: {
      auth_token: profile.gen_auth_token,
      recurring_id: recurring_id,
      venue_id: venue.id,
      start_time_diff: 3600,
      end_time_diff: 3600,
      title: "shift me recurring"
    }
    assert_equal "ok", JSON.parse(response.body)["result"]

    events = Event.where(recurring_id: recurring_id).order(:start_time)
    # Should be 11:00–13:00 CST = 03:00–05:00 UTC, not 12:00–14:00 (double-shift)
    assert_equal "2025-01-06 03:00:00 UTC", events.first.start_time.utc.strftime("%Y-%m-%d %H:%M:%S UTC")
    assert_equal "2025-01-06 05:00:00 UTC", events.first.end_time.utc.strftime("%Y-%m-%d %H:%M:%S UTC")
  end

  test "recurring/update with venue: overlap with external event → rejected" do
    profile = Profile.find_by(handle: "cookie")
    venue = build_venue

    post api_recurring_create_url, params: {
      auth_token: profile.gen_auth_token,
      group_id: 1, event_count: 2, interval: "week",
      timezone: "Asia/Shanghai", title: "update conflict recurring",
      start_time: "2025-01-06T02:00:00Z", end_time: "2025-01-06T04:00:00Z",
      venue_id: venue.id, location: "x", display: "normal", event_type: "event"
    }
    recurring_id = JSON.parse(response.body)["recurring"]["id"]

    # Block the shifted position for week 1 (03:00–05:00 UTC)
    Event.create!(
      group_id: 1, owner_id: 1, venue: venue, status: "published",
      title: "external blocker", display: "normal", event_type: "event",
      start_time: "2025-01-06T03:30:00Z", end_time: "2025-01-06T04:30:00Z",
      key: SecureRandom.hex(8)
    )

    post api_recurring_update_url, params: {
      auth_token: profile.gen_auth_token,
      recurring_id: recurring_id,
      venue_id: venue.id,
      start_time_diff: 3600,
      end_time_diff: 3600
    }
    assert_equal "error", JSON.parse(response.body)["result"]
    # Events should NOT have been shifted
    events = Event.where(recurring_id: recurring_id).order(:start_time)
    assert_equal "2025-01-06 02:00:00 UTC", events.first.start_time.utc.strftime("%Y-%m-%d %H:%M:%S UTC")
  end

  test "recurring/update with venue: availability violation → rejected" do
    profile = Profile.find_by(handle: "cookie")
    venue = build_venue
    # Monday 09:00–12:00 only
    Availability.create!(item: venue, day_of_week: "monday", intervals: [["09:00", "12:00"]], role: "all")

    post api_recurring_create_url, params: {
      auth_token: profile.gen_auth_token,
      group_id: 1, event_count: 2, interval: "week",
      timezone: "Asia/Shanghai", title: "avail violation recurring",
      start_time: "2025-01-06T02:00:00Z", end_time: "2025-01-06T04:00:00Z",  # 10–12 CST, within slot
      venue_id: venue.id, location: "x", display: "normal", event_type: "event"
    }
    recurring_id = JSON.parse(response.body)["recurring"]["id"]

    # Shift by 2 hours → 12:00–14:00 CST, outside slot
    post api_recurring_update_url, params: {
      auth_token: profile.gen_auth_token,
      recurring_id: recurring_id,
      venue_id: venue.id,
      start_time_diff: 7200,
      end_time_diff: 7200
    }
    assert_equal "error", JSON.parse(response.body)["result"]
  end
end
