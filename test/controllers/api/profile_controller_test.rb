require "test_helper"

class Api::ProfileControllerTest < ActionDispatch::IntegrationTest

  # test "api#profile/signin_with_email" do
  #   post api_service_send_email_url, params: { context: "email-signin", email: "example@gmail.com" }
  #   assert_response :success
  #   p response.body

  #   post api_profile_signin_with_email_url, params: { email: "example@gmail.com", code: ProfileToken.last.code }
  #   assert_response :success
  #   p response.body
  #   auth_token = JSON.parse(response.body)["auth_token"]
  #   p Profile.find_by(email: "example@gmail.com")

  #   post api_profile_create_url, params: { auth_token: auth_token, handle: "example" }
  #   assert_response :success
  #   p response.body

  #   get api_profile_get_by_email_url, params: { email: "example@gmail.com" }
  #   assert_response :success
  #   p response.body

  #   get api_profile_me_url, params: { auth_token: auth_token }
  #   assert_response :success
  # end

  # test "api#profile/set_verified_email" do
  #   post api_service_send_email_url, params: { context: "email-verify", email: "biscuit@gmail.com" }
  #   assert_response :success
  #   p response.body

  #   auth_token = Profile.find_by(handle: "biscuit").gen_auth_token
  #   post api_profile_set_verified_email_url, params: { auth_token: auth_token, email: "biscuit@gmail.com", code: ProfileToken.find_by(context: "email-verify", sent_to: "biscuit@gmail.com").code }
  #   assert_response :success
  #   p Profile.find_by(handle: "biscuit")
  # end

  test "api#profile/update" do
    auth_token = Profile.find_by(handle: "cookie").gen_auth_token

    post api_profile_update_url, params: { auth_token: auth_token, profile: { nickname: "binggan" } }
    p response.body
    assert_response :success
    p Profile.find_by(handle: "cookie").nickname == "binggan"
  end

end
