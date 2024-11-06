class Api::RememberController < ApiController

  def meta
    render json: { 
      types: [
        {
          path: "remember",
          badge_class_id: 1829,
          count: 2,
          description: "Remember is a badge that allows you to remember a person or a thing.",
        }
      ]
     }
  end

  def create
    profile = current_profile!
    badge_class = BadgeClass.find_by(badge_type: "remember", id: params[:badge_class_id])
    expires_at = params[:expires_at] || DateTime.now + 90.days

    voucher = Voucher.new(
      sender: profile,
      badge_class: badge_class,
      message: params[:message],
      counter: 1,
      strategy: 'remember',
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
    activity = Activity.create(item_type: 'Voucher', item_id: voucher.id, initiator_id: profile.id, action: "voucher/join")

    render json: { voucher: voucher.as_json, badge_class: badge_class.as_json, profile: profile.as_json(only: [:id, :handle, :nickname, :image_url]) }
  end

  def join
    profile = current_profile!
    voucher = Voucher.find(params[:voucher_id])
    sender = voucher.sender
    badge_class = voucher.badge_class
    activity = Activity.find_or_create_by(item_type: 'Voucher', item_id: voucher.id, initiator_id: profile.id, action: "voucher/join")
    render json: { activity: activity.as_json(only: [:id, :action], include: [:initiator => { only: [:id, :handle, :nickname, :image_url] }]), voucher: voucher.as_json, badge_class: badge_class.as_json, sender: sender.as_json(only: [:id, :handle, :nickname, :image_url]) }
  end

  def cancel
    profile = current_profile!
    voucher = Voucher.find(params[:voucher_id])
    activity = Activity.find_by(item_id: voucher.id, initiator_id: profile.id, action: "voucher/join")
    activity.destroy
    render json: { result: "ok" }
  end

  def get
    voucher = Voucher.find(params[:voucher_id])
    badge_class = voucher.badge_class
    activities = Activity.where(item_type: 'Voucher', item_id: voucher.id, action: "voucher/join").order(created_at: :desc).all
    render json: { activities: activities.as_json(only: [:id, :action], include: [:initiator => { only: [:id, :handle, :nickname, :image_url] }]), voucher: voucher.as_json, badge_class: badge_class.as_json }
  end

  def mint
    profile = current_profile!

    voucher = Voucher.find(params[:voucher_id])
    badge_class = voucher.badge_class
    # authorize badge_class, :send?
    authorize voucher, :read?
    expires_at = voucher.expires_at
    return render json: { error: "voucher used" } if voucher.counter == 0

    activities = Activity.where(item_type: 'Voucher', item_id: voucher.id, action: "voucher/join").order(created_at: :desc).all
    return render json: { error: "members not enough" } if activities.count < 2

    badges = Badge.transaction do
      activities.map do |activity|
        badge = Badge.new(
          index: badge_class.counter,
          content: voucher.badge_content || voucher.message || badge_class.content,
          metadata: badge_class.metadata,
          status: "minted",
          badge_class_id: badge_class.id,
          creator_id: voucher.sender.id,
          owner_id: activity.initiator_id,
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

        new_activity = Activity.create(
          item: badge,
          item_class_id: badge.badge_class_id,
          initiator_id: profile.id,
          action: 'voucher/mint',
        )

        badge
      end
      voucher.update(counter: 0)
    end

    render json: { voucher: voucher.as_json, badge_class: badge_class.as_json, badges: badges.as_json }
  end
end
