class Api::VoucherController < ApiController

  def get_code
    voucher = Voucher.find(params[:id])
    authorize voucher, :read?
    render json: { voucher_id: voucher.id, code: voucher.code }
  end

  def revoke
    profile = current_profile!
    voucher = Voucher.includes(:badge_class).find(params[:id])
    authorize voucher, :update?

    voucher.update(counter: 0)

    render json: { voucher: voucher.as_json(include: :badge_class) }
  end

  def use
    profile = current_profile!
    voucher = Voucher.find(params[:id])
    badge_class = voucher.badge_class

    if params[:index].present? && Activity.find_by(initiator_id: profile.id, data: params[:index].to_s).present?
      return render json: { result: "error", message: "you have claimed the wamo code" }
    end
    raise AppError.new("invalid voucher") if voucher.counter == 0 || voucher.expires_at < DateTime.now()

    # todo : check time and count
    if voucher.strategy == 'code'
      unless voucher.code.to_s == params[:code].to_s
        render json: { result: "error", message: "voucher code is empty or incorrect" }
        return
      end
    elsif voucher.strategy == 'event'
      unless voucher.receiver_id == profile.id
        render json: { result: "error", message: "voucher is not for this user" }
        return
      end
    elsif voucher.strategy == 'account'
      unless voucher.receiver_id == profile.id
        render json: { result: "error", message: "voucher is not for this user" }
        return
      end
    elsif voucher.strategy == 'address'
      unless voucher.receiver_address == profile.address
        render json: { result: "error", message: "voucher is not for this user" }
        return
      end
    elsif voucher.strategy == 'email'
      unless voucher.receiver_address == profile.email
        render json: { result: "error", message: "voucher is not for this user" }
        return
      end
    end

    # todo : check by voucher instead!!!
    unless Badge.where(voucher_id: params[:id], owner_id: profile.id).blank?
      render json: { result: "error", message: "user has already claimed voucher" }
      return
    end

    badge = Badge.new(
      index: badge_class.counter,
      content: voucher.badge_content || voucher.message || badge_class.content,
      metadata: badge_class.metadata,
      status: "minted",
      badge_class_id: badge_class.id,
      creator_id: voucher.sender.id,
      owner_id: profile.id,
      voucher_id: voucher.id,
    )
    # need test
    badge.title = voucher.badge_title || badge_class.title
    badge.image_url = voucher.badge_image || badge_class.image_url
    # need test
    if voucher.data
      data = JSON.parse(voucher.data)
      badge.value = data["value"] if data["value"]
      badge.start_time = data["start_time"] if data["start_time"]
      badge.end_time = data["end_time"] if data["end_time"]
    end

    badge.save
    badge_class.increment!(:counter)
    voucher.decrement!(:counter)

    if voucher.strategy == 'event'
      Participant.find_by(voucher_id: voucher.id).update(badge_id: badge.id)
    end
    activity = Activity.create(
      item: badge,
      item_class_id: badge.badge_class_id,
      initiator_id: profile.id,
      action: 'voucher/use',
      data: params[:index].to_s,
      )

    if badge_class.permissions.include?("group_member_pass")
      group = badge_class.group
      membership = Membership.find_by(profile_id: profile.id, target_id: group.id)
      if !membership
        membership = Membership.create(profile_id: profile.id, target_id: group.id, role: 'member')
      end
    end

    render json: { badge: badge.as_json }
  end

  def create
    profile = current_profile!
    badge_class = BadgeClass.find(params[:badge_class_id])
    authorize badge_class, :send?
    expires_at = params[:expires_at] || DateTime.now + 90.days

    voucher = Voucher.new(
      sender: profile,
      badge_class: badge_class,
      # need test
      badge_title: params[:badge_title],
      badge_content: (params[:badge_content].present? && sanitize_text(params[:badge_content]) || nil),
      badge_image: params[:badge_image],
      message: params[:message],
      counter: params[:counter],
      strategy: 'code',
      code: rand(1_000_000..10_000_000),
      expires_at: expires_at,
    )

    # need test
    if !badge_class.weighted && params[:value].present?
      raise AppError.new("invalid value for unweighted badge")
    end
    # need test
    if params[:value] || params[:start_time] || params[:end_time]
      voucher.data = {
        value: params[:value],
        start_time: params[:start_time],
        end_time: params[:end_time],
      }
    end
    voucher.save
    activity = Activity.create(item_type: 'BadgeClass', item_class_id: badge_class.id, initiator_id: profile.id, action: "voucher/create")

    render json: { voucher: voucher.as_json }
  end

  def send_badge
    profile = current_profile!

    badge_class = BadgeClass.find(params[:badge_class_id])
    authorize badge_class, :send?

    # TODO: add check again with email input
    receivers = params[:receivers].map do |handle|
      Profile.find_by(handle: handle) || Profile.find_by(address: handle)
    end
    raise AppError.new("invalid receiver") if receivers.any?{ |e| e.nil? }
    expires_at = params[:expires_at] || DateTime.now + 90.days

    vouchers = receivers.map do |receiver|
      voucher = Voucher.new(
        sender: profile,
        badge_class: badge_class,
        # need test
        badge_title: params[:badge_title],
        badge_content: (params[:badge_content].present? && sanitize_text(params[:badge_content]) || nil),
        badge_image: params[:badge_image],
        # need test
        message: params[:message],
        strategy: 'account',
        counter: 1,
        receiver_address_type: 'id',
        receiver_id: receiver.id,
        # need test
        expires_at: expires_at,
      )
      if !badge_class.weighted && params[:value].present?
        raise AppError.new("invalid value for unweighted badge_class")
      end
      # need test
      if params[:value] || params[:start_time] || params[:end_time]
        voucher.data = {
          value: params[:value],
          start_time: params[:start_time],
          end_time: params[:end_time],
        }
      end
      voucher.save
      activity = Activity.create(item: badge_class, initiator_id: profile.id, receiver_type: 'id', receiver_id: receiver.id, action: "voucher/send_badge", data: "voucher:#{voucher.id}")
      voucher
    end

    render json: { vouchers: vouchers.as_json }
  end

  def send_badge_by_address
    profile = current_profile!

    badge_class = BadgeClass.find(params[:badge_class_id])
    authorize badge_class, :send?

    # TODO: add check again with email input
    receivers = params[:receivers]
    receivers.map do |address|
      raise AppError.new("invalid receiver") unless check_address(address)
    end
    expires_at = params[:expires_at] || DateTime.now + 90.days

    vouchers = receivers.map do |receiver|
      voucher = Voucher.new(
        sender: profile,
        badge_class: badge_class,
        # need test
        badge_title: params[:badge_title],
        badge_content: (params[:badge_content].present? && sanitize_text(params[:badge_content]) || nil),
        badge_image: params[:badge_image],
        # need test
        message: params[:message],
        strategy: 'address',
        counter: 1,
        receiver_address_type: 'address',
        receiver_address: receiver,
        # need test
        expires_at: expires_at,
      )
      if !badge_class.weighted && params[:value].present?
        raise AppError.new("invalid value for unweighted badge_class")
      end
      # need test
      if params[:value] || params[:start_time] || params[:end_time]
        voucher.data = {
          value: params[:value],
          start_time: params[:start_time],
          end_time: params[:end_time],
        }
      end
      voucher.save
      activity = Activity.create(item: badge_class, initiator_id: profile.id, receiver_type: 'address', receiver_id: receiver, action: "voucher/send_badge_by_address")

      voucher
    end

    render json: { vouchers: vouchers.as_json }
  end

  def send_badge_by_email
    profile = current_profile!

    badge_class = BadgeClass.find(params[:badge_class_id])
    authorize badge_class, :send?

    # TODO: add check again with email input
    receivers = params[:receivers]
    receivers.map do |address|
      raise AppError.new("invalid receiver") unless check_address_or_email(address)
    end
    expires_at = params[:expires_at] || DateTime.now + 90.days

    vouchers = receivers.map do |receiver|
      voucher = Voucher.new(
        sender: profile,
        badge_class: badge_class,
        # need test
        badge_title: params[:badge_title],
        badge_content: (params[:badge_content].present? && sanitize_text(params[:badge_content]) || nil),
        badge_image: params[:badge_image],
        # need test
        message: params[:message],
        strategy: 'email',
        counter: 1,
        receiver_address_type: 'email',
        receiver_address: receiver,
        # need test
        expires_at: expires_at,
      )
      if !badge_class.weighted && params[:value].present?
        raise AppError.new("invalid value for unweighted badge_class")
      end
      # need test
      if params[:value] || params[:start_time] || params[:end_time]
        voucher.data = {
          value: params[:value],
          start_time: params[:start_time],
          end_time: params[:end_time],
        }
      end
      voucher.save
      activity = Activity.create(item: badge_class, initiator_id: profile.id, receiver_type: 'address', receiver_id: receiver, action: "voucher/send_badge_by_address")

      voucher
    end

    render json: { vouchers: vouchers.as_json }
  end

  def reject_badge
    profile = current_profile!

    voucher = Voucher.includes(:badge_class).find(params[:id])
    unless voucher.strategy == 'account' && voucher.receiver_id == profile.id
        render json: { result: "error", message: "voucher is not for this user" }
        return
    end
    voucher.update(counter: 0)
    render json: { voucher: voucher.as_json(include: :badge_class) }
  end
end
