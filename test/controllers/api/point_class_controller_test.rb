require "test_helper"

class Api::PointClassControllerTest < ActionDispatch::IntegrationTest
  test "api#point_class/create" do
    profile = profiles(:one)
    auth_token = profile.gen_auth_token
    post api_point_class_create_url, params: {
      auth_token: auth_token,
      point_class: {
      name: "pointt",
      title: "test point class",
      content: "test point class description",
      group_id: 1,
      point_type: "point"
}
    }
    assert_response :success
    assert PointClass.find_by(name: "pointt")
  end
end
