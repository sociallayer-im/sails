class CreateGroups < ActiveRecord::Migration[7.2]
  def change
    create_table :groups do |t|
      t.string :handle
      t.string :chain
      t.string :image_url
      t.string :nickname
      t.text :about
      t.integer :parent_id
      t.string :status, default: "active"
      t.string :tags, array: true
      t.string :event_taglist, array: true
      t.string :venue_taglist, array: true
      t.boolean :group_ticket_enabled
      t.string :can_publish_event
      t.string :can_join_event
      t.string :can_view_event
      t.string :customizer
      t.string :logo_url
      t.string :banner_link_url
      t.string :banner_image_url
      t.integer :memberships_count
      t.integer :events_count, default: 0
      t.string :timezone
      t.string :location
      t.jsonb :metadata
      t.jsonb :extra
      t.jsonb :social_links, default: {}
      t.jsonb :permissions, default: {}
      t.timestamps
    end
  end
end
