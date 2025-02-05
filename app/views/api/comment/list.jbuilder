json.comments @comments do |comment|
  json.extract! comment, :id, :title, :item_type, :item_id, :comment_type, :reply_parent_id, :edit_parent_id, :badge_id, :icon_url, :content, :content_type, :created_at, :updated_at
  json.partial! 'api/profile/profile', profile: comment.profile
end
