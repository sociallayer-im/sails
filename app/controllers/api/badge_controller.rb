class Api::BadgeController < ApiController
  def meta
    badge = Badge.find(params[:id])

    render json: {
      "name": "Social Layer",
      "description": badge.badge.title,
      "external_url": "https://app.sola.day", # need update
      "image": badge.badge_class.image_url,
      "attributes": []
    }
  end

  def update
    badge = Badge.find(params[:id])
    badge.update(display: params[:display])
    render json: { result: "ok" }
  end

  def transfer
    profile = current_profile!

    badge = Badge.find(params[:badge_id])
    target = Profile.find_by(username: params[:target])
    authorize badge, :own?

    # need test
    raise AppError.new("invalid state") unless badge.status == "accepted"
    raise AppError.new("invalid badge_type") if badge.badge_class.transferable
    raise AppError.new("invalid target id") if target.nil? || profile.id == target.id

    badge.update(owner_id: params[:target_id])
    activity = Activity.create(item: badge, initiator_id: profile.id, action: "badge/transfer", target_id: target.id)
    render json: { result: "ok" }
  end

  def consume
    profile = current_profile!

    badge = Badge.find(params[:badge_id])
    badge_class = badge.badge_class

    authorize badge, :own?

    # need test
    raise AppError.new("invalid gift") unless badge_class.weighted
    raise AppError.new("invalid value") unless params[:delta].to_i > 0
    raise AppError.new("invalid badge value") unless badge.value >= params[:delta].to_i

    badge.decrement!(:value, params[:delta].to_i)
    badge.touch(:last_value_used_at)
    activity = Activity.create(item: badge, initiator_id: profile.id, action: "badge/consume")

    render json: { badge: badge }
  end

  def burn
    profile = current_profile!

    badge = Badge.find(params[:badge_id])
    authorize badge, :own?
    raise AppError.new("invalid state") unless badge.status == "accepted"

    badge.update(status: "burned")
    activity = Activity.create(item: badge, initiator_id: profile.id, action: "badge/burn")

    render json: { result: "ok" }
  end

  def swap_code
    profile = current_profile!

    badge = Badge.find(params[:badge_id])
    authorize badge, :own?

    payload = {
      badge_id: badge.id,
      auth_type: "swap"
    }
    token = JWT.encode payload, $hmac_secret, "HS256"
    activity = Activity.create(item: badge, initiator_id: profile.id, action: "badge/swap_code")

    render json: { result: "ok", token: token, badge_id: badge.id }
  end

  def swap
    profile = current_profile!
    badge = Badge.find(params[:badge_id])
    authorize badge, :own?
    swap_token = params[:swap_token]

    decoded_token = JWT.decode swap_token, $hmac_secret, true, { algorithm: "HS256" }
    target_badge_id = decoded_token[0]["badge_id"]
    target_badge = Badge.find(target_badge_id)
    target_badge_owner_id = target_badge.owner_id

    badge.update(owner_id: target_badge_owner_id)
    target_badge.update(owner_id: profile.id)
    activity = Activity.create(item: badge, initiator_id: profile.id, action: "badge/swap_code")

    render json: { result: "ok" }
  end

  def wamo_go_merge
    profile = current_profile!
    badges = Badge.where(id: params[:badge_ids])
    color = params[:color]
    required_badge_count = 2
    ids = badges.ids
    unless (ids.uniq.count == params[:badge_ids].count) && (ids.uniq.count == required_badge_count)
      raise AppError.new("invalid badge for merge")
    end
    badges.each do |badge|
      authorize badge, :own?
      unless badge.badge_class.permissions.include?("wamo-normal")
        raise AppError.new("invalid badge state for merge: require wamo-normal permission")
      end

      unless JSON.parse(badge.badge_class.metadata || "{}")["color"] == color
        raise AppError.new("invalid badge state for merge: color empty")
      end

      unless JSON.parse(badge.metadata || "{}")["merged"].blank?
        raise AppError.new("invalid badge state for merge: has merged")
      end
    end

    # todo : randomly select from colored merger badges
    badge_class = BadgeClass.find_by(id: params[:new_badge_id])
    raise AppError.new("invalid target badge for merge") unless badge_class.permissions.include?("wamo-merge")

    badge = Badge.new(
      index: badge_class.counter,
      content: badge_class.content,
      status: "accepted",
      badge_class_id: badge_class.id,
      creator_id: badge_class.creator.id,
      owner_id: profile.id,
      title: badge_class.title,
      image_url: badge_class.image_url,
    )

    badge.save
    badge_class.increment!(:counter)

    badges.each do |badge|
      badge.status = "burned"
      badge.metadata = JSON.dump({ merged: badge_class.id })
      badge.save
      activity = Activity.create(item: badge, initiator_id: profile.id, action: "badge/burn")
    end

    render json: { result: "ok", badge_id: badge.id }
  end
end
