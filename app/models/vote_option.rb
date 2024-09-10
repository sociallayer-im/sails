class VoteOption < ApplicationRecord
  belongs_to :group, optional: true # remove group column
  belongs_to :vote_proposal

  before_save do
    self.group_id ||= self.vote_proposal.group_id
  end
end
