class Contact < ApplicationRecord
  belongs_to :source, class_name: "Profile", foreign_key: "source_id"
  belongs_to :target, class_name: "Profile", foreign_key: "target_id"

  validates :role, inclusion: { in: %w(contact follower) }
  enum :status, { active: 'active', freezed: 'freezed' }
end
