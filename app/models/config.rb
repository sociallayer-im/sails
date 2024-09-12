class Config < ApplicationRecord
  belongs_to :item, polymorphic: true, optional: true
  belongs_to :group, optional: true

  validates :name, inclusion: { in: %w(event_webhook_url stripe_public_key stripe_secret_key) }
end
