class Membership < ApplicationRecord
  belongs_to :profile
  belongs_to :target, class_name: "Group", foreign_key: "target_id"

  enum :status, { active: 'active', freezed: 'freezed', normal: 'normal' }
  enum :role, { member: 'member', operator: 'operator', manager: 'manager', owner: 'owner' }
end
