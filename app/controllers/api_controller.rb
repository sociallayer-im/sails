require "jwt"
$hmac_secret = ENV["JWT_SECRET_KEY"]

class AppError < StandardError
end

class AuthTokenError < StandardError
end

class ApiController < ApplicationController
  skip_forgery_protection
  include Pundit::Authorization

  def check_address(addr)
    (addr =~ /^0x[a-fA-F0-9]{40}$/) == 0
  end

  def check_address_or_email(addr)
    check_address(addr) || (addr =~ URI::MailTo::EMAIL_REGEXP) == 0
  end

  def check_badge_domain_label(label)
    (label =~ /^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*$/) == 0
  end

  def check_badge_domain_label_and_length(label)
    (label.length >= 4) && check_badge_domain_label(label)
  end

  def check_profile_username(handle)
    /^[a-z0-9]+([\-]{1}[a-z0-9]+)*$/.match(handle).to_s == handle
  end

  def check_profile_username_and_length(handle)
    handle.length >= 6 && check_profile_username(handle)
  end

  def sanitize_text(content)
    content = Sanitize.fragment(content, Sanitize::Config::RELAXED)
  end

  def current_profile
    return Profile.find_by(address: @address) if @address

    begin
      token = params[:auth_token]
      decoded_token = JWT.decode token, $hmac_secret, true, { algorithm: "HS256" }
      @profile_id = decoded_token[0]["id"]
      @profile = Profile.find_by(id: @profile_id)
    rescue Exception => e
      Rails.logger.info e.message
      nil
    end
  end

  def current_profile!
    return Profile.find_by(address: @address) if @address

    raise AuthTokenError.new("missing auth_token") unless params[:auth_token]

    begin
      token = params[:auth_token]
      decoded_token = JWT.decode token, $hmac_secret, true, { algorithm: "HS256" }
      @profile_id = decoded_token[0]["id"]
    rescue Exception => e
      Rails.logger.info e.message
      raise AuthTokenError.new(e.message)
    end

    @profile = Profile.find_by(id: @profile_id)
    raise AppError.new("profile is not found") unless @profile

    @profile
  end

  def pundit_user
    current_profile!
  end

  rescue_from Pundit::NotAuthorizedError do |err|
    Rails.logger.info err.message
    render json: { result: "error", message: err.message }, status: 403
  end

  rescue_from AuthTokenError do |err|
    Rails.logger.info err.message
    render json: { result: "error", message: "invalid auth_token: #{err.message}" }, status: 403
  end

  rescue_from AppError do |err|
    Rails.logger.info err.message
    render json: { result: "error", message: err.message }, status: 400
  end
end
