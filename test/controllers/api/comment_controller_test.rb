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

    post api_comment_index_url, params: { auth_token: auth_token, item_type: "Event", item_id: 1 }
    assert_response :success
    comments = JSON.parse(response.body)["comments"]
    assert comments.count == 1
    assert comments.first["content"] == "hello"
  end

end
