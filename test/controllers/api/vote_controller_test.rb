require "test_helper"

class Api::VoteControllerTest < ActionDispatch::IntegrationTest
  test "api#vote/create" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token

    assert_difference "VoteProposal.count", 1 do
      post api_vote_create_url, params: {
        auth_token: auth_token,
        group_id: 1,
        vote_proposal: {
          title: "save the planet",
          content: "we should save the planet",
          max_choice: 1,
          eligibile_group_id: 1,
          start_time: DateTime.now,
          end_time: DateTime.now + 7.days,
          vote_options_attributes: [
            {title: "yes", content: "yes we should save the planet"},
            {title: "no", content: "no we should not save the planet"}
          ]
        }
      }
    end
    assert_response :success

    vote = VoteProposal.find_by(title: "save the planet")
    assert vote
  end

  test "api#vote/update" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    vote_proposal = VoteProposal.create!(
      title: "save the planet",
      content: "we should save the planet",
      creator_id: profile.id,
      group_id: 1,
      max_choice: 1,
      eligibile_group_id: 1,
      start_time: DateTime.now,
      end_time: DateTime.now + 7.days,
      vote_options_attributes: [
        {title: "yes", content: "yes we should save the planet"},
        {title: "no", content: "no we should not save the planet"}
      ]
    )

    post api_vote_update_url, params: {
      auth_token: auth_token,
      id: vote_proposal.id,
      group_id: 1,
      vote_proposal: {
        title: "save the oceans",
        content: "we should save the oceans",
        max_choice: 1,
        eligibile_group_id: 1,
        start_time: DateTime.now,
        end_time: DateTime.now + 7.days,

      }
    }
    assert_response :success

    # vote_proposal.reload
    # assert_equal "save the oceans", vote_proposal.title
    # assert_equal "we should save the oceans", vote_proposal.content
    # assert_equal "yes we should save the oceans", vote_proposal.vote_options.first.content
    # assert_equal "no we should not save the oceans", vote_proposal.vote_options.second.content
  end

  # test "api#vote/cast_vote" do
  #   profile = Profile.find_by(handle: "cookie")
  #   auth_token = profile.gen_auth_token
  #   vote_proposal = VoteProposal.create!(
  #     title: "save the planet",
  #     content: "we should save the planet",
  #     creator_id: profile.id,
  #     group_id: 1,
  #     max_choice: 1,
  #     eligibile_group_id: 1,
  #     start_time: DateTime.now,
  #     end_time: DateTime.now + 7.days,
  #     vote_options_attributes: [
  #       {title: "yes", content: "yes we should save the planet"},
  #       {title: "no", content: "no we should not save the planet"}
  #     ]
  #   )

  #   post api_vote_cast_vote_url, params: {
  #     auth_token: auth_token,
  #     vote_proposal_id: vote_proposal.id,
  #     vote_option_ids: [vote_proposal.vote_options.first.id]
  #   }
  #   assert_response :success

  #   vote = VoteRecord.find_by(voter: profile, vote_proposal: vote_proposal)
  #   assert vote
  #   assert_equal vote.vote_options.first.title, "yes"
  # end

  # test "api#vote/cancel" do
  #   profile = Profile.find_by(handle: "cookie")
  #   auth_token = profile.gen_auth_token
  #   vote_proposal = VoteProposal.create!(
  #     title: "save the forests",
  #     content: "we should save the forests",
  #     max_choice: 1,
  #     eligibile_group_id: 1,
  #     start_time: DateTime.now,
  #     end_time: DateTime.now + 7.days,
  #     vote_options_attributes: [
  #       {title: "yes", content: "yes we should save the forests"},
  #       {title: "no", content: "no we should not save the forests"}
  #     ]
  #   )
  #   vote = Vote.create!(profile: profile, vote_proposal: vote_proposal, vote_option_ids: [vote_proposal.vote_options.first.id])

  #   post api_vote_cancel_url, params: {
  #     auth_token: auth_token,
  #     vote_id: vote.id
  #   }
  #   assert_response :success

  #   assert_nil Vote.find_by(id: vote.id)
  # end
end
