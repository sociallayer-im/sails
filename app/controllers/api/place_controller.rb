class Api::PlaceController < ApiController
  def search
    query = params[:query].to_s.strip
    @places = Place.where("name ILIKE ? OR address ILIKE ?", "%#{query}%", "%#{query}%").limit(20)
  end

  def get
    @place = Place.find(params[:id])
  end

  def create
    name = params[:name].to_s.strip
    return render json: { result: "error", message: "name is required" } if name.blank?

    @place = Place.create!(
      name:              name,
      address:           params[:address],
      geo_lat:           params[:geo_lat],
      geo_lng:           params[:geo_lng],
      location_viewport: params[:location_viewport],
      data:              params[:data],
    )
    render :get
  end
end
