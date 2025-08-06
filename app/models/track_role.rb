class TrackRole < ApplicationRecord
  belongs_to :track
  belongs_to :group
  belongs_to :profile
  validates :role, inclusion: { in: %w(member manager) }

  before_validation :set_group_id

  def set_group_id
    self.group_id = self.track.group_id if self.track.present?
  end
end
