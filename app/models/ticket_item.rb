class TicketItem < ApplicationRecord
  belongs_to :profile, optional: true
  belongs_to :ticket
  belongs_to :event, optional: true
  belongs_to :participant, optional: true
  belongs_to :payment_method, optional: true
  belongs_to :group, optional: true
  belongs_to :coupon, optional: true

  validates :status, inclusion: { in: %w(pending unbounded succeeded cancelled timeout) }
  validates :ticket_type, inclusion: { in: %w(event group) }
  enum :auth_type, { free: 'free', payment: 'payment', zupass: 'zupass', badge: 'badge', invite: 'invite' }

  def check_permission(event)
    return false unless ticket_type == "group"

    tz = event.group.timezone
    event_period = (event.start_time.in_time_zone(tz).to_date..event.end_time.in_time_zone(tz).to_date)

    if ticket.start_date.present?
      return false unless (ticket.start_date..ticket.end_date).overlaps?(event_period)
    elsif ticket.days_allowed.present?
      return false unless ticket.days_allowed.any? { |day| event_period.include?(day) }
    end

    # todo : use track_id
    if ticket.tracks_allowed.present?
      return false unless ticket.tracks_allowed.intersect?(event.tags)
    end

    return true
  end

  def cancel
    if self.participant.payment_status == "pending"
      self.participant.update(payment_status: "cancelled", status: "cancelled")
    end
    self.update(status: "cancelled", participant_id: nil)
    if self.coupon_id
      self.coupon.increment!(:order_usage_count)
    end
  end

  def timeout
    if self.participant.payment_status == "pending"
      self.participant.update(payment_status: "cancelled", status: "cancelled")
    end
    self.update(status: "timeout", participant_id: nil)
    if self.coupon_id
      self.coupon.increment!(:order_usage_count)
    end
  end
end
