json.extract! event, :id, :title, :start_time, :end_time, :timezone, :meeting_url, :venue_id, :location, :owner_id, :group_id, :cover_url, :status, :require_approval, :tags, :event_type, :display, :track_id, :created_at, :updated_at
json.url event_url(event, format: :json)
