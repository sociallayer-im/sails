class GroupInvite < ApplicationRecord
  belongs_to :sender, class_name: "Profile", foreign_key: "sender_id", optional: true
  belongs_to :receiver, class_name: "Profile", foreign_key: "receiver_id", optional: true
  belongs_to :group
  belongs_to :badge_class, optional: true
  belongs_to :badge, optional: true
  has_many   :activities, as: :item

  validates :role, inclusion: { in: %w(member operator manager owner) }
  enum :status, { sending: 'sending', requesting: 'requesting', accepted: 'accepted', cancelled: 'cancelled', revoked: 'revoked' }
end
