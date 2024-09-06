class CreateProfiles < ActiveRecord::Migration[7.2]
  def change
    create_table :profiles do |t|
      t.string :handle
      t.string :email
      t.string :phone
      t.string :address
      t.string :sol_address
      t.string :chain
      t.string :zupass
      t.string :status, default: "active"
      t.string :image_url
      t.string :nickname
      t.string :about
      t.string :farcaster_fid
      t.string :farcaster_address
      t.string :location
      t.jsonb :extra, default: {}
      t.jsonb :permissions, default: {}
      t.jsonb :social_links, default: {}
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["address"], name: "index_profiles_on_address", unique: true
      t.index ["email"], name: "index_profiles_on_email", unique: true
      t.index ["phone"], name: "index_profiles_on_phone", unique: true
      t.index ["handle"], name: "index_profiles_on_handle", unique: true
    end
  end
end
