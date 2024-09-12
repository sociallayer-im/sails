class TrackRole < ApplicationRecord
  belongs_to :track
  belongs_to :profile
  validates :role, inclusion: { in: %w(member manager) }

  before_save :set_group_id

  def set_group_id
    self.group_id = self.track.group_id
  end
end
