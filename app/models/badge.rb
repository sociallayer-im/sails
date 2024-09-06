class Badge < ApplicationRecord
  belongs_to :badge_class
  belongs_to :owner, class_name: "Profile", foreign_key: "owner_id"
  belongs_to :creator, class_name: "Profile", foreign_key: "creator_id"
  has_one :participant
  has_many :comments
  has_many :activities, as: :item

  enum :status, { minted: 'minted', burned: 'burned' }
  enum :display, { normal: 'normal', hidden: 'hidden', pinned: 'pinned' }
  validates :end_time, comparison: { greater_than: :start_time }, allow_nil: true
end
