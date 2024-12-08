require "test_helper"

class Api::VenueControllerTest < ActionDispatch::IntegrationTest
  # generate test for venue/create
  test "api#venue/create" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token

    assert_changes "Venue.count" do
    post api_venue_create_url,
      params: {
        auth_token: auth_token,
        group_id: 1,
        venue: {
          title: "created venue",
          location: "new venue location",
          geo_lat: 22.3193,
          geo_lng: 114.1694,
          availabilities_attributes: [
            { day: "2024-01-01", intervals: [ [ "09:00", "17:00" ] ], role: "manager" }
          ],
          venue_overrides_attributes: [
            { day: "2024-01-01", data: [ [ "09:00", "17:00" ] ], role: "manager" }
          ],
          venue_timeslots_attributes: [
            { day_of_week: "monday", start_at: "09:00", end_at: "17:00", role: "manager" }
          ]
        }
      }
      assert Venue.find_by(title: "created venue").present?
      p Venue.find_by(title: "created venue").availabilities.inspect
      p Venue.find_by(title: "created venue").venue_overrides.inspect
      p Venue.find_by(title: "created venue").venue_timeslots.inspect
    end
  end

  test "api#venue/update" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token

    assert_changes "Venue.find_by(id: 540).title" do
    post api_venue_update_url,
      params: { auth_token: auth_token, id: 540, venue: {
        title: "updated venue",
        about: "updated venue description"
      } }
      assert Venue.find_by(title: "updated venue").present?
    end
  end

  test "api#venue/remove" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token

    assert_changes "Venue.find_by(id: 540).visibility" do
    post api_venue_remove_url,
      params: { auth_token: auth_token, id: 540 }
    end
  end

  test "api#venue/check_availability" do
    venue = Venue.create!(
      title: "test venue",
      location: "test location",
      geo_lat: 22.3193,
      geo_lng: 114.1694,
      start_date: "2023-09-01",
      end_date: "2023-12-31",
      group_id: 1,
      visibility: "all"
    )

    post api_venue_check_availability_url,
      params: {
        id: venue.id,
        start_time: "2023-08-01T10:00:00Z",
        end_time: "2023-08-01T12:00:00Z",
        timezone: "UTC"
      }

    assert_response :success
    response_body = JSON.parse(response.body)
    assert_not response_body["available"]
    assert response_body["message"].is_a?(String)
  end

  test "api#venue/check_availability with venue_timeslot" do
    venue = Venue.create!(
      title: "test venue with timeslot",
      location: "test location",
      geo_lat: 22.3193,
      geo_lng: 114.1694,
      start_date: "2023-09-01",
      end_date: "2023-12-31",
      group_id: 1,
      visibility: "all"
    )

    Availability.create!(
      item: venue,
      day_of_week: "monday",
      intervals: [[ "09:00", "17:00" ]],
    )

    post api_venue_check_availability_url,
      params: {
        id: venue.id,
        start_time: "2023-09-04T10:00:00Z", # Monday
        end_time: "2023-09-04T12:00:00Z",
        timezone: "UTC"
      }

    assert_response :success
    response_body = JSON.parse(response.body)
    assert response_body["available"]
    assert response_body["message"].is_a?(String)
  end

  test "api#venue/check_availability with venue_timeslot and timezone Asia/Shanghai" do
    venue = Venue.create!(
      title: "test venue with timeslot and timezone",
      location: "test location",
      geo_lat: 22.3193,
      geo_lng: 114.1694,
      start_date: "2023-09-01",
      end_date: "2023-12-31",
      group_id: 1,
      visibility: "all"
    )

    Availability.create!(
      item: venue,
      day_of_week: "monday",
      intervals: [[ "09:00", "11:10" ],[ "10:00", "12:10" ]],
    )

    post api_venue_check_availability_url,
      params: {
        id: venue.id,
        start_time: "2023-09-04T10:00:00+0800", # Monday 10:00 - 12:00 AM in Asia/Shanghai timezone
        end_time: "2023-09-04T12:00:00+0800",
        timezone: "Asia/Shanghai"
      }

    assert_response :success
    response_body = JSON.parse(response.body)
    assert response_body["available"]
    assert response_body["message"].is_a?(String)
  end

  test "api#venue/check_availability with venue_override" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token

    venue = Venue.create!(
      title: "test venue with override",
      location: "test location",
      geo_lat: 22.3193,
      geo_lng: 114.1694,
      start_date: "2023-09-01",
      end_date: "2023-12-31",
      group_id: 1,
      visibility: "all"
    )

    Availability.create!(
      item: venue,
      day: "2023-09-04", # Monday
      intervals: [[ "09:00", "17:00" ]],
    )

    post api_venue_check_availability_url,
      params: {
        auth_token: auth_token,
        id: venue.id,
        start_time: "2023-09-04T10:00:00Z", # Monday
        end_time: "2023-09-04T12:00:00Z",
        timezone: "UTC"
      }

    assert_response :success
    response_body = JSON.parse(response.body)
    assert response_body["available"]
    assert response_body["message"].is_a?(String)
  end
end
