require "test_helper"

class Api::MarkerControllerTest < ActionDispatch::IntegrationTest
  test "api#marker/create" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token

    assert_changes "Marker.count" do
    post api_marker_create_url,
      params: {
        auth_token: auth_token,
        group_id: 1,
        marker: {
        title: "created marker",
        about: "new marker description",
        geo_lat: 22.3193,
        geo_lng: 114.1694
      } }
    assert_response :success
    end

    get api_marker_list_url, params: { auth_token: auth_token, group_id: 1 }
    assert_response :success
    markers = JSON.parse(response.body)["markers"]
    assert_equal markers.count, 2
    assert markers.last["title"] == "created marker"


    get api_marker_get_url, params: { auth_token: auth_token, id: Marker.last.id }
    assert_response :success
    marker = JSON.parse(response.body)["marker"]
    assert_equal marker["title"], "created marker"
  end

  test "api#marker/update" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token

    assert_changes "Marker.find_by(id: 1).title" do
    post api_marker_update_url,
      params: { auth_token: auth_token, id: 1, marker: {
        title: "updated marker",
        about: "updated marker description"
      } }
    assert_response :success
    end
  end

  test "api#marker/remove" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token

    assert_changes "Marker.find_by(id: 1).status", false do
    post api_marker_remove_url,
        params: { auth_token: auth_token, id: 1 }
      assert_response :success
    end
  end

  test "api#marker/checkin" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token

    assert_changes "Comment.where(item_type: 'Marker', item_id: 1).count" do
    post api_marker_checkin_url,
      params: { auth_token: auth_token, id: 1, title: "checkin", content: "checkin content" }
    assert_response :success
    end
  end
end
