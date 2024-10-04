class AddAllForeignKeys < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key :activities, :profiles, column: :initiator_id

    add_foreign_key :badgelets, :badges, column: :badge_id
    add_foreign_key :badgelets, :profiles, column: :creator_id
    add_foreign_key :badgelets, :profiles, column: :owner_id
    add_foreign_key :badgelets, :vouchers, column: :voucher_id

    add_foreign_key :badges, :profiles, column: :creator_id
    add_foreign_key :badges, :groups, column: :group_id

    add_foreign_key :contacts, :profiles, column: :source_id
    add_foreign_key :contacts, :profiles, column: :target_id

    add_foreign_key :estores, :groups, column: :group_id
    add_foreign_key :estores, :profiles, column: :owner_id

    add_foreign_key :event_sites, :groups, column: :group_id
    add_foreign_key :event_sites, :profiles, column: :owner_id

    add_foreign_key :events, :profiles, column: :owner_id
    add_foreign_key :events, :badges, column: :badge_id
    add_foreign_key :events, :recurring_events, column: :recurring_event_id

    add_foreign_key :group_invites, :profiles, column: :sender_id
    add_foreign_key :group_invites, :profiles, column: :receiver_id
    add_foreign_key :group_invites, :badges, column: :badge_id
    add_foreign_key :group_invites, :badgelets, column: :badgelet_id

    add_foreign_key :groups, :groups, column: :parent_id

    add_foreign_key :map_checkins, :markers, column: :marker_id
    add_foreign_key :map_checkins, :profiles, column: :profile_id
    add_foreign_key :map_checkins, :badgelets, column: :badgelet_id

    add_foreign_key :markers, :profiles, column: :owner_id
    add_foreign_key :markers, :groups, column: :group_id
    add_foreign_key :markers, :badges, column: :badge_id
    add_foreign_key :markers, :vouchers, column: :voucher_id

    add_foreign_key :memberships, :profiles, column: :profile_id
    add_foreign_key :memberships, :groups, column: :target_id

    add_foreign_key :order_items, :orders, column: :order_id
    add_foreign_key :order_items, :products, column: :product_id
    add_foreign_key :order_items, :product_items, column: :product_item_id

    add_foreign_key :orders, :estores, column: :estore_id
    add_foreign_key :orders, :profiles, column: :profile_id
    # add_foreign_key :orders, :point_classes, column: :payment_point_class_id
    # add_foreign_key :orders, :badges, column: :payment_badge_id

    add_foreign_key :participants, :events, column: :event_id
    add_foreign_key :participants, :profiles, column: :profile_id
    add_foreign_key :participants, :badgelets, column: :badgelet_id

    add_foreign_key :point_classes, :profiles, column: :creator_id
    add_foreign_key :point_classes, :groups, column: :group_id

    add_foreign_key :points, :point_classes, column: :point_class_id
    add_foreign_key :points, :profiles, column: :creator_id
    add_foreign_key :points, :profiles, column: :owner_id

    add_foreign_key :point_items, :point_classes, column: :point_class_id
    add_foreign_key :point_items, :profiles, column: :sender_id
    add_foreign_key :point_items, :profiles, column: :owner_id

    add_foreign_key :products, :estores, column: :estore_id

    add_foreign_key :product_items, :products, column: :product_id

    add_foreign_key :vote_options, :groups, column: :group_id
    add_foreign_key :vote_options, :vote_proposals, column: :vote_proposal_id

    add_foreign_key :vote_proposals, :groups, column: :group_id
    add_foreign_key :vote_proposals, :profiles, column: :creator_id
    add_foreign_key :vote_proposals, :groups, column: :eligibile_group_id
    add_foreign_key :vote_proposals, :badges, column: :eligibile_badge_id
    add_foreign_key :vote_proposals, :points, column: :eligibile_point_id

    add_foreign_key :vote_records, :groups, column: :group_id
    add_foreign_key :vote_records, :profiles, column: :voter_id
    add_foreign_key :vote_records, :vote_proposals, column: :vote_proposal_id

    add_foreign_key :vouchers, :profiles, column: :sender_id
    add_foreign_key :vouchers, :badges, column: :badge_id
    add_foreign_key :vouchers, :profiles, column: :receiver_id
  end
end
