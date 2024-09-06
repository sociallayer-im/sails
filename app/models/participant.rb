class Participant < ApplicationRecord
  belongs_to :event
  belongs_to :profile
  belongs_to :badge, optional: true
  has_many :ticket_items

  validates :status, inclusion: { in: %w(attending waiting pending disapproved checked cancelled) }

  def email_notify!(content_type)
    if self.profile.email.present?
      if content_type == :cancel
        self.event.send_mail_cancel_event(self.profile.email)
      end
    end
  end
end
