class Api::PointController < ApiController
  def create
    profile = current_profile!

    point_class = PointClass.find(params[:point_class_id])
    authorize point_class, :send?, policy_class: PointClassPolicy

    invalid_receivers = params[:receivers].reject do |receiver|
      Profile.exists?(address: receiver[:receiver]) || Profile.exists?(handle: receiver[:receiver])
    end

    if invalid_receivers.any?
      invalid_ids = invalid_receivers.map { |r| r[:receiver] }.join(', ')
      raise AppError.new("Invalid receiver id(s): #{invalid_ids}")
    end

    # need test for group

    point_transfers = params[:receivers].map do |receiver_value|
      target = receiver_value[:receiver]
      value = receiver_value[:value]
      receiver = Profile.find_by(address: target) || Profile.find_by(handle: target)
      point_transfer = PointTransfer.create(
        point_class_id: point_class.id,
        value: value,
        sender_id: profile.id,
        receiver_id: receiver.id
      )
      activity = Activity.create(item: point_transfer, initiator_id: profile.id, action: "point/send", receiver_type: "id", receiver_id: receiver.id, data: point_transfer.value.to_s)

      point_transfer
    end

    render json: { result: "ok", point_transfers: point_transfers.as_json }
  end

  def accept
    profile = current_profile!

    point_transfer = PointTransfer.find(params[:point_transfer_id])

    raise AppError.new("access denied") unless point_transfer.receiver_id == profile.id
    raise AppError.new("invalid state") unless point_transfer.status == "pending"

    point_class = point_transfer.point_class
    point_class.increment!(:total_supply, point_transfer.value)
    point = PointBalance.find_by(point_class_id: point_transfer.point_class_id, owner_id: profile.id)
    if point
      point.increment!(:value, point_transfer.value)
    else
      point = PointBalance.create(point_class_id: point_transfer.point_class_id, creator_id: point_class.creator_id, owner_id: point_transfer.receiver_id, value: point_transfer.value)
    end
    point_transfer.update(status: "accepted")
    activity = Activity.create(item: point_transfer, initiator_id: profile.id, action: "point/accept", data: point_transfer.value.to_s)
    render json: { result: "ok", point_transfer: point_transfer.as_json }
  end

  def transfer
    profile = current_profile!

    point_class = PointClass.find(params[:point_class_id])

    source_point = PointBalance.find_by(point_class_id: params[:point_class_id], owner_id: profile.id)
    raise AppError.new("invalid balance") if source_point.value < params[:value].to_i
    raise AppError.new("untransferable") unless source_point.point_class.transferable
    point = PointBalance.find_by(point_class_id: source_point.point_class_id, owner_id: params[:target_profile_id])
    if point
      source_point.decrement!(:value, params[:value].to_i)
      point.increment!(:value, params[:value].to_i)
    else
      source_point.decrement!(:value, params[:value].to_i)
      point = PointBalance.create(point_class_id: source_point.point_class_id, creator_id: source_point.creator_id, owner_id: params[:target_profile_id], value: params[:value])
    end
    point_transfer = PointTransfer.create(point_class_id: point.point_class_id, sender_id: source_point.owner_id, receiver_id: params[:target_profile_id], value: params[:value].to_i, status: "transfered")
    render json: { result: "ok", point_transfer: point_transfer.as_json }
  end

  def reject
    profile = current_profile!

    point_transfer = PointTransfer.find(params[:point_transfer_id])
    raise AppError.new("access denied") unless point_transfer.receiver_id == profile.id
    raise AppError.new("invalid state") unless point_transfer.status == "pending"

    point_transfer.update(status: "rejected")
    activity = Activity.create(item: point_transfer, initiator_id: profile.id, action: "point/reject")
    render json: { result: "ok", point_transfer: point_transfer.as_json }
  end
end
