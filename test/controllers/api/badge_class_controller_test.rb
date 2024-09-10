require "test_helper"

class Api::BadgeClassControllerTest < ActionDispatch::IntegrationTest
  test "create" do
    auth_token = profiles(:one).gen_auth_token
    assert_difference "BadgeClass.count", 1 do
      post api_badge_class_create_url, params: { auth_token: auth_token, badge_class: { group_id: 1, name: "test", title: "test", content: "test badge class", transferable: true, image_url: "https://test.com/image.png" } }
    end
    assert_response :success
    assert_equal "test", BadgeClass.last.name
  end
end
