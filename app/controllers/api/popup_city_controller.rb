class Api::PopupCityController < ApiController
  def list
    groups = Group.where.not(start_date: nil).order(start_date: :desc)
    groups = groups.where.not("group_tags @> ARRAY[?]::varchar[]", [":hidden"]) unless params[:include_hidden].present?
    render json: {
      popup_cities: groups.map { |g| group_as_popup_city(g) }
    }
  end

  def get
    group = Group.find(params[:id])
    render json: { popup_city: group_as_popup_city(group) }
  end

  private

  def group_as_popup_city(g)
    {
      id: g.id,
      title: g.nickname,
      start_date: g.start_date,
      end_date: g.end_date,
      image_url: g.image_url,
      banner_image_url: g.banner_image_url,
      location: g.location,
      website: g.website,
      group_tags: g.group_tags,
      group_id: g.id,
      group: { id: g.id, handle: g.handle, nickname: g.nickname, image_url: g.image_url }
    }
  end
end
