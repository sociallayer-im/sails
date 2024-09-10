class Api::MarkerController < ApiController
  def create
    profile = current_profile!
    group = Group.find(params[:group_id])

    marker = Marker.new(marker_params)
    marker.update(
      owner: profile,
      group: group,
      status: "active"
    )
    render json: { marker: marker.as_json }
  end

  def update
    profile = current_profile!
    marker = Marker.find(params[:id])
    authorize marker, :update?

    marker.update(marker_params)
    render json: { marker: marker.as_json }
  end

  def remove
    profile = current_profile!
    marker = Marker.find(params[:id])
    authorize marker, :update?

    marker.update(
      status: "removed",
      )
    render json: { result: "ok" }
  end

  def checkin
    profile = current_profile!
    marker = Marker.find(params[:id])
    authorize marker, :update?

    comment = Comment.create(
      item: marker,
      comment_type: "checkin",
      profile: profile,
      title: params[:title],
      content: params[:content],
      content_type: params[:content_type],
      reply_parent_id: params[:reply_parent_id],
      icon_url: params[:icon_url],
      )

    render json: { result: "ok", comment: comment.as_json }
  end

  private

  def marker_params
    params.require(:marker).permit(:marker_type, :category, :pin_image_url, :cover_image_url,
              :title, :about, :link, :start_time, :end_time,
              :location, :formatted_address, :location_viewport, :geo_lat, :geo_lng
            )
  end
end
