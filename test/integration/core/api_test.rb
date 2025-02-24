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
      end
  end
end