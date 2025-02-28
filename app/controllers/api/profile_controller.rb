class Api::ProfileController < ApiController
  def current
    profile = current_profile!
    render json: profile
  end

  def nonce
    render json: { nonce: rand(100_000_000_000_000_000).to_s(16) }
  end

  def get_by_handle
    @profile = Profile.find_by(handle: params[:handle])
    render :show
  end

  def verify
    begin
      signature = params[:signature]
      message = Siwe::Message.from_message params[:message]
      message.verify(signature, message.domain, message.issued_at, message.nonce)
      address = message.address

      profile = Profile.find_or_create_by(address: address)

      SigninActivity.create(
        app: params[:app],
        address: address,
        address_type: "eth_wallet",
        address_source: params[:address_source],
        profile_id: profile.id,
        locale: params[:locale],
        lang: params[:lang],
        remote_ip: request.remote_ip,
        )
      if params[:app] == "seedao.sola.day" || params[:app] == "seedaobeta.sola.day"
        seedao_group_name = params[:app].sub(".sola.day", "")
        seedao_group = Group.find_by(handle: seedao_group_name)
        data = RestClient.get("https://sola.deno.dev/seedao/getname/#{address}")
        domain = JSON.parse(data.body)["domain"]
        if domain.present? && seedao_group
          seedao_group.add_member(profile.id, "member")
        end
      end
      render json: { result: "ok", auth_token: profile.gen_auth_token, address: address, id: profile.id }
    rescue Siwe::ExpiredMessage
      raise AppError.new("Siwe::ExpiredMessage")
    rescue Siwe::NotValidMessage
      raise AppError.new("Siwe::NotValidMessage")
    rescue Siwe::InvalidSignature
      raise AppError.new("Siwe::InvalidSignature")
    end
  end

  def signin_with_phone
    vcode = ProfileToken.find_by(context: "phone-signin",send_to: params[:phone], code: params[:code]).order('created_at DESC').first
    raise AppError.new("PhoneSignIn::InvalidEmailOrCode") unless vcode
    raise AppError.new("PhoneSignIn::Expired") unless DateTime.now < (vcode.created_at + 30.minute)
    raise AppError.new("PhoneSignIn::CodeIsUsed") if vcode.verified

    vcode.update(verified: true)

    profile = Profile.find_or_create_by(phone: params[:phone])

    SigninActivity.create(
      app: params[:app],
      address: params[:phone],
      address_type: "phone",
      address_source: params[:address_source],
      profile_id: profile.id,
      locale: params[:locale],
      lang: params[:lang],
      remote_ip: request.remote_ip,
      )
    render json: { result: "ok", auth_token: profile.gen_auth_token, phone: params[:phone], id: profile.id, address_type: "phone" }
  end

  def signin_with_email
    token = ProfileToken.where(context: "email-signin", sent_to: params[:email], code: params[:code]).order('created_at DESC').first
    raise AppError.new("EMailSignIn::InvalidEmailOrCode") unless token
    raise AppError.new("EMailSignIn::Expired") unless DateTime.now < (token.created_at + 30.minute)
    raise AppError.new("EMailSignIn::CodeIsUsed") if token.verified

    token.update(verified: true)

    profile = Profile.find_or_create_by(email: params[:email])
    profile.bind_ticket_items

    SigninActivity.create(
      app: params[:app],
      address: params[:email],
      address_type: "email",
      address_source: params[:address_source],
      profile_id: profile.id,
      locale: params[:locale],
      lang: params[:lang],
      remote_ip: request.remote_ip,
      )
    render json: { result: "ok", auth_token: profile.gen_auth_token, email: params[:email], id: profile.id, address_type: "email" }
  end

  def signin_with_google
    unless params[:next_token] == ENV['NEXT_TOKEN']
      raise AppError.new("invalid next token")
    end

    profile = Profile.find_or_create_by(email: params[:email])
    profile.bind_ticket_items

    SigninActivity.create(
      app: params[:app],
      address: params[:email],
      address_type: "email",
      address_source: "#{params[:address_source]}:google",
      profile_id: profile.id,
      locale: params[:locale],
      lang: params[:lang],
      remote_ip: request.remote_ip,
      )
    render json: { result: "ok", auth_token: profile.gen_auth_token, email: params[:email], id: profile.id, address_type: "email" }
  end

  def signin_with_zkemail
    unless params[:next_token] == ENV['NEXT_TOKEN']
      raise AppError.new("invalid next token")
    end

    profile = Profile.find_or_create_by(email: params[:email])
    profile.bind_ticket_items

    SigninActivity.create(
      app: params[:app],
      address: params[:email],
      address_type: "email",
      address_source: params[:address_source],
      profile_id: profile.id,
      locale: params[:locale],
      lang: params[:lang],
      remote_ip: request.remote_ip,
      )
    render json: { result: "ok", auth_token: profile.gen_auth_token, email: params[:email], id: profile.id, address_type: "email" }
  end

  def signin_with_mina
    unless params[:next_token] == ENV['NEXT_TOKEN']
      raise AppError.new("invalid next token")
    end

    profile = Profile.find_or_create_by(mina_address: params[:mina_address])
    profile.bind_ticket_items

    SigninActivity.create(
      app: params[:app],
      address: params[:mina_address],
      address_type: "mina",
      address_source: params[:address_source],
      profile_id: profile.id,
      locale: params[:locale],
      lang: params[:lang],
      remote_ip: request.remote_ip,
      )
    render json: { result: "ok", auth_token: profile.gen_auth_token, mina_address: params[:mina_address], id: profile.id, address_type: "mina" }
  end

  def signin_with_fuel
    unless params[:next_token] == ENV['NEXT_TOKEN']
      raise AppError.new("invalid next token")
    end

    profile = Profile.find_or_create_by(fuel_address: params[:fuel_address])
    profile.bind_ticket_items

    SigninActivity.create(
      app: params[:app],
      address: params[:fuel_address],
      address_type: "fuel",
      address_source: params[:address_source],
      profile_id: profile.id,
      locale: params[:locale],
      lang: params[:lang],
      remote_ip: request.remote_ip,
      )
    render json: { result: "ok", auth_token: profile.gen_auth_token, fuel_address: params[:fuel_address], id: profile.id, address_type: "fuel" }
  end

  def signin_with_telegram
    unless params[:next_token] == ENV['NEXT_TOKEN']
      raise AppError.new("invalid next token")
    end

    profile = Profile.find_or_create_by(telegram_id: params[:telegram_id])
    profile.bind_ticket_items

    SigninActivity.create(
      app: params[:app],
      address: params[:telegram_id],
      address_type: "telegram",
      address_source: params[:address_source],
      profile_id: profile.id,
      locale: params[:locale],
      lang: params[:lang],
      remote_ip: request.remote_ip,
      )
    render json: { result: "ok", auth_token: profile.gen_auth_token, telegram_id: params[:telegram_id], id: profile.id, address_type: "telegram" }
  end

  def signin_with_farcaster
    unless params[:next_token] == ENV['NEXT_TOKEN']
      raise AppError.new("invalid next token")
    end

    profile = Profile.find_or_create_by(farcaster_fid: params[:farcaster_fid])
    profile.update(farcaster_address: params[:farcaster_address])

    SigninActivity.create(
      app: params[:app],
      address: params[:farcaster_address],
      address_type: 'farcaster',
      address_source: params[:address_source],
      profile_id: profile.id,
      locale: params[:locale],
      lang: params[:lang],
      remote_ip: request.remote_ip,
      )
    render json: { result: "ok", auth_token: profile.gen_auth_token, email: params[:email], id: profile.id, address_type: "farcaster" }
  end

  def signin_with_world_id
    unless params[:next_token] == ENV['NEXT_TOKEN']
      raise AppError.new("invalid next token")
    end

    profile = Profile.find_or_create_by(address: params[:address], address_type: "worldid")
    payload = {
      id: profile.id,
      address_type: "worldid",
      "https://hasura.io/jwt/claims": {
        "x-hasura-default-role": "user",
        "x-hasura-allowed-roles": ["user"],
        "x-hasura-user-id": profile.id.to_s,
      }
    }
    auth_token = JWT.encode payload, $hmac_secret, "HS256"
    SigninActivity.create(
      app: params[:app],
      address: params[:address],
      address_type: 'worldid',
      address_source: params[:address_source],
      profile_id: profile.id,
      locale: params[:locale],
      lang: params[:lang],
      remote_ip: request.remote_ip,
      )
    render json: { result: "ok", auth_token: auth_token, email: params[:email], id: profile.id, address_type: "solana_wallet" }
  end

  def signin_with_multi_zupass
    unless params[:next_token] == ENV['NEXT_TOKEN']
      raise AppError.new("invalid next token")
    end

    zupass_list = params[:zupass_list]
    first_pass = zupass_list.first
    profile = Profile.find_or_create_by(email: params[:email])
    profile.update(
      zupass: "#{first_pass[:zupass_event_id]}:#{first_pass[:zupass_product_id]}",
      )
    profile.bind_ticket_items

    # todo : save zupass data of profile

    SigninActivity.create(
      app: params[:app],
      address: params[:email],
      address_type: 'zupass',
      address_source: params[:address_source],
      data: "zupass:#{first_pass[:zupass_event_id]}:#{first_pass[:zupass_product_id]}",
      profile_id: profile.id,
      locale: params[:locale],
      lang: params[:lang],
      remote_ip: request.remote_ip,
      )
    render json: { result: "ok", auth_token: profile.gen_auth_token, email: params[:email], id: profile.id, address_type: "zupass" }
  end

  def signin_with_zupass
    unless params[:next_token] == ENV["NEXT_TOKEN"]
      raise AppError.new("invalid next token")
    end

    profile = Profile.find_or_create_by(email: params[:email])
    profile.update(
      zupass: "#{params[:zupass_event_id]}:#{params[:zupass_product_id]}",
      )

    SigninActivity.create(
      app: params[:app],
      address: params[:email],
      address_type: "zupass",
      address_source: params[:address_source],
      data: "zupass:#{params[:zupass_event_id]}:#{params[:zupass_product_id]}",
      profile_id: profile.id,
      locale: params[:locale],
      lang: params[:lang],
      remote_ip: request.remote_ip,
      )
    render json: { result: "ok", auth_token: profile.gen_auth_token, email: params[:email], id: profile.id, address_type: "zupass" }
  end

  def signin_with_solana
    unless params[:next_token] == ENV["NEXT_TOKEN"]
      raise AppError.new("invalid next token")
    end

    profile = Profile.find_or_create_by(sol_address: params[:sol_address])

    SigninActivity.create(
      app: params[:app],
      address: params[:sol_address],
      address_type: "solana_wallet",
      address_source: params[:address_source],
      profile_id: profile.id,
      locale: params[:locale],
      lang: params[:lang],
      remote_ip: request.remote_ip,
      )
    render json: { result: "ok", auth_token: profile.gen_auth_token, email: params[:email], id: profile.id, address_type: "solana_wallet" }
  end

  def signin_with_farcaster
    unless params[:next_token] == ENV["NEXT_TOKEN"]
      raise AppError.new("invalid next token")
    end

    profile = Profile.find_or_create_by(far_fid: params[:far_fid])
    profile.update(far_address: params[:far_address])

    SigninActivity.create(
      app: params[:app],
      address: params[:email],
      address_type: "farcaster",
      address_source: params[:address_source],
      profile_id: profile.id,
      locale: params[:locale],
      lang: params[:lang],
      remote_ip: request.remote_ip,
      )
    render json: { result: "ok", auth_token: profile.gen_auth_token, email: params[:email], id: profile.id, address_type: "farcaster" }
  end

  def set_verified_email
    profile = current_profile!

    if Profile.find_by(email: params[:email])
      raise AppError.new("profile with the same email exists")
    end

    if profile.email
      raise AppError.new("profile email exists")
    end

    token = ProfileToken.find_by(sent_to: params[:email], code: params[:code])
    raise AppError.new("EMailSignIn::InvalidEmailOrCode") unless token
    raise AppError.new("EMailSignIn::Expired") unless DateTime.now < (token.created_at + 30.minute)
    raise AppError.new("EMailSignIn::CodeIsUsed") if token.verified

    token.update(verified: true)

    profile.update(email: params[:email])

    render json: { result: "ok", email: params[:email], id: profile.id }
  end

  def set_verified_address
    profile = current_profile!

    begin
      signature = params[:signature]
      message = Siwe::Message.from_message params[:message]
      message.verify(signature, message.domain, message.issued_at, message.nonce)

      address = message.address

      if Profile.find_by(address: address)
        raise AppError.new("profile with the same address already exists")
      end

      if profile.address
        raise AppError.new("profile address exists")
      end

      profile.update(address: address)

      render json: { result: "ok", email: profile.email, address: message.address, id: profile.id }
    rescue Siwe::ExpiredMessage
      raise AppError.new("Siwe::ExpiredMessage")
    rescue Siwe::NotValidMessage
      raise AppError.new("Siwe::NotValidMessage")
    rescue Siwe::InvalidSignature
      raise AppError.new("Siwe::InvalidSignature")
    end
  end

  def create
    handle = params[:handle]
    unless check_profile_handle_and_length(handle)
      raise AppError.new("invalid handle")
    end

    profile = current_profile
    unless profile
      raise AppError.new("profile not exists")
    end

    if profile.handle
      raise AppError.new("profile handle is already set")
    end

    if Profile.find_by(handle: handle) || Group.find_by(handle: handle) || Profile.find_by(username: handle) || Group.find_by(username: handle)
      raise AppError.new("profile handle exists")
    end
    ActiveRecord::Base.transaction do
      profile.update(handle: handle, username: handle)
      Domain.create(handle: handle, fullname: "#{handle}.sola.day", item_type: "Profile", item_id: profile.id)
    end
    render json: { result: "ok" }
  end

  def update
    profile = current_profile!
    profile.update(profile_params)
    render json: { result: "ok" }
  end

  def get_by_email
    profile = Profile.find_by(email: params[:email])
    render json: { profile: profile.as_json }
  end

  def follow
    profile = current_profile!
    target = Profile.find(params[:target_id])

    if profile.id == target.id
      raise AppError.new("can not follow yourself")
    end

    Contact.find_or_create_by(source_id: profile.id, target_id: target.id, role: "follower")
    render json: { result: "ok" }
  end

  def unfollow
    profile = current_profile!
    target = Profile.find(params[:target_id])

    results = Contact.where(source_id: profile.id, target_id: params[:target_id], role: "follower").delete_all
    render json: { result: "ok" }
  end

  def me
    profile = current_profile
    render json: { profile: profile.as_json }
  end

  def track_list
    profile = Profile.find(params[:id])
    track_ids = profile.ticket_items.where(ticket_type: "group", group_id: params[:group_id], status: "succeeded").map {|ticket_item| ticket_item.ticket.tracks_allowed }.flatten.compact.uniq
    render json: { track_ids: track_ids.as_json }
  end

  private


  def profile_params
    params.require(:profile).permit(:image_url, :nickname, :about, :location, {social_links: [:twitter, :github, :discord, :telegram, :ens, :lens, :nostr]})
  end
end
