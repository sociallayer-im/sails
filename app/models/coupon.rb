class Coupon < ApplicationRecord
  validates :selector, inclusion: { in: %w(code email zupass badge) }
  validates :discount_type, inclusion: { in: %w(ratio amount) }
  belongs_to :event

  before_save do
    if code.blank?
      self.code = SecureRandom.hex(6)
    end
  end

  def get_discounted_price(amount)
    original_amount = amount
    if self.expires_at < DateTime.now || self.max_allowed_usages <= self.order_usage_count
      return [amount, nil, nil]
    end
    if self.discount_type == "ratio"
      return [amount, nil, nil] if self.discount_value > 10000 || self.discount_value < 0
      amount = amount * self.discount_value / 10000
    elsif self.discount_type == "amount"
      discount_value = paymethod.chain == "stripe" ? self.discount_value : self.discount_value * 10000
      discount_value = amount if discount_value > amount
      amount = amount - discount_value
    end
    discount_value = original_amount - amount
    discount_data = "id=#{id}|#{discount_type}|#{discount_value}"
    [amount, discount_value, discount_data]
  end
end
