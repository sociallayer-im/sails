class Api::VoteController < ApiController
  def create
    profile = current_profile!
    group = Group.find(params[:group_id])

    authorize group, :create_vote?, policy_class: GroupPolicy

    proposal = VoteProposal.new(vote_proposal_params)
    proposal.update(
      creator: profile,
      group: group,
    )

    render json: { proposal: proposal.as_json }
  end

  def cancel
    profile = current_profile!

    proposal = VoteProposal.find(params[:id])
    authorize proposal, :cancel?
    proposal.update(status: "cancel")

    render json: { result: "ok" }
  end

  def update
    profile = current_profile!

    proposal = VoteProposal.find(params[:id])
    authorize proposal, :update?

    proposal.update(vote_proposal_params)

    render json: { proposal: proposal.as_json }
  end

  def cast_vote
    profile = current_profile!

    proposal = VoteProposal.find(params[:id])

    # todo : separate permission check code

    options = []
    params[:option].each do |option_id|
      option = VoteOption.find_by(vote_proposal_id: params[:id], id: option_id)
      options << option
      raise AppError.new("invalid option") unless option
    end

    raise AppError.new("exceed vote_proposal max_choice") if options.count > (proposal.max_choice || 1)

    raise AppError.new("user has voted") if VoteRecord.find_by(vote_proposal_id: proposal.id, voter_id: profile.id)
    raise AppError.new("vote has been cancelled") if proposal.status == "cancel"

    if proposal.start_time
      raise AppError.new("voting time not started") if DateTime.now < proposal.start_time
    end

    if proposal.end_time
      raise AppError.new("voting time is ended") if DateTime.now > proposal.end_time
    end

    # TODO: multi choice

    weight = 1

    # TODO: check user eligibility!!!
    if proposal.eligibility == "has_group_membership" && !proposal.group.is_member(profile.id)
      raise AppError.new("voter not eligibile")
    end
    if proposal.eligibility == "has_badge" && !Badge.find_by(badge_class_id: proposal.eligibile_badge_class_id, owner_id: profile.id).present?
      raise AppError.new("voter not eligibile")
    end

    if proposal.eligibility == "badge_count"
      weight = Badge.where(badge_class_id: proposal.eligibile_badge_class_id, owner_id: profile.id).count
      raise AppError.new("voter not eligibile") unless Badge.find_by(badge_class_id: proposal.eligibile_badge_class_id, owner_id: profile.id).present?
    end

    record = VoteRecord.create(
      group_id: proposal.group_id,
      vote_proposal_id: proposal.id,
      voter_id: profile.id,
      vote_options: (options.map { |op| op.id }),
    )

    proposal.increment!(:voter_count, 1)
    proposal.increment!(:weight_count, weight)
    options.map { |op| op.increment!(:voted_weight, weight) }

    render json: { result: "ok", voter_records: record.as_json }
  end

  private

  def vote_proposal_params
    params.require(:vote_proposal).permit(:title, :content, :show_voters, :max_choice,
          :eligibile_group_id, :eligibile_badge_class_id, :eligibile_point_id,
          :verification, :eligibility, :can_update_vote, :start_time, :end_time,
          vote_options_attributes: [ :id, :title, :link, :_destroy ]
        )
  end
end
