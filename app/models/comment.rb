class Comment < ApplicationRecord
  belongs_to :marker
  belongs_to :profile
  belongs_to :badge, optional: true

  belongs_to :item, polymorphic: true, optional: true
  belongs_to :reply_parent, class_name: "Comment", foreign_key: "reply_parent_id"
  belongs_to :edit_parent, class_name: "Comment", foreign_key: "edit_parent_id"

  validates :comment_type, inclusion: { in: %w(checkin chat event) }
  enum :status, { normal: 'normal', edited: 'edited', removed: 'removed' }
end
