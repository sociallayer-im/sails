class VoteRecord < ApplicationRecord
  belongs_to :group
  belongs_to :vote_proposal
  belongs_to :voter, class_name: "Profile", foreign_key: "voter_id"
end
