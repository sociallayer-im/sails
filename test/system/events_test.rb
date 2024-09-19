require "application_system_test_case"

class EventsTest < ApplicationSystemTestCase
  setup do
    @event = events(:one)
  end

  test "visiting the index" do
    visit events_url
    assert_selector "h1", text: "Events"
  end

  test "should create event" do
    visit events_url
    click_on "New event"

    fill_in "Cover url", with: @event.cover_url
    fill_in "Display", with: @event.display
    fill_in "End time", with: @event.end_time
    fill_in "Event type", with: @event.event_type
    fill_in "Group", with: @event.group_id
    fill_in "Location", with: @event.location
    fill_in "Meeting url", with: @event.meeting_url
    fill_in "Owner", with: @event.owner_id
    check "Require approval" if @event.require_approval
    fill_in "Start time", with: @event.start_time
    fill_in "Status", with: @event.status
    fill_in "Tags", with: @event.tags
    fill_in "Timezone", with: @event.timezone
    fill_in "Title", with: @event.title
    fill_in "Track", with: @event.track_id
    fill_in "Venue", with: @event.venue_id
    click_on "Create Event"

    assert_text "Event was successfully created"
    click_on "Back"
  end

  test "should update Event" do
    visit event_url(@event)
    click_on "Edit this event", match: :first

    fill_in "Cover url", with: @event.cover_url
    fill_in "Display", with: @event.display
    fill_in "End time", with: @event.end_time.to_s
    fill_in "Event type", with: @event.event_type
    fill_in "Group", with: @event.group_id
    fill_in "Location", with: @event.location
    fill_in "Meeting url", with: @event.meeting_url
    fill_in "Owner", with: @event.owner_id
    check "Require approval" if @event.require_approval
    fill_in "Start time", with: @event.start_time.to_s
    fill_in "Status", with: @event.status
    fill_in "Tags", with: @event.tags
    fill_in "Timezone", with: @event.timezone
    fill_in "Title", with: @event.title
    fill_in "Track", with: @event.track_id
    fill_in "Venue", with: @event.venue_id
    click_on "Update Event"

    assert_text "Event was successfully updated"
    click_on "Back"
  end

  test "should destroy Event" do
    visit event_url(@event)
    click_on "Destroy this event", match: :first

    assert_text "Event was successfully destroyed"
  end
end
