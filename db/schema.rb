# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2024_08_21_170124) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "activities", force: :cascade do |t|
    t.integer "item_type"
    t.integer "item_class_id"
    t.integer "item_id"
    t.integer "initiator_id"
    t.integer "target_type"
    t.integer "target_id"
    t.string "context"
    t.string "action"
    t.string "data"
    t.string "memo"
    t.integer "receiver_id"
    t.string "receiver_type", default: "id"
    t.string "receiver_address"
    t.boolean "has_read", default: false
    t.datetime "created_at", null: false
  end

  create_table "badge_classes", force: :cascade do |t|
    t.string "domain"
    t.string "name"
    t.string "title"
    t.jsonb "metadata"
    t.text "content"
    t.string "image_url"
    t.integer "creator_id"
    t.integer "group_id"
    t.integer "counter", default: 1
    t.string "tags", array: true
    t.boolean "transferable", default: false, null: false
    t.boolean "revocable", default: false, null: false
    t.boolean "weighted", default: false, null: false
    t.boolean "encrypted", default: false, null: false
    t.string "permissions", default: [], array: true
    t.string "chain_index"
    t.string "chain_space"
    t.string "chain_txhash"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "active"
    t.string "display", default: "normal"
    t.index ["creator_id"], name: "index_badge_classes_on_creator_id"
  end

  create_table "badges", force: :cascade do |t|
    t.string "domain"
    t.integer "index"
    t.integer "badge_class_id"
    t.integer "creator_id"
    t.integer "owner_id"
    t.string "image_url"
    t.string "title"
    t.jsonb "metadata"
    t.text "content"
    t.string "status", default: "minted", null: false, comment: "minted | burned"
    t.string "display", default: "normal"
    t.string "tags", array: true
    t.integer "value", default: 0
    t.datetime "start_time"
    t.datetime "end_time"
    t.string "chain_index"
    t.string "chain_space"
    t.string "chain_txhash"
    t.integer "voucher_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comments", force: :cascade do |t|
    t.string "item_type"
    t.integer "item_id"
    t.string "comment_type"
    t.integer "profile_id"
    t.integer "badge_id"
    t.string "status", default: "normal"
    t.string "title"
    t.text "content"
    t.string "icon_url"
    t.string "content_type", default: "text/plain"
    t.integer "reply_parent_id"
    t.integer "edit_parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "communities", force: :cascade do |t|
    t.string "title"
    t.string "image_url"
    t.string "location"
    t.string "website"
    t.integer "group_id"
    t.date "start_date"
    t.date "end_date"
    t.string "kind", comment: "popup_city | community"
    t.string "group_tags", array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "contacts", force: :cascade do |t|
    t.integer "source_id"
    t.integer "target_id"
    t.string "label"
    t.string "role", default: "contact", null: false, comment: "contact | follow"
    t.string "status", default: "normal", null: false, comment: "normal | freezed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "event_roles", force: :cascade do |t|
    t.integer "event_id"
    t.integer "profile_id"
    t.string "email"
    t.string "nickname"
    t.string "image_url"
    t.string "role"
    t.string "about"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "events", force: :cascade do |t|
    t.string "title"
    t.datetime "start_time"
    t.datetime "end_time"
    t.string "timezone"
    t.string "meeting_url"
    t.integer "venue_id"
    t.string "location"
    t.string "formatted_address"
    t.text "location_viewport"
    t.decimal "geo_lat", precision: 10, scale: 6
    t.decimal "geo_lng", precision: 10, scale: 6
    t.integer "owner_id"
    t.integer "group_id"
    t.string "cover_url"
    t.string "status", default: "published", null: false
    t.boolean "require_approval"
    t.text "content"
    t.string "tags", array: true
    t.integer "max_participant"
    t.integer "min_participant"
    t.integer "participants_count", default: 0
    t.integer "badge_class_id"
    t.integer "recurring_id"
    t.string "event_type", comment: "event"
    t.string "display", default: "normal", comment: "normal | hidden | pinned"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_url"
    t.text "notes"
    t.jsonb "extra"
  end

  create_table "group_invites", force: :cascade do |t|
    t.integer "sender_id"
    t.integer "receiver_id"
    t.integer "group_id"
    t.string "message"
    t.datetime "expires_at"
    t.integer "badge_class_id"
    t.string "role", default: "member"
    t.string "status", default: "sending"
    t.string "receiver_address_type", default: "id"
    t.string "receiver_address"
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "groups", force: :cascade do |t|
    t.string "handle"
    t.string "chain"
    t.string "image_url"
    t.string "nickname"
    t.text "about"
    t.integer "parent_id"
    t.string "status", default: "active"
    t.string "tags", array: true
    t.string "event_taglist", array: true
    t.string "venue_taglist", array: true
    t.boolean "group_ticket_enabled"
    t.string "can_publish_event"
    t.string "can_join_event"
    t.string "can_view_event"
    t.string "customizer"
    t.string "logo_url"
    t.string "banner_link_url"
    t.string "banner_image_url"
    t.integer "memberships_count"
    t.integer "events_count", default: 0
    t.string "timezone"
    t.string "location"
    t.jsonb "metadata"
    t.jsonb "extra"
    t.jsonb "social_links", default: {}
    t.jsonb "permissions", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "markers", force: :cascade do |t|
    t.integer "owner_id"
    t.integer "group_id"
    t.string "marker_type", default: "site", null: false, comment: "site | event | share"
    t.string "category"
    t.string "pin_image_url"
    t.string "cover_image_url"
    t.string "title"
    t.text "about"
    t.string "link"
    t.string "status", default: "normal", null: false, comment: "normal | removed"
    t.string "location"
    t.string "formatted_address"
    t.text "location_viewport"
    t.decimal "geo_lat", precision: 10, scale: 6
    t.decimal "geo_lng", precision: 10, scale: 6
    t.datetime "start_time"
    t.datetime "end_time"
    t.jsonb "data"
    t.datetime "created_at", null: false
  end

  create_table "memberships", force: :cascade do |t|
    t.integer "profile_id"
    t.integer "group_id"
    t.string "role", default: "member", null: false, comment: "member | operator | guardian | manager | owner"
    t.string "status", default: "normal", null: false, comment: "normal | freezed"
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "participants", force: :cascade do |t|
    t.integer "event_id"
    t.integer "profile_id"
    t.text "message"
    t.string "status", default: "applied", null: false, comment: "applied | pending | disapproved | checked | cancel"
    t.datetime "check_time"
    t.string "payment_status"
    t.jsonb "payment_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "payment_methods", force: :cascade do |t|
    t.string "item_type"
    t.integer "item_id"
    t.string "chain"
    t.string "kind", default: "crypto", null: false, comment: "crypto | fiat | credit | free"
    t.string "token_name"
    t.string "token_address"
    t.string "receiver_address"
    t.decimal "price", precision: 40
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "point_balances", force: :cascade do |t|
    t.integer "point_class_id"
    t.integer "creator_id"
    t.integer "owner_id"
    t.integer "value", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "point_classes", force: :cascade do |t|
    t.string "name"
    t.string "title"
    t.string "sym", default: "pt", null: false
    t.jsonb "metadata"
    t.text "content"
    t.string "image_url"
    t.integer "creator_id"
    t.integer "group_id"
    t.boolean "transferable", default: false, null: false
    t.boolean "revocable", default: false, null: false
    t.string "point_type", default: "point", null: false, comment: "point | credit"
    t.integer "total_supply", default: 0
    t.integer "max_supply"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_point_classes_on_creator_id"
  end

  create_table "point_transfers", force: :cascade do |t|
    t.integer "point_class_id"
    t.integer "sender_id"
    t.integer "receiver_id"
    t.integer "value", default: 0
    t.string "status", default: "pending", null: false, comment: "pending | accepted | rejected | revoked"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "profile_tokens", force: :cascade do |t|
    t.string "context"
    t.string "sent_to"
    t.string "code"
    t.boolean "verified", default: false
    t.datetime "created_at", null: false
  end

  create_table "profiles", force: :cascade do |t|
    t.string "handle"
    t.string "email"
    t.string "phone"
    t.string "address"
    t.string "sol_address"
    t.string "chain"
    t.string "zupass"
    t.string "status", default: "active"
    t.string "image_url"
    t.string "nickname"
    t.string "about"
    t.string "farcaster_fid"
    t.string "farcaster_address"
    t.string "location"
    t.jsonb "extra", default: {}
    t.jsonb "permissions", default: {}
    t.jsonb "social_links", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address"], name: "index_profiles_on_address", unique: true
    t.index ["email"], name: "index_profiles_on_email", unique: true
    t.index ["handle"], name: "index_profiles_on_handle", unique: true
    t.index ["phone"], name: "index_profiles_on_phone", unique: true
  end

  create_table "promo_codes", force: :cascade do |t|
    t.string "selector", comment: "code | email | zupass | badge"
    t.string "label"
    t.string "code"
    t.string "receiver_address"
    t.string "discount_type", comment: "ratio | amount"
    t.integer "discount", comment: "0 to 100 for ratio, cent of dollar for amount"
    t.integer "event_id"
    t.integer "applicable_ticket_ids", array: true
    t.integer "ticket_item_ids", array: true
    t.datetime "expiry_time"
    t.integer "max_allowed_usages"
    t.integer "order_usage_count"
    t.boolean "removed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "recurrings", force: :cascade do |t|
    t.datetime "start_time"
    t.datetime "end_time"
    t.string "interval"
    t.string "timezone"
    t.integer "event_count"
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "signin_activities", force: :cascade do |t|
    t.string "app"
    t.string "address"
    t.string "address_type"
    t.string "address_source"
    t.integer "profile_id"
    t.text "data"
    t.datetime "created_at", null: false
    t.string "remote_ip"
    t.string "locale"
    t.string "lang"
  end

  create_table "ticket_items", force: :cascade do |t|
    t.integer "profile_id"
    t.integer "ticket_id"
    t.integer "event_id"
    t.string "chain"
    t.string "txhash"
    t.string "status"
    t.string "discount_value"
    t.string "discount_data"
    t.string "order_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ticket_type", default: "event", comment: "event | group"
    t.string "auth_type", comment: "free | payment | zupass | badge | invite"
    t.integer "group_id"
    t.integer "participant_id"
    t.integer "payment_method_id"
    t.decimal "amount", precision: 40
    t.decimal "original_price", precision: 40
    t.integer "token_address"
    t.integer "receiver_address"
  end

  create_table "tickets", force: :cascade do |t|
    t.string "title"
    t.string "content"
    t.string "ticket_type", default: "event", comment: "event | group"
    t.integer "group_id"
    t.integer "event_id"
    t.integer "check_badge_class_id"
    t.integer "quantity"
    t.datetime "end_time"
    t.boolean "need_approval"
    t.string "status", default: "normal"
    t.datetime "created_at", null: false
    t.string "zupass_event_id"
    t.string "zupass_product_id"
    t.string "zupass_product_name"
    t.date "start_date"
    t.date "end_date"
    t.date "days_allowed", array: true
    t.string "tracks_allowed", array: true
  end

  create_table "tracks", force: :cascade do |t|
    t.string "tag"
    t.string "title"
    t.string "kind", comment: "public | private"
    t.string "icon_url"
    t.string "about"
    t.integer "group_id"
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "venue_overrides", force: :cascade do |t|
    t.integer "venue_id"
    t.date "day"
    t.boolean "disabled"
    t.string "start_at"
    t.string "end_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "venue_timeslots", force: :cascade do |t|
    t.integer "venue_id"
    t.string "day_of_week"
    t.boolean "disabled"
    t.string "start_at"
    t.string "end_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "venues", force: :cascade do |t|
    t.string "title"
    t.string "location"
    t.text "about"
    t.integer "group_id"
    t.integer "owner_id"
    t.string "formatted_address"
    t.text "location_viewport"
    t.decimal "geo_lat", precision: 10, scale: 6
    t.decimal "geo_lng", precision: 10, scale: 6
    t.datetime "created_at", null: false
    t.date "start_date"
    t.date "end_date"
    t.string "link"
    t.integer "capacity"
    t.boolean "require_approval", default: false
    t.string "tags", array: true
    t.string "visibility", comment: "all | manager | none"
  end

  create_table "vote_options", force: :cascade do |t|
    t.integer "group_id"
    t.integer "vote_proposal_id"
    t.string "title"
    t.string "link"
    t.string "content"
    t.string "image_url"
    t.integer "voted_weight", default: 0
    t.datetime "created_at", null: false
  end

  create_table "vote_proposals", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.integer "group_id"
    t.integer "creator_id"
    t.string "eligibility", default: "has_group_membership", null: false, comment: "has_group_membership | everyone | is_verified | is_verified_in_group | has_badge | badge_count | max_badge_weight | total_badge_weight | points_count | above_points_threshold"
    t.integer "eligibile_group_id"
    t.integer "eligibile_badge_class_id"
    t.integer "eligibile_point_id"
    t.string "verification"
    t.string "status", default: "published", null: false, comment: "draft | published | closed | cancelled"
    t.boolean "show_voters"
    t.boolean "can_update_vote"
    t.integer "voter_count", default: 0
    t.integer "weight_count", default: 0
    t.integer "max_choice", default: 1
    t.datetime "start_time"
    t.datetime "end_time"
    t.datetime "created_at", null: false
  end

  create_table "vote_records", force: :cascade do |t|
    t.integer "group_id"
    t.integer "voter_id"
    t.integer "vote_proposal_id"
    t.integer "vote_options", array: true
    t.boolean "replaced", default: false
    t.datetime "created_at", null: false
  end

  create_table "vouchers", force: :cascade do |t|
    t.integer "sender_id"
    t.integer "badge_class_id"
    t.string "badge_title"
    t.string "badge_content"
    t.string "badge_image"
    t.string "badge_data", comment: "start_time, end_time, value, transferable, revocable"
    t.string "code"
    t.string "message"
    t.datetime "expires_at"
    t.integer "counter", default: 1
    t.integer "receiver_id"
    t.string "receiver_address"
    t.string "receiver_address_type", default: "id"
    t.datetime "claimed_at"
    t.boolean "claimed_by_server", default: false
    t.string "strategy", default: "code"
    t.integer "issued_amount"
    t.string "issued_token_ids", array: true
    t.string "minted_tx"
    t.string "minted_address"
    t.string "minted_ids", array: true
    t.datetime "created_at", null: false
    t.index ["sender_id"], name: "index_vouchers_on_sender_id"
  end
end
