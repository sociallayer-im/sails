class Participant < ApplicationRecord
  belongs_to :event
  belongs_to :profile
  belongs_to :badge, optional: true
  has_many :ticket_items

  validates :status, inclusion: { in: %w(attending waiting pending disapproved rejected checked cancelled) }
  validates :payment_status, inclusion: { in: %w(pending succeeded cancelled) }, allow_nil: true

  def profile_name
    self.profile.handle
  end

  def profile_image_url
    self.profile.image_url
  end

  def email_notify!(content_type)
    if self.profile.email.present?
      if content_type == :cancel
        self.event.send_mail_cancel_event(self.profile.email)
      end
    end
  end
end
