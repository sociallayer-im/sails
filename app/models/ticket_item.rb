class TicketItem < ApplicationRecord
  belongs_to :profile
  belongs_to :participant
  belongs_to :ticket
  belongs_to :event
  belongs_to :payment_method, optional: true
  belongs_to :group, optional: true

  validates :status, inclusion: { in: %w(pending succeeded cancelled) }
  validates :ticket_type, inclusion: { in: %w(event group) }
  enum :auth_type, { free: 'free', payment: 'payment', zupass: 'zupass', badge: 'badge', invite: 'invite' }
end
