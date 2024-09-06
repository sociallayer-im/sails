class Api::PointController < ApiController
  def create
    profile = current_profile!

    params[:receivers].each do |receiver|
      raise AppError.new("invalid receiver id") unless Profile.find_by(address: receiver[:receiver]) || Profile.find_by(handle: receiver[:receiver])
    end

    point_class = PointClass.find(params[:point_class_id])
    authorize point_class, :send?
    # need test for group

    point_items = params[:receivers].map do |receiver_value|
      target = receiver_value[:receiver]
      value = receiver_value[:value]
      receiver = Profile.find_by(address: target) || Profile.find_by(handle: target)
      point_item = PointTransfer.create(
        point_class_id: point_class.id,
        value: value,
        sender_id: profile.id,
        receiver_id: receiver.id
      )
      activity = Activity.create(item: point_item, initiator_id: profile.id, action: "point/send", receiver_type: "id", receiver_id: receiver.id, data: point_item.value.to_s)

      point_item
    end

    render json: { result: "ok", point_items: point_items.as_json }
  end

  def accept
    profile = current_profile!

    point_item = PointItem.find(params[:point_item_id])

    raise AppError.new("access denied") unless point_item.owner_id == profile.id
    raise AppError.new("invalid state") unless point_item.status == "pending"

    point_class = point_item.point_class
    point_class.increment!(:total_supply, point_item.value)
    point = PointBalance.find_by(point_class_id: point_item.point_class_id, owner_id: profile.id)
    if point
      point.increment!(:value, point_item.value)
    else
      point = PointBalance.create(point_class_id: point_item.point_class_id, creator_id: point_class.creator_id, owner_id: point_item.owner_id, value: point_item.value)
    end
    point_item.update(status: "accepted")
    activity = Activity.create(item: point_item, initiator_id: profile.id, action: "point/accept", data: point_item.value.to_s)
    render json: { result: "ok", point_item: point_item.as_json }
  end

  def transfer
    profile = current_profile!

    source_point = PointBalance.find(params[:point_id])
    raise AppError.new("invalid balance") if source_point.value < params[:amount].to_i
    raise AppError.new("untransferable") unless source_point.point_class.transferable
    point = PointBalance.find_by(point_class_id: source_point.point_class_id, owner_id: params[:target_profile_id])
    if point
      source_point.decrement!(:value, params[:amount].to_i)
      point.increment!(:value, params[:amount].to_i)
    else
      source_point.decrement!(:value, params[:amount].to_i)
      point = PointBalance.create(point_class_id: source_point.point_class_id, creator_id: source_point.creator_id, owner_id: params[:target_profile_id], value: params[:amount])
    end
    point_item = PointItem.create(point_class_id: point.point_class_id, sender_id: source_point.owner_id, owner_id: params[:target_profile_id], value: params[:amount].to_i, status: "transfered")
    render json: { result: "ok", point_item: point_item.as_json }
  end

  def reject
    profile = current_profile!

    point_item = PointItem.find(params[:point_item_id])
    raise AppError.new("access denied") unless point_item.owner_id == profile.id
    raise AppError.new("invalid state") unless point_item.status == "pending"

    point_item.update(status: "rejected")
    activity = Activity.create(item: point_item, initiator_id: profile.id, action: "point/reject")
    render json: { result: "ok", point_item: point_item.as_json }
  end
end
