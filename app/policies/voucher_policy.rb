class VoucherPolicy < ApplicationPolicy
  attr_reader :profile, :voucher

  def initialize(profile, voucher)
    @profile = profile
    @voucher = voucher
  end

  def read?
    @voucher.sender_id == @profile.id
  end

  def update?
    @voucher.sender_id == @profile.id
  end
end
