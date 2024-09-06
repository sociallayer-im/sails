class BadgeClass < ApplicationRecord
  belongs_to :creator, class_name: "Profile", foreign_key: "creator_id"
  belongs_to :group, optional: true

  has_many :badges, dependent: :destroy
  has_many :vouchers, dependent: :delete_all
  has_many :events
  has_many :markers
  has_many :activities, as: :item

  validates :name, presence: true
  validates :title, presence: true
  enum :status, { active: 'active', freezed: 'freezed' }
  enum :display, { normal: 'normal', hidden: 'hidden', pinned: 'pinned' }
end
