class CreateGroups < ActiveRecord::Migration[7.1]
  def change
    create_table :groups do |t|
      t.string  "username"
      t.string  "chain_index"
      t.string  "chain_space"
      t.string  "image_url"
      t.string  "nickname"
      t.text    "about"
      t.string  "twitter"
      t.string  "github"
      t.string  "discord"
      t.string  "telegram"
      t.string  "ens"
      t.string  "lens"
      t.string  "nostr"
      t.string  "website"
      t.string  "location"
      t.integer "parent_id"
      t.string  "permissions", default: [], array: true
      t.string  "status", default: "active", null: false, comment: "active | freezed"
      t.string  "event_tags", array: true
      t.boolean "event_enabled", default: false
      t.string  "can_publish_event", default: "everyone", comment: "manager | member | everyone"
      t.string  "can_join_event", default: "everyone", comment: "manager | member | everyone"
      t.string  "can_view_event", default: "everyone", comment: "manager | member | everyone"
      t.boolean "map_enabled", default: false
      t.integer "map_union", array: true
      t.string  "banner_link_url"
      t.string  "banner_image_url"
      t.text    "banner_text"
      t.datetime "created_at", null: false
    end
  end
end
