class Venue < ApplicationRecord
  belongs_to :owner, class_name: "Profile", foreign_key: "owner_id", optional: true
  belongs_to :group
  has_many :events
  has_many :venue_timeslots
  has_many :venue_overrides

  validates :end_date, comparison: { greater_than: :start_date }, allow_nil: true

  accepts_nested_attributes_for :venue_timeslots, allow_destroy: true
  accepts_nested_attributes_for :venue_overrides, allow_destroy: true

  validates :visibility, inclusion: { in: %w(all manager none) }
end
