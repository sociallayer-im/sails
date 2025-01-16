json.group do
  json.extract! @group, :id, :username, :handle, :image_url, :nickname, :about, :parent_id, :permissions, :status,
   :event_tags, :event_enabled, :can_publish_event, :can_join_event, :can_view_event, :banner_link_url, :banner_image_url, :banner_text,
   :logo_url, :memberships_count, :timezone, :customizer, :created_at, :updated_at
end
