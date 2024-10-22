require "test_helper"

class Api::CommentControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "api#comment/create" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token

    post api_comment_create_url, params: { auth_token: auth_token, comment: {
      item_type: "Event",
      item_id: 1,
      content: "hello",
      content_type: "text",
      comment_type: "comment",
    } }
    assert_response :success
    comment = Comment.find_by(content: "hello")
    assert comment
    assert comment.profile == profile

    post api_comment_list_url, params: { auth_token: auth_token, comment_type: "comment", item_type: "Event", item_id: 1 }
    assert_response :success
    comments = JSON.parse(response.body)["comments"]
    assert_equal comments.count, 1
    assert comments.first["content"] == "hello"


    post api_comment_create_url, params: { auth_token: auth_token, comment: {
      item_type: "Event",
      item_id: 1,
      comment_type: "star",
    } }
    assert_response :success

    get api_event_list_url, params: { auth_token: auth_token, group_id: 1, with_stars: true }
    assert_response :success
    events = JSON.parse(response.body)["events"]
    assert_equal events.find { |x| x["id"] == 1 }["star"], true
  end

end
