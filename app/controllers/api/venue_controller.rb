class Api::VenueController < ApiController
  def create
    profile = current_profile!
    group = Group.find(params[:group_id])

    venue = Venue.new(venue_params)
    venue.update(owner: profile, group: group, visibility: "all")
    render json: { venue: venue_json(venue) }
  end

  def update
    profile = current_profile!
    venue = Venue.find(params[:id])
    authorize venue.group, :manage_venue?

    venue.update(venue_params)
    render json: { venue: venue_json(venue) }
  end

  def get
    venue = Venue.find(params[:id])
    render json: { venue: venue_json(venue) }
  end

  def remove
    profile = current_profile!
    venue = Venue.find(params[:id])
    authorize venue.group, :manage_venue?

    venue.update(visibility: "none")
    render json: { venue: venue_json(venue) }
  end

  def check_availability
    venue = Venue.find(params[:id])

    available, message = venue.check_availability(params[:start_time], params[:end_time], params[:timezone])

    render json: { available: available, message: message }
  end

  def list
    profile = current_profile!
    group = Group.find_by(id: params[:group_id])
    venues = Venue.includes(:place, :availabilities, :venue_overrides, :venue_timeslots).where(group: group)
    render json: { venues: venues.map { |v| venue_json(v) } }
  end

  private

  def venue_json(venue)
    json = venue.as_json(include: [:availabilities, :venue_overrides, :venue_timeslots])
    place = venue.place
    if place
      json['location']          = place.name
      json['formatted_address'] = place.address
      json['geo_lat']           = place.geo_lat
      json['geo_lng']           = place.geo_lng
      json['location_viewport'] = place.location_viewport
      json['location_data']     = nil
      json['place']             = place.as_json(only: [:id, :name, :address, :geo_lat, :geo_lng, :location_viewport, :data, :created_at, :updated_at])
    else
      json['place'] = nil
    end
    json
  end

  def venue_params
    permitted = params.require(:venue).permit(
      :title, :about, :link, :capacity, :start_date, :end_date, :require_approval, :visibility, :featured_image_url, :place_id,
      amenities: [],
      tags: [],
      track_ids: [],
      image_urls: [],
      venue_overrides_attributes: [ :id, :venue_id, :day, :disabled, :start_at, :end_at, :role, :_destroy ],
      venue_timeslots_attributes: [ :id, :venue_id, :day_of_week, :disabled, :start_at, :end_at, :role, :_destroy ],
      availabilities_attributes: [ :id, :item_id, :item_type, :day_of_week, :day, :role, :_destroy ]
    )

    # intervals is a JSONB array-of-arrays — must be injected outside standard strong params
    raw_avails = params.dig(:venue, :availabilities_attributes)
    if raw_avails.present?
      raw_list = raw_avails.is_a?(ActionController::Parameters) ? raw_avails.values : Array(raw_avails)
      permitted_list = permitted[:availabilities_attributes] || []
      permitted_list.each_with_index do |avail, i|
        avail[:intervals] = Array(raw_list[i].try(:[], :intervals) || raw_list[i].try(:[], 'intervals'))
      end
    end

    permitted
  end
end
