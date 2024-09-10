require "test_helper"

class Api::VoucherControllerTest < ActionDispatch::IntegrationTest
  test "api#voucher/create" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    assert_difference "Voucher.count", 1 do
      post api_voucher_create_url, params: {
        auth_token: auth_token,
        badge_class_id: 1,
        badge_title: "super hello",
        message: "send hello badge"
      }
    end
    code = JSON.parse(response.body)["voucher"]["code"]
    assert_equal Voucher.find_by(badge_title: "super hello").code, code
  end

  test "api#voucher/get_code" do
    profile = profiles(:one)
    auth_token = profile.gen_auth_token
    get api_voucher_get_code_url(id: 1, auth_token: auth_token)
    assert_response :success
    assert_equal Voucher.find_by(badge_title: "test hello").code, "11111"
  end

  test "api#voucher/use" do
    profile = profiles(:two)
    auth_token = profile.gen_auth_token
    post api_voucher_use_url, params: {
      auth_token: auth_token,
      id: 1,
      code: "11111"
    }
    assert_response :success
    assert_equal Voucher.find_by(code: "11111").counter, 4
    assert_equal profile.owned_badges.count, 1
  end

  test "api#voucher/revoke" do
    profile = profiles(:one)
    auth_token = profile.gen_auth_token
    voucher = vouchers(:one) # Assuming you have a fixture for vouchers
    post api_voucher_revoke_url, params: {
      auth_token: auth_token,
      id: 1
    }
    assert_response :success
    assert_equal Voucher.find_by(code: voucher.code).counter, 0
  end

  test "api#voucher/send_badge" do
    profile = profiles(:one)
    auth_token = profile.gen_auth_token
    post api_voucher_send_badge_url, params: {
      auth_token: auth_token,
      badge_class_id: 1,
      badge_title: "super hello",
      message: "send hello badge",
      receivers: [ "mooncake" ]
    }
    assert_response :success
    assert_equal Voucher.find_by(badge_title: "super hello").counter, 1

    # test accept badge
    profile2 = profiles(:two)
    auth_token2 = profile2.gen_auth_token
    post api_voucher_use_url, params: {
      auth_token: auth_token2,
      id: Voucher.find_by(badge_title: "super hello").id
    }
    assert_response :success
    assert_equal 0, Voucher.find_by(badge_title: "super hello").counter
    assert_equal 1, profile2.owned_badges.count
  end

  test "api#voucher/send_badge_by_email" do
    profile = profiles(:one)
    auth_token = profile.gen_auth_token
    post api_voucher_send_badge_by_email_url, params: {
      auth_token: auth_token,
      badge_class_id: 1,
      badge_title: "super hello",
      message: "send hello badge",
      receivers: [ profiles(:two).email ]
    }
    assert_response :success
    assert_equal Voucher.find_by(badge_title: "super hello").counter, 1

    # test accept badge
    profile2 = profiles(:two)
    auth_token2 = profile2.gen_auth_token
    post api_voucher_use_url, params: {
      auth_token: auth_token2,
      id: Voucher.find_by(badge_title: "super hello").id
    }
    assert_response :success
    assert_equal 0, Voucher.find_by(badge_title: "super hello").counter
    assert_equal 1, profile2.owned_badges.count
  end

  test "api#voucher/send_badge_by_address" do
    profile = profiles(:one)
    auth_token = profile.gen_auth_token
    post api_voucher_send_badge_by_address_url, params: {
      auth_token: auth_token,
      badge_class_id: 1,
      badge_title: "super hello",
      message: "send hello badge",
      receivers: [ profiles(:four).address ]
    }
    assert_response :success
    assert_equal Voucher.find_by(badge_title: "super hello").counter, 1

    # test accept badge
    profile2 = profiles(:four)
    auth_token2 = profile2.gen_auth_token
    post api_voucher_use_url, params: {
      auth_token: auth_token2,
      id: Voucher.find_by(badge_title: "super hello").id
    }
    assert_response :success
    assert_equal 0, Voucher.find_by(badge_title: "super hello").counter
    assert_equal 1, profile2.owned_badges.count
  end

  test "api#voucher/reject_badge" do
    profile = profiles(:one)
    auth_token = profile.gen_auth_token
    post api_voucher_send_badge_url, params: {
      auth_token: auth_token,
      badge_class_id: 1,
      badge_title: "super hello",
      message: "send hello badge",
      receivers: [ "mooncake" ]
    }
    assert_response :success
    assert_equal Voucher.find_by(badge_title: "super hello").counter, 1

    # test reject badge
    profile2 = profiles(:two)
    auth_token2 = profile2.gen_auth_token
    post api_voucher_reject_badge_url, params: {
      auth_token: auth_token2,
      id: Voucher.find_by(badge_title: "super hello").id
    }
    assert_response :success
    assert_equal 0, Voucher.find_by(badge_title: "super hello").counter
    assert_equal 0, profile2.owned_badges.count
  end
end
