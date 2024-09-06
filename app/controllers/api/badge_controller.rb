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
    raise AppError.new("invalid state") unless badge.status == "minted"
    raise AppError.new("invalid badge_type") if badge.badge_class.transferable
    raise AppError.new("invalid target id") if target.nil? || profile.id == target.id

    badge.update(owner_id: params[:target_id])
    activity = Activity.create(item: badge, initiator_id: profile.id, action: "badge/transfer", target_id: target.id)
    render json: { result: "ok" }
  end

  def burn
    profile = current_profile!

    badge = Badge.find(params[:badge_id])
    authorize badge, :own?
    raise AppError.new("invalid state") unless badge.status == "minted"

    badge.update(status: "burned")
    activity = Activity.create(item: badge, initiator_id: profile.id, action: "badge/burn")

    render json: { result: "ok" }
  end

  def swap_code
    profile = current_profile!

    badge = Badge.find(params[:badge_id])
    authorize badge, :own?

    # need test
    raise AppError.new("invalid state") unless badge.status == "minted"
    raise AppError.new("invalid badge_type") if badge.badge_class.transferable

    token = badge.gen_swap_code
    activity = Activity.create(item: badge, initiator_id: profile.id, action: "badge/swap_code")

    render json: { result: "ok", token: token, badge_id: badge.id }
  end

  def swap
    profile = current_profile!
    badge = Badge.find(params[:badge_id])
    authorize badge, :own?

    Badge.decode_swap_code(params[:swap_token])
    target_badge = Badge.find(target_badge_id)
    target_badge_owner_id = target_badge.owner_id

    raise AppError.new("invalid state") unless target_badge.status == "minted"
    raise AppError.new("invalid badge_type") if target_badge.badge_class.transferable

    badge.update(owner_id: target_badge_owner_id)
    target_badge.update(owner_id: profile.id)
    activity = Activity.create(item: badge, initiator_id: profile.id, action: "badge/swap_code")

    render json: { result: "ok" }
  end

  def merge
  end
end
