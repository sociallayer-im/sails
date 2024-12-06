class Api::VenueController < ApiController
  def create
    profile = current_profile!
    group = Group.find(params[:group_id])

    venue = Venue.new(venue_params)
    venue.update(
      owner: profile,
      group: group,
      visibility: "all"
    )
    render json: { venue: venue.as_json }
  end

  def update
    profile = current_profile!
    venue = Venue.find(params[:id])
    authorize venue.group, :manage_venue?

    venue.update(venue_params)

    render json: { venue: venue.as_json }
  end

  def remove
    profile = current_profile!
    venue = Venue.find(params[:id])
    authorize venue.group, :manage_venue?

    venue.update(visibility: "none")

    render json: { venue: venue.as_json }
  end

  def check_availability
    venue = Venue.find(params[:id])

    available, message = venue.check_availability(params[:start_time], params[:end_time], params[:timezone])

    render json: { available: available, message: message }
  end

  def list
    profile = current_profile!
    group = Group.find_by(id: params[:group_id])
    venues = Venue.where(group: group)
    render json: { venues: venues.as_json }
  end

  private

  def venue_params
    params.require(:venue).permit(
      :title, :location, :about, :link, :capacity, :formatted_address, :location_viewport, :location_data, :geo_lat, :geo_lng, :start_date, :end_date, :require_approval, :visibility, :tags,
      venue_overrides_attributes: [ :id, :venue_id, :day, :disabled, :start_at, :end_at, :role, :_destroy ],
      venue_timeslots_attributes: [ :id, :venue_id, :day_of_week, :disabled, :start_at, :end_at, :role, :_destroy ],
      availabilities_attributes: [ :id, :item_id, :item_type, :day_of_week, :day, :intervals, :role, :_destroy ]
    )
  end
end
