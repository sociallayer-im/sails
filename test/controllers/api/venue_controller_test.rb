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
          geo_lng: 114.1694
        }
      }
      assert Venue.find_by(title: "created venue").present?
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
end
