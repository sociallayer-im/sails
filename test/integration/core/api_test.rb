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
      assert_equal(event.id, JSON.parse(@response.body)["id"])
      p @response.body
    end
  end
end