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
end
