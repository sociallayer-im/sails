class Track < ApplicationRecord
  belongs_to :group

  validates :kind, inclusion: { in: %w(public private) }
end
