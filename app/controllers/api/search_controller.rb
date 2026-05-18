class Api::SearchController < ApiController
  def index
    keyword = params[:keyword].to_s.strip
    return render json: { events: [], groups: [], profiles: [], badge_classes: [] } if keyword.blank?

    limit = 100

    events = Event.includes(:owner, :event_roles)
                  .where(status: %w[open published closed])
                  .where("display != 'private'")
                  .where("title ~* ?", keyword)
                  .order(id: :desc)
                  .limit(limit)

    groups = Group.where("handle ~* ? OR nickname ~* ?", keyword, keyword)
                  .order(id: :desc)
                  .limit(limit)

    profiles = Profile.where("handle ~* ? OR nickname ~* ?", keyword, keyword)
                      .order(id: :desc)
                      .limit(limit)

    badge_classes = BadgeClass.where("badge_type != 'private'")
                              .where("name ~* ? OR title ~* ?", keyword, keyword)
                              .order(id: :desc)
                              .limit(limit)

    render json: {
      events: events.map { |e|
        {
          id: e.id, title: e.title, event_type: e.event_type, track_id: e.track_id,
          start_time: e.start_time, end_time: e.end_time, timezone: e.timezone,
          status: e.status, display: e.display, meeting_url: e.meeting_url,
          location: e.location, formatted_address: e.formatted_address,
          geo_lat: e.geo_lat, geo_lng: e.geo_lng, cover_url: e.cover_url,
          tags: e.tags, external_url: e.external_url, recurring_id: e.recurring_id,
          owner: e.owner ? { id: e.owner.id, handle: e.owner.handle, nickname: e.owner.nickname, image_url: e.owner.image_url } : nil,
          event_roles: e.event_roles.map { |r| { id: r.id, role: r.role, item_id: r.item_id, item_type: r.item_type, nickname: r.nickname, image_url: r.image_url } }
        }
      },
      groups: groups.map { |g|
        { id: g.id, handle: g.handle, username: g.username, nickname: g.nickname, image_url: g.image_url,
          about: g.about, status: g.status, memberships_count: g.memberships_count }
      },
      profiles: profiles.map { |p|
        { id: p.id, handle: p.handle, username: p.username, nickname: p.nickname, image_url: p.image_url }
      },
      badge_classes: badge_classes.map { |b|
        { id: b.id, title: b.title, name: b.name, image_url: b.image_url, badge_type: b.badge_type,
          transferable: b.transferable, content: b.content, metadata: b.metadata }
      }
    }
  end
end
