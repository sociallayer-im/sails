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
  end
end