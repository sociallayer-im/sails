class Badge < ApplicationRecord
  belongs_to :badge_class
  belongs_to :owner, class_name: "Profile", foreign_key: "owner_id"
  belongs_to :creator, class_name: "Profile", foreign_key: "creator_id"
  belongs_to :voucher
  has_one :participant
  has_many :comments
  has_many :activities, as: :item

  enum :status, { minted: 'minted', burned: 'burned' }
  enum :display, { normal: 'normal', hidden: 'hidden', pinned: 'pinned' }
  validates :end_time, comparison: { greater_than: :start_time }, allow_nil: true

  def gen_swap_code
    payload = {
      badge_id: badge.id,
      auth_type: "swap"
    }
    token = JWT.encode payload, $hmac_secret, "HS256"
  end

  def decode_swap_code
    decoded_token = JWT.decode swap_token, $hmac_secret, true, { algorithm: "HS256" }
    target_badge_id = decoded_token[0]["badge_id"]
  end
end
