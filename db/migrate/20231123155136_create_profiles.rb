class CreateProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :profiles do |t|
      t.string "username"
      t.string "address"
      t.string "email"
      t.string "phone"
      t.string "zupass"
      t.string "address_type", default: "wallet"
      t.string "chain_index"
      t.string "chain_space"
      t.string "status", default: "active", null: false, comment: "active | freezed"
      t.string "image_url"
      t.string "nickname"
      t.text   "about"
      t.string "twitter"
      t.string "github"
      t.string "discord"
      t.string "telegram"
      t.string "ens"
      t.string "lens"
      t.string "nostr"
      t.string "website"
      t.string "permissions", default: [], array: true
      t.string "location"
      t.integer "group_id"
      t.string "gcalendar_refresh_token"
      t.datetime "gcalendar_connected_at"
      t.datetime "last_signin_at"
      t.datetime "created_at", null: false
      t.index ["address"], name: "index_profiles_on_address", unique: true
      t.index ["email"], name: "index_profiles_on_email", unique: true
      t.index ["phone"], name: "index_profiles_on_phone", unique: true
      t.index ["username"], name: "index_profiles_on_username", unique: true
    end
  end
end
