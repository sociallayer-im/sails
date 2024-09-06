class PaymentMethod < ApplicationRecord
  belongs_to :item, polymorphic: true, optional: true

  validates :item_type, inclusion: { in: %w(Ticket Profile) }
  validates :chain, inclusion: { in: %w(ethereum op arb polygon base stripe) }
  enum :kind, { crypto: 'crypto', fiat: 'fiat', credit: 'credit' }
end
