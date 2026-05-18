class Api::PopupCityController < ApiController
  def list
    popup_cities = PopupCity.includes(:group).order(start_date: :desc)
    popup_cities = popup_cities.where.not("group_tags @> ARRAY[?]::varchar[]", [":hidden"]) unless params[:include_hidden].present?
    render json: {
      popup_cities: popup_cities.map { |pc|
        pc.as_json(only: [:id, :title, :start_date, :end_date, :image_url, :location, :website, :group_tags]).merge(
          group: pc.group ? pc.group.as_json(only: [:id, :handle, :nickname, :image_url]) : nil
        )
      }
    }
  end

  def get
    popup_city = PopupCity.includes(:group).find(params[:id])
    render json: {
      popup_city: popup_city.as_json(only: [:id, :title, :start_date, :end_date, :image_url, :location, :website, :group_tags, :group_id]).merge(
        group: popup_city.group ? popup_city.group.as_json(only: [:id, :handle, :nickname, :image_url]) : nil
      )
    }
  end
end
