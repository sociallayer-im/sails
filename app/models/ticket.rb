class Ticket < ApplicationRecord
  belongs_to :event
  has_many :participants, dependent: :delete_all
  has_many :ticket_items, dependent: :delete_all
  has_many :payment_methods, as: :item, dependent: :delete_all

  accepts_nested_attributes_for :payment_methods, allow_destroy: true
end
