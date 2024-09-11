require "test_helper"

class Api::ServiceControllerTest < ActionDispatch::IntegrationTest
  test "api#service/send_email" do
    profile = profiles(:one)
    auth_token = profile.gen_auth_token

    assert_difference 'ActionMailer::Base.deliveries.size', +1 do
      post api_service_send_email_url, params: {
        auth_token: auth_token,
        context: "email-verify",
        email: "test@example.com"
      }
    end

    assert_response :success
    assert ProfileToken.find_by(sent_to: "test@example.com", context: "email-verify")

    email = ActionMailer::Base.deliveries.last
    assert_equal ["test@example.com"], email.to
    assert_equal 'Social Layer Sign-In', email.subject
  end

end
