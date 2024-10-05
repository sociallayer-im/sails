class Voucher < ApplicationRecord
  belongs_to :sender, class_name: "Profile", foreign_key: "sender_id"
  belongs_to :receiver, class_name: "Profile", foreign_key: "receiver_id", optional: true
  belongs_to :badge_class
  belongs_to :item, polymorphic: true, optional: true
  has_many :badges
  has_many :activities, as: :item

  validates :receiver_address_type, inclusion: { in: %w(id email address) }, allow_nil: true
  validates :strategy, inclusion: { in: %w(code account address email event) }
end
