class Track < ApplicationRecord
  belongs_to :group
  has_many :track_roles, dependent: :delete_all
  has_many :events, dependent: :nullify

  accepts_nested_attributes_for :track_roles, allow_destroy: true
  validates :kind, inclusion: { in: %w(public private) }
end
