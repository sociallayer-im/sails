json.group do
  json.extract! @group, :id, :username, :handle, :image_url, :nickname, :about, :parent_id, :permissions, :status,
   :event_tags, :event_enabled, :can_publish_event, :can_join_event, :can_view_event, :banner_link_url, :banner_image_url, :banner_text,
   :logo_url, :memberships_count, :timezone, :customizer, :created_at, :updated_at,
   :group_tags, :map_enabled, :venue_union, :group_union, :social_links,
   :start_date, :end_date, :location, :website

  if @include_detail
    json.memberships @group.memberships.includes(:profile) do |m|
      json.extract! m, :id, :profile_id, :role
      if m.profile
        json.profile do
          json.extract! m.profile, :id, :handle, :nickname, :image_url
        end
      else
        json.profile nil
      end
    end

    json.tracks @group.tracks do |t|
      json.extract! t, :id, :title, :kind, :icon_url, :group_id
    end

    json.venues @group.venues do |v|
      json.extract! v, :id, :title, :location, :geo_lat, :geo_lng, :capacity, :require_approval, :visibility, :about, :link, :formatted_address
    end

  end
end
