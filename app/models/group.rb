class Group < ApplicationRecord
  has_many :events
  has_many :venues
  has_many :markers
  has_many :group_invites
  has_many :badge_classes
  has_many :point_classes
  has_many :vote_proposals
  has_many :vote_options
  has_many :vote_records
  has_many :memberships, dependent: :delete_all
  has_many :popup_cities, dependent: :delete_all
  has_many :tracks, dependent: :delete_all
  has_many :tickets
  has_many :ticket_items

  enum :status, { active: 'active', freezed: 'freezed' }
  validates :can_publish_event, inclusion: { in: %w(all member ticket operator manager) }
  validates :can_join_event, inclusion: { in: %w(all member ticket operator manager) }
  validates :can_view_event, inclusion: { in: %w(all member operator manager) }

  accepts_nested_attributes_for :tracks, allow_destroy: true

  def get_owner
    Membership.find_by(target_id: id, role: 'owner').try(:profile)
  end

  def is_owner(profile_id)
    Membership.find_by(profile_id: profile_id, target_id: id, role: 'owner', status: "active")
  end

  def is_manager(profile_id)
    Membership.find_by(profile_id: profile_id, target_id: id, role: %w[manager owner], status: "active")
  end

  def is_operator(profile_id)
    Membership.find_by(profile_id: profile_id, target_id: id, role: %w[operator manager owner], status: "active")
  end

  def is_member(profile_id)
    Membership.find_by(profile_id: profile_id, target_id: id, role: %w[member operator manager owner], status: "active")
  end

  def add_member(profile_id, role)
    membership = Membership.find_by(profile_id: profile_id, target_id: self.id)
    if membership
      membership.update(role: role)
    else
      membership = Membership.create(profile_id: profile_id, target_id: id, role: role, status: "active")
      self.increment!(:memberships_count)
    end
    membership
  end

  def display_name
    self.nickname || self.handle
  end
end
