json.group do
  json.extract! @group, :id, :username, :handle, :image_url, :nickname, :about, :parent_id, :permissions, :status,
   :event_tags, :event_enabled, :can_publish_event, :can_join_event, :can_view_event, :banner_link_url, :banner_image_url, :banner_text,
   :logo_url, :memberships_count, :timezone, :customizer, :created_at, :updated_at,
   :group_tags, :map_enabled, :venue_union, :group_union, :social_links,
   :start_date, :end_date, :location, :website, :featured_image_url, :ticket_link

  if @group.parent
    json.parent do
      json.extract! @group.parent, :id, :handle, :nickname, :image_url
    end
  else
    json.parent nil
  end

  json.children @group.children do |c|
    json.extract! c, :id, :handle, :nickname, :image_url, :about, :memberships_count
  end

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

    json.venues @group.venues.includes(:availabilities) do |v|
      json.extract! v, :id, :title, :location, :geo_lat, :geo_lng, :capacity, :require_approval, :visibility, :about, :link, :formatted_address,
                    :start_date, :end_date
      json.availabilities v.availabilities do |a|
        json.extract! a, :id, :day_of_week, :day, :intervals, :role
      end
    end

  end
end
