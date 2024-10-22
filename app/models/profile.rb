require "jwt"
$hmac_secret = ENV["JWT_SECRET_KEY"]
raise "missing JWT_SECRET_KEY" unless $hmac_secret

class Profile < ApplicationRecord
  belongs_to :group, optional: true

  has_many :events, class_name: "Event", inverse_of: "owner", foreign_key: "owner_id"
  has_many :venues, class_name: "Venue", inverse_of: "owner", foreign_key: "owner_id"
  has_many :marker, class_name: "Marker", inverse_of: "owner", foreign_key: "owner_id"

  has_many :badge_classes, class_name: "BadgeClass", inverse_of: "creator", foreign_key: "creator_id"
  has_many :created_badges, class_name: "Badge", inverse_of: "creator", foreign_key: "creator_id"
  has_many :owned_badges, class_name: "Badge", inverse_of: "owner", foreign_key: "owner_id"

  has_many :point_classes, class_name: "PointClass", inverse_of: "creator", foreign_key: "creator_id"
  has_many :owned_point_balances, class_name: "PointBalance", inverse_of: "owner", foreign_key: "owner_id"
  has_many :created_point_balances, class_name: "PointBalance", inverse_of: "creator", foreign_key: "creator_id"
  has_many :received_point_transfers, class_name: "PointTransfer", inverse_of: "receiver", foreign_key: "receiver_id"
  has_many :sent_point_items, class_name: "PointTransfer", inverse_of: "sender", foreign_key: "sender_id"

  has_many :vouchers, class_name: "Voucher", inverse_of: "sender", foreign_key: "sender_id"
  has_many :received_vouchers, class_name: "Voucher", inverse_of: "receiver", foreign_key: "receiver_id"

  has_many :memberships
  has_many :groups, through: :memberships

  has_many :source_contacts, class_name: "Contact", inverse_of: "source", foreign_key: "source_id"
  has_many :target_contacts, class_name: "Contact", inverse_of: "target", foreign_key: "target_id"

  has_many :contact_sources, :through => :target_contacts, :source => "source", foreign_key: "target_id"
  has_many :contact_targets, :through => :source_contacts, :source => "target", foreign_key: "source_id"

  has_many :ticket_items
  enum :status, { active: 'active', freezed: 'freezed' }

  def admin?
    self.permissions.include?("admin")
  end

  def gen_auth_token
    payload = {
      id: self.id,
      address_type: "email",
      "https://hasura.io/jwt/claims": {
        "x-hasura-default-role": "user",
        "x-hasura-allowed-roles": ["user"],
        "x-hasura-user-id": self.id.to_s,
      }
    }
    auth_token = JWT.encode payload, $hmac_secret, "HS256"
  end

  def bind_ticket_items
    return if self.email.nil?
    TicketItem.where(selector_address: self.email, status: "unbounded").each do |ticket_item|
      ticket_item.update(status: "succeeded", profile_id: self.id)
      if ticket_item.ticket_type == 'group' && Membership.find_by(profile_id: ticket_item.profile_id, target_id: ticket_item.group_id).blank?
        Membership.create(profile: ticket_item.profile, target: ticket_item.group, role: "member", status: "active")
      end
    end
  end

  def send_mail_new_event(event)
    if self.email.present?
      mailer = EventMailer.with(event_id: event.id, recipient: self.email).event_created
      mailer.deliver_later
    end
  end

  def send_mail_event_invite(event)
    if self.email.present?
      mailer = EventMailer.with(event_id: event.id, recipient: self.email).event_invited
      mailer.deliver_later
    end
  end

  def send_mail_update_event(event)
    if self.email.present?
      mailer = EventMailer.with(event_id: event.id, recipient: self.email).event_updated
      mailer.deliver_later
    end
  end

  def send_mail_cancel_event(event)
    if self.email.present?
      mailer = EventMailer.with(event_id: event.id, recipient: self.email).event_updated
      mailer.deliver_later
    end
  end
end
