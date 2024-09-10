require "test_helper"

class Api::VoucherControllerTest < ActionDispatch::IntegrationTest
  # generate test for voucher/create
  test "api#voucher/create" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token

    post api_voucher_create_url, params: { auth_token: auth_token, voucher: {
      code: "VOUCHER123",
      description: "Voucher for 123",
    } }
  end
end
