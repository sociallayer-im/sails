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

  private

  def venue_params
    params.require(:venue).permit(
      :title, :location, :about, :link, :capacity, :formatted_address, :location_viewport, :geo_lat, :geo_lng, :start_date, :end_date, :require_approval, :visibility, :tags,
      venue_overrides: [ :id, :venue_id, :day, :disabled, :start_at, :end_at, :_destroy ],
      venue_timeslots: [ :id, :venue_id, :day_of_week, :disabled, :start_at, :end_at, :_destroy ],
      availabilities: [ :id, :item_id, :item_type, :day_of_week, :day, :intervals, :_destroy ]
    )
  end
end
