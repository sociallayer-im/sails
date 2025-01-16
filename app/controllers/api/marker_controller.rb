class Api::MarkerController < ApiController
  def create
    profile = current_profile!
    group = Group.find(params[:group_id])

    marker = Marker.new(marker_params)
    if marker.update(
      owner: profile,
      group: group,
      status: "active"
    )
      render json: { marker: marker.as_json }
    else
      render json: { result: "error", message: marker.errors.full_messages.join(", ") }
    end
  end

  def update
    profile = current_profile!
    marker = Marker.find(params[:id])
    authorize marker, :update?

    if marker.update(marker_params)
      render json: { marker: marker.as_json }
    else
      render json: { result: "error", message: marker.errors.full_messages.join(", ") }
    end
  end

  def remove
    profile = current_profile!
    marker = Marker.find(params[:id])
    authorize marker, :update?

    if marker.update(status: "removed")
      render json: { result: "ok" }
    else
      render json: { result: "error", message: marker.errors.full_messages.join(", ") }
    end
  end

  def checkin
    profile = current_profile!
    marker = Marker.find(params[:id])
    authorize marker, :update?

    comment = Comment.new(
      item: marker,
      comment_type: "checkin",
      profile: profile,
      title: params[:title],
      content: params[:content],
      content_type: params[:content_type],
      reply_parent_id: params[:reply_parent_id],
      icon_url: params[:icon_url],
      )

    if comment.save
      render json: { result: "ok", comment: comment.as_json }
    else
      render json: { result: "error", message: comment.errors.full_messages.join(", ") }
    end
  end

  def list
    profile = current_profile!
    group = Group.find(params[:group_id])
    markers = group.markers.where(status: "active")
    markers = markers.where(marker_type: params[:marker_type]) if params[:marker_type].present?
    markers = markers.where(category: params[:category]) if params[:category].present?
    @markers = markers
  end

  def get
    @marker = Marker.find(params[:id])
  end

  private

  def marker_params
    params.require(:marker).permit(:marker_type, :category, :pin_image_url, :cover_image_url,
              :title, :about, :link, :start_time, :end_time,
              :location, :formatted_address, :location_viewport, :location_data, :geo_lat, :geo_lng
            )
  end
end
