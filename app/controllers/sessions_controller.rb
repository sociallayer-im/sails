class SessionsController < ApplicationController
  # skip_before_action :authenticate, only: %i[ new create ]

  before_action :set_session, only: :destroy

  def index
    @profiles = Profile.order(created_at: :desc)
  end

  def new
  end

  def verify
    code = rand(10_000..100_000)
    token = ProfileToken.create(context: params[:context], sent_to: params[:email], code: code)

    p token
    mailer = SigninMailer.with(code: code, recipient: params[:email]).signin_email
    mailer.deliver_now!
    @email = params[:email]
  end

  def show
    @profile = Profile.find(params[:id])
  end

  def create
    token = ProfileToken.find_by(context: "email-verify", sent_to: params[:email], code: params[:code])
    return render json: { result: "error", message: "EMailSignIn::InvalidEmailOrCode" } unless token
    return render json: { result: "error", message: "EMailSignIn::Expired" } unless DateTime.now < (token.created_at + 30.minute)
    return render json: { result: "error", message: "EMailSignIn::CodeIsUsed" } if token.verified

    # token.update(verified: true)

    profile = Profile.find_or_create_by(email: params[:email])
    cookies.signed[:profile_id] = profile.id

    SigninActivity.create(
      app: "web",
      address: params[:email],
      address_type: "email",
      address_source: "email-verifier",
      profile_id: profile.id,
      locale: params[:locale],
      lang: params[:lang],
      remote_ip: request.remote_ip,
      )
    # render json: { result: "ok", auth_token: profile.gen_auth_token, email: params[:email], id: profile.id, address_type: "email" }
    redirect_to root_path, notice: "Signed in successfully"
  end

  # def create
  #   if user = User.authenticate_by(email: params[:email], password: params[:password])
  #     @session = user.profiles.create!
  #     cookies.signed.permanent[:session_token] = { value: @session.id, httponly: true }

  #     redirect_to root_path, notice: "Signed in successfully"
  #   else
  #     redirect_to sign_in_path(email_hint: params[:email]), alert: "That email or password is incorrect"
  #   end
  # end

  def destroy
    @session.destroy; redirect_to(sessions_path, notice: "That session has been logged out")
  end

  private
    def set_session
      @session = Current.user.profiles.find(params[:id])
    end
end
