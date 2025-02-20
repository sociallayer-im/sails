require "test_helper"

module Core
  class ApiTest < ActionDispatch::IntegrationTest
    test "GET /api/hello returns hello world" do
      get "/api/hello"

      assert_response :success
      assert_equal({ "hello" => "world" }, JSON.parse(@response.body))
    end
  end
end