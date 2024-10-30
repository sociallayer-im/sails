require "test_helper"

class Api::RememberControllerTest < ActionDispatch::IntegrationTest
  test "create" do
    auth_token = profiles(:one).gen_auth_token
    badge_class = badge_classes(:soulbound)
    post api_remember_create_url, params: { auth_token: auth_token, badge_class_id: badge_class.id }
    assert_response :success

    voucher = Voucher.find_by(badge_class: badge_class)
    assert voucher.present?

    auth_token2 = profiles(:two).gen_auth_token
    post api_remember_join_url, params: { auth_token: auth_token2, voucher_id: voucher.id }
    assert_response :success

    auth_token3 = profiles(:three).gen_auth_token
    post api_remember_join_url, params: { auth_token: auth_token3, voucher_id: voucher.id }
    assert_response :success

    get api_remember_get_url, params: { auth_token: auth_token2, voucher_id: voucher.id }
    assert_response :success

    post api_remember_mint_url, params: { auth_token: auth_token, voucher_id: voucher.id }
    assert_response :success

    assert Badge.where(voucher: voucher).count == 3
  end

  test "cancel" do
    auth_token = profiles(:one).gen_auth_token
    badge_class = badge_classes(:soulbound)
    post api_remember_create_url, params: { auth_token: auth_token, badge_class_id: badge_class.id }
    assert_response :success

    voucher = Voucher.find_by(badge_class: badge_class)
    assert voucher.present?

    auth_token2 = profiles(:two).gen_auth_token
    post api_remember_join_url, params: { auth_token: auth_token2, voucher_id: voucher.id }
    assert_response :success

    auth_token3 = profiles(:three).gen_auth_token
    post api_remember_join_url, params: { auth_token: auth_token3, voucher_id: voucher.id }
    assert_response :success

    get api_remember_get_url, params: { auth_token: auth_token2, voucher_id: voucher.id }
    assert_response :success

    post api_remember_cancel_url, params: { auth_token: auth_token3, voucher_id: voucher.id }
    assert_response :success

    post api_remember_mint_url, params: { auth_token: auth_token, voucher_id: voucher.id }
    assert_response :success

    assert Badge.where(voucher: voucher).count == 2
  end
end
