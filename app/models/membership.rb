class Membership < ApplicationRecord
  belongs_to :profile
  belongs_to :group

  enum :status, { active: 'active', freezed: 'freezed' }
  enum :role, { member: 'member', operator: 'operator', manager: 'manager', owner: 'owner' }
end
