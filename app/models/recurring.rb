class Recurring < ApplicationRecord
  has_many :events
  validates :end_time, comparison: { greater_than: :start_time }, allow_nil: true
end
