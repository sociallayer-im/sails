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
  validates :can_publish_event, inclusion: { in: %w(all member operator manager) }
  validates :can_join_event, inclusion: { in: %w(all member operator manager) }
  validates :can_view_event, inclusion: { in: %w(all member operator manager) }

  accepts_nested_attributes_for :tracks, allow_destroy: true

  def get_owner
    Membership.find_by(group_id: id, role: 'owner').try(:profile)
  end

  def is_owner(profile_id)
    Membership.find_by(profile_id: profile_id, group_id: id, role: 'owner')
  end

  def is_manager(profile_id)
    Membership.find_by(profile_id: profile_id, group_id: id, role: %w[manager owner])
  end

  def is_operator(profile_id)
    Membership.find_by(profile_id: profile_id, group_id: id, role: %w[operator manager owner])
  end

  def is_member(profile_id)
    Membership.find_by(profile_id: profile_id, group_id: id, role: %w[member operator manager owner])
  end
end
