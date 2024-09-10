class VoteProposalPolicy < ApplicationPolicy
  attr_reader :profile, :proposal

  def initialize(profile, proposal)
    @profile = profile
    @proposal = proposal
  end

  def update?
    @proposal.creator_id == @profile.id
  end

  def cancel?
    @proposal.creator_id == @profile.id && @proposal.vote_records.count == 0
  end

end
