class TrackRole < ApplicationRecord
  belongs_to :track
  belongs_to :profile
  validates :role, inclusion: { in: %w(member manager) }
end
