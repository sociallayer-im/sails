class PaymentMethod < ApplicationRecord
  SUPPORTED_CHAINS = %w[ethereum optimism arbitrum polygon base stripe].freeze

  belongs_to :item, polymorphic: true, optional: true

  validates :item_type, inclusion: { in: %w(Ticket Profile) }
  validates :chain, inclusion: { in: SUPPORTED_CHAINS }, allow_blank: true
  validate :chains_must_be_supported

  enum :kind, { crypto: 'crypto', fiat: 'fiat', credit: 'credit' }

  # Returns the token contract address for a given chain.
  # Falls back to token_address for single-chain records.
  def token_address_for_chain(chain_name)
    chain_token_addresses&.dig(chain_name.to_s) || token_address
  end

  # All chains this payment method accepts (multi-chain or legacy single).
  def effective_chains
    chains.present? ? chains : [chain].compact
  end

  private

  def chains_must_be_supported
    invalid = Array(chains) - SUPPORTED_CHAINS
    errors.add(:chains, "contains unsupported chains: #{invalid.join(', ')}") if invalid.any?
  end
end
