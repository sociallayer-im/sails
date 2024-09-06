class VoteProposal < ApplicationRecord
  belongs_to :creator, class_name: "Profile", foreign_key: "creator_id"
  belongs_to :group

  has_many :vote_options
  has_many :vote_records

  validates :end_time, comparison: { greater_than: :start_time }
  validates :status, inclusion: { in: %w(draft published closed cancelled) }

  accepts_nested_attributes_for :vote_options, allow_destroy: true
end
