require "test_helper"

class Api::PointControllerTest < ActionDispatch::IntegrationTest
  test "api#point/create" do
    profile = profiles(:one)
    auth_token = profile.gen_auth_token
    post api_point_create_url, params: {
      auth_token: auth_token,
        point_class_id: 1,
        receivers: [
          {
            receiver: profiles(:four).address,
            value: 100
          }
        ]
    }
    assert_response :success
    assert_equal PointTransfer.find_by(point_class_id: 1, sender_id: 1).value, 100
    point_transfer_id = JSON.parse(response.body)["point_transfers"][0]["id"]

    profile2 = profiles(:four)
    auth_token2 = profile2.gen_auth_token
    post api_point_accept_url, params: {
      auth_token: auth_token2,
      point_transfer_id: point_transfer_id
    }
    assert_response :success
    assert PointTransfer.find_by(id: point_transfer_id).status == "accepted"
    assert PointBalance.find_by(point_class_id: 1, owner_id: profile2.id).value == 100

    post api_point_transfer_url, params: {
      auth_token: auth_token2,
      point_class_id: 1,
      value: 20,
      target_profile_id: profiles(:two).id
    }
    assert_response :success
    assert_equal PointBalance.find_by(point_class_id: 1, owner: profiles(:two)).value, 20
    assert_equal PointBalance.find_by(point_class_id: 1, owner: profiles(:four)).value, 80
    assert PointTransfer.find_by(point_class_id: 1, sender_id: profile2.id).value, 20
  end

  test "api#point/reject" do
    profile = profiles(:one)
    auth_token = profile.gen_auth_token
    post api_point_create_url, params: {
      auth_token: auth_token,
        point_class_id: 1,
        receivers: [
          {
            receiver: profiles(:four).address,
            value: 100
          }
        ]
    }
    assert_response :success
    assert_equal PointTransfer.find_by(point_class_id: 1, sender_id: 1).value, 100
    point_transfer_id = JSON.parse(response.body)["point_transfers"][0]["id"]


    profile2 = profiles(:four)
    auth_token2 = profile2.gen_auth_token
    post api_point_reject_url, params: {
      auth_token: auth_token2,
      point_transfer_id: point_transfer_id
    }
    assert_response :success
    assert PointTransfer.find_by(id: point_transfer_id).status == "rejected"
  end
end
