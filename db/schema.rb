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

ActiveRecord::Schema[7.2].define(version: 2025_08_06_093937) do
  create_schema "hdb_catalog"

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "activities", force: :cascade do |t|
    t.integer "item_class_id"
    t.integer "item_id"
    t.integer "initiator_id"
    t.integer "target_id"
    t.string "action"
    t.string "data"
    t.string "memo"
    t.datetime "created_at", null: false
    t.integer "receiver_id"
    t.string "receiver_type", default: "id"
    t.string "receiver_address"
    t.boolean "has_read", default: false
    t.string "item_type"
    t.string "target_type"
    t.index ["created_at"], name: "index_activities_on_created_at"
    t.index ["initiator_id"], name: "index_activities_on_initiator_id"
    t.index ["item_type", "item_id"], name: "index_activities_on_item_type_and_item_id"
  end

  create_table "availabilities", force: :cascade do |t|
    t.integer "item_id"
    t.string "item_type"
    t.string "day_of_week"
    t.date "day"
    t.jsonb "intervals"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role"
  end

  create_table "badge_classes", force: :cascade do |t|
    t.string "name"
    t.string "title"
    t.text "metadata"
    t.text "content"
    t.string "image_url"
    t.integer "creator_id"
    t.integer "group_id"
    t.integer "counter", default: 1
    t.string "hashtags", array: true
    t.boolean "transferable", default: false, null: false
    t.boolean "revocable", default: false, null: false
    t.boolean "weighted", default: false, null: false
    t.boolean "encrypted", default: false, null: false
    t.string "badge_type", default: "badge", null: false, comment: "badge | nft | nftpass | private"
    t.string "permissions", default: [], array: true
    t.string "chain_index"
    t.string "chain_space"
    t.string "chain_txhash"
    t.datetime "created_at", null: false
    t.string "display", default: "normal", comment: "normal | hide | top"
    t.string "domain"
    t.datetime "updated_at"
    t.string "status", default: "active"
    t.string "can_send_badge", default: "owner"
    t.index ["creator_id"], name: "index_badge_classes_on_creator_id"
  end

  create_table "badges", force: :cascade do |t|
    t.integer "index"
    t.integer "badge_class_id"
    t.integer "creator_id"
    t.integer "owner_id"
    t.string "image_url"
    t.string "title"
    t.text "metadata"
    t.text "content"
    t.string "status", default: "new", null: false, comment: "new | burnt"
    t.string "display", default: "normal", null: false, comment: "normal | hide | top"
    t.string "hashtags", array: true
    t.integer "value", default: 0
    t.datetime "last_value_used_at"
    t.datetime "start_time"
    t.datetime "end_time"
    t.string "chain_index"
    t.string "chain_space"
    t.string "chain_txhash"
    t.integer "voucher_id"
    t.datetime "created_at"
    t.string "domain"
    t.datetime "updated_at"
  end

  create_table "comments", force: :cascade do |t|
    t.integer "title"
    t.string "item_type", default: "Group"
    t.integer "item_id"
    t.integer "reply_parent_id"
    t.text "content"
    t.string "content_type", default: "text"
    t.integer "profile_id"
    t.boolean "removed"
    t.datetime "created_at"
    t.string "status", default: "active"
    t.string "comment_type"
    t.string "icon_url"
    t.integer "edit_parent_id"
    t.integer "badge_id"
    t.datetime "updated_at"
    t.index ["item_type", "item_id", "status"], name: "index_comments_on_item_type_and_item_id_and_status"
    t.index ["profile_id", "comment_type"], name: "index_comments_on_profile_id_and_comment_type"
  end

  create_table "configs", force: :cascade do |t|
    t.integer "group_id"
    t.integer "item_id"
    t.string "item_type"
    t.string "name"
    t.string "value"
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "contacts", force: :cascade do |t|
    t.integer "source_id"
    t.integer "target_id"
    t.string "role", default: "contact", null: false, comment: "contact"
    t.string "status", default: "normal", null: false, comment: "normal | freezed"
    t.datetime "created_at", null: false
  end

  create_table "coupons", force: :cascade do |t|
    t.string "selector_type", comment: "code | email | zupass | badge"
    t.string "label"
    t.string "code"
    t.string "receiver_address"
    t.string "discount_type", comment: "ratio | amount"
    t.integer "discount", comment: "0 to 100 for ratio, cent of dollar for amount"
    t.integer "event_id"
    t.integer "applicable_ticket_ids", array: true
    t.integer "ticket_item_ids", array: true
    t.datetime "expires_at"
    t.integer "max_allowed_usages"
    t.integer "order_usage_count"
    t.boolean "removed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "custom_forms", force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.string "status"
    t.string "item_type"
    t.integer "item_id"
    t.integer "group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "domains", force: :cascade do |t|
    t.string "handle"
    t.string "fullname"
    t.string "item_type"
    t.integer "item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["handle"], name: "index_domains_on_handle", unique: true
  end

  create_table "estores", force: :cascade do |t|
    t.string "title"
    t.integer "group_id"
    t.integer "owner_id"
    t.string "status", default: "normal", null: false, comment: "draft | normal | closed"
    t.string "image_url"
    t.string "background_url"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "event_roles", force: :cascade do |t|
    t.integer "event_id"
    t.integer "item_id"
    t.string "email"
    t.string "nickname"
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role"
    t.string "item_type"
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
    t.string "status", default: "open", null: false, comment: "draft | open | closed | cancel"
    t.boolean "require_approval"
    t.text "host_info"
    t.text "content"
    t.string "category"
    t.string "tags", array: true
    t.integer "max_participant"
    t.integer "min_participant"
    t.integer "participants_count", default: 0
    t.integer "badge_class_id"
    t.integer "recurring_id"
    t.string "event_type", comment: "event"
    t.string "display", default: "normal", comment: "normal | hide | top"
    t.datetime "created_at", null: false
    t.string "external_url"
    t.text "notes"
    t.string "padge_link"
    t.integer "operators", array: true
    t.jsonb "schedule_details"
    t.string "requirement_tags", array: true
    t.string "extra", array: true
    t.integer "track_id"
    t.datetime "updated_at"
    t.jsonb "extras", default: {}
    t.string "location_data"
    t.boolean "pinned", default: false
    t.string "theme"
    t.string "op_status"
    t.string "op_priority"
    t.string "op_labels", default: [], array: true
    t.integer "assigned_operators", default: [], array: true
    t.index ["group_id", "status", "start_time"], name: "index_events_on_group_id_and_status_and_start_time"
    t.index ["group_id"], name: "index_events_on_group_id"
    t.index ["owner_id"], name: "index_events_on_owner_id"
    t.index ["recurring_id"], name: "index_events_on_recurring_id"
    t.index ["track_id", "status"], name: "index_events_on_track_id_and_status"
    t.index ["venue_id"], name: "index_events_on_venue_id"
  end

  create_table "followings", force: :cascade do |t|
    t.integer "profile_id"
    t.integer "target_id"
    t.datetime "created_at"
    t.string "role"
  end

  create_table "form_fields", force: :cascade do |t|
    t.string "label"
    t.string "description"
    t.string "field_type"
    t.jsonb "field_options"
    t.string "required"
    t.string "custom_form_id"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.jsonb "serialized_properties"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_discard"
    t.text "callback_queue_name"
    t.integer "callback_priority"
    t.datetime "enqueued_at"
    t.datetime "discarded_at"
    t.datetime "finished_at"
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id", null: false
    t.text "job_class"
    t.text "queue_name"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.text "error"
    t.integer "error_event", limit: 2
    t.text "error_backtrace", array: true
    t.uuid "process_id"
    t.interval "duration"
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
    t.index ["process_id", "created_at"], name: "index_good_job_executions_on_process_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
    t.integer "lock_type", limit: 2
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "key"
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "performed_at"
    t.datetime "finished_at"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at"
    t.uuid "batch_id"
    t.uuid "batch_callback_id"
    t.boolean "is_discrete"
    t.integer "executions_count"
    t.text "job_class"
    t.integer "error_event", limit: 2
    t.text "labels", array: true
    t.uuid "locked_by_id"
    t.datetime "locked_at"
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at_cond", where: "(cron_key IS NOT NULL)"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at_cond", unique: true, where: "(cron_key IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["labels"], name: "index_good_jobs_on_labels", where: "(labels IS NOT NULL)", using: :gin
    t.index ["locked_by_id"], name: "index_good_jobs_on_locked_by_id", where: "(locked_by_id IS NOT NULL)"
    t.index ["priority", "created_at"], name: "index_good_job_jobs_for_candidate_lookup", where: "(finished_at IS NULL)"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at"], name: "index_good_jobs_on_priority_scheduled_at_unfinished_unlocked", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "group_invites", force: :cascade do |t|
    t.integer "sender_id"
    t.integer "receiver_id"
    t.integer "group_id"
    t.string "message"
    t.datetime "expires_at"
    t.integer "badge_class_id"
    t.integer "badge_id"
    t.string "role", default: "member"
    t.string "status", default: "sending", null: false, comment: "sending | accepted | cancel | revoked"
    t.boolean "accepted", default: false
    t.datetime "created_at", null: false
    t.string "receiver_address_type", default: "id"
    t.string "receiver_address"
  end

  create_table "group_pass_types", force: :cascade do |t|
    t.string "title"
    t.integer "group_id"
    t.string "zupass_event_id"
    t.string "zupass_product_id"
    t.string "zupass_product_name"
    t.date "start_date"
    t.date "end_date"
    t.date "days_allowed", array: true
    t.string "tracks_allowed", array: true
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "group_passes", force: :cascade do |t|
    t.integer "group_id"
    t.integer "profile_id"
    t.string "auth_type"
    t.string "zupass_event_id"
    t.string "zupass_product_id"
    t.string "zupass_product_name"
    t.date "start_date"
    t.date "end_date"
    t.date "days_allowed", array: true
    t.date "days_blocked", array: true
    t.boolean "weekend", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "allow_tags", array: true
    t.string "title"
    t.integer "pass_type_id"
    t.integer "ticket_id"
    t.string "tracks_allowed", array: true
  end

  create_table "groups", force: :cascade do |t|
    t.string "username"
    t.string "chain_index"
    t.string "chain_space"
    t.string "image_url"
    t.string "nickname"
    t.text "about"
    t.string "twitter"
    t.string "github"
    t.string "discord"
    t.string "telegram"
    t.string "ens"
    t.string "lens"
    t.string "nostr"
    t.string "website"
    t.string "location"
    t.integer "parent_id"
    t.string "permissions", default: [], array: true
    t.string "status", default: "active", null: false, comment: "active | freezed"
    t.string "event_tags", array: true
    t.boolean "event_enabled", default: false
    t.string "can_publish_event", default: "everyone", comment: "manager | member | everyone"
    t.string "can_join_event", default: "everyone", comment: "manager | member | everyone"
    t.string "can_view_event", default: "everyone", comment: "manager | member | everyone"
    t.boolean "map_enabled", default: false
    t.integer "map_union", array: true
    t.string "banner_link_url"
    t.string "banner_image_url"
    t.text "banner_text"
    t.datetime "created_at", null: false
    t.string "logo_url"
    t.integer "memberships_count", default: 0, null: false
    t.integer "events_count", default: 0, null: false
    t.string "group_tags", array: true
    t.string "timezone"
    t.string "map_preview_url"
    t.string "can_publish_event_with_approval", default: "none", comment: "member | everyone | none"
    t.string "group_space_logo_url"
    t.string "event_site_tags", array: true
    t.string "event_requirement_tags", array: true
    t.string "farcaster"
    t.integer "main_event_id"
    t.string "stripe_app_key"
    t.string "stripe_app_secret"
    t.string "stripe_callback"
    t.string "stripe_data"
    t.string "customizer"
    t.boolean "group_ticket_enabled", default: false
    t.integer "group_ticket_event_id"
    t.date "start_date"
    t.date "end_date"
    t.jsonb "social_links", default: {}
    t.datetime "updated_at"
    t.string "handle"
    t.integer "group_union", array: true
    t.string "op_label_list", default: [], array: true
    t.index ["group_tags"], name: "index_groups_on_group_tags", using: :gin
    t.index ["handle"], name: "index_groups_on_handle"
    t.index ["status"], name: "index_groups_on_status"
  end

  create_table "mail_tokens", force: :cascade do |t|
    t.string "email"
    t.string "code"
    t.boolean "verified", default: false
    t.datetime "created_at", null: false
  end

  create_table "map_checkins", force: :cascade do |t|
    t.integer "marker_id"
    t.integer "profile_id"
    t.integer "badge_id"
    t.string "check_type"
    t.string "content"
    t.string "image_url"
    t.datetime "created_at", null: false
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
    t.integer "badge_class_id"
    t.integer "voucher_id"
    t.integer "event_id"
    t.string "highlight"
    t.text "message"
    t.integer "map_checkins_count", default: 0, null: false
    t.string "marker_state", comment: "like zugame state"
    t.datetime "created_at", null: false
    t.datetime "updated_at"
    t.string "location_data"
    t.index ["geo_lat", "geo_lng"], name: "index_markers_on_geo_lat_and_geo_lng"
    t.index ["group_id", "status"], name: "index_markers_on_group_id_and_status"
  end

  create_table "memberships", force: :cascade do |t|
    t.integer "profile_id"
    t.integer "target_id"
    t.string "role", default: "member", null: false, comment: "member | issuer | event_manager | guardian | manager | owner"
    t.string "status", default: "normal", null: false, comment: "normal | freezed"
    t.datetime "created_at"
    t.string "cap"
    t.jsonb "data"
    t.datetime "updated_at"
    t.index ["profile_id", "target_id"], name: "index_memberships_on_profile_id_and_target_id", unique: true
    t.index ["target_id", "role"], name: "index_memberships_on_target_id_and_role"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.bigint "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.bigint "resource_owner_id"
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.string "scopes"
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "operator_notes", force: :cascade do |t|
    t.integer "author_id"
    t.integer "event_id"
    t.text "content"
    t.integer "mentions", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "order_items", force: :cascade do |t|
    t.integer "order_id"
    t.integer "product_id"
    t.integer "product_item_id"
    t.integer "quantity"
    t.datetime "created_at", null: false
  end

  create_table "orders", force: :cascade do |t|
    t.integer "estore_id"
    t.integer "profile_id"
    t.integer "amount"
    t.integer "payment_point_class_id"
    t.integer "payment_badge_id"
    t.string "memo"
    t.string "status", default: "normal", null: false, comment: "normal | cancel"
    t.string "pay_status", default: "pending", comment: "pending | success | cancel"
    t.string "delivery_code"
    t.string "delivery_status", default: "success", comment: "pending | success | failed | cancel"
    t.datetime "created_at", null: false
  end

  create_table "participants", force: :cascade do |t|
    t.integer "event_id"
    t.integer "profile_id"
    t.text "message"
    t.string "role", comment: "attendee | speaker | organizer"
    t.integer "voucher_id"
    t.integer "badge_id"
    t.string "status", default: "applied", null: false, comment: "applied | pending | disapproved | checked | cancel"
    t.datetime "check_time"
    t.datetime "created_at", null: false
    t.integer "ticket_id"
    t.string "payment_status"
    t.string "payment_data"
    t.string "payment_chain"
    t.datetime "register_time"
    t.index ["event_id", "status"], name: "index_participants_on_event_id_and_status"
    t.index ["event_id"], name: "index_participants_on_event_id"
    t.index ["profile_id", "status"], name: "index_participants_on_profile_id_and_status"
    t.index ["profile_id"], name: "index_participants_on_profile_id"
  end

  create_table "payment_methods", force: :cascade do |t|
    t.string "item_type"
    t.integer "item_id"
    t.string "chain"
    t.string "kind"
    t.string "token_name"
    t.string "token_address"
    t.string "receiver_address"
    t.integer "price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "protocol"
  end

  create_table "point_balances", force: :cascade do |t|
    t.integer "point_class_id"
    t.integer "creator_id"
    t.integer "owner_id"
    t.integer "value", default: 0
    t.datetime "created_at", null: false
  end

  create_table "point_classes", force: :cascade do |t|
    t.string "name"
    t.string "title"
    t.string "sym", default: "pt", null: false
    t.text "metadata"
    t.text "content"
    t.string "image_url"
    t.string "chain_index"
    t.string "chain_space"
    t.integer "creator_id"
    t.integer "group_id"
    t.boolean "transferable", default: false, null: false
    t.boolean "revocable", default: false, null: false
    t.string "point_type", default: "point", null: false, comment: "point | credit"
    t.integer "total_supply", default: 0
    t.datetime "created_at", null: false
    t.index ["creator_id"], name: "index_point_classes_on_creator_id"
  end

  create_table "point_transfers", force: :cascade do |t|
    t.integer "point_class_id"
    t.integer "sender_id"
    t.integer "receiver_id"
    t.integer "value", default: 0
    t.string "status", default: "pending", null: false, comment: "pending | accepted | rejected | revoked"
    t.datetime "created_at", null: false
  end

  create_table "popup_cities", force: :cascade do |t|
    t.string "title"
    t.string "image_url"
    t.string "location"
    t.string "website"
    t.integer "group_id"
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "group_tags", array: true
  end

  create_table "product_items", force: :cascade do |t|
    t.integer "product_id"
    t.string "label"
    t.string "image_url"
    t.integer "inventory"
    t.integer "price"
    t.integer "payment_point_class_id"
    t.integer "payment_badge_id"
    t.integer "index", default: 0, null: false
    t.string "status", default: "normal", null: false, comment: "draft | normal | closed"
    t.datetime "created_at", null: false
  end

  create_table "products", force: :cascade do |t|
    t.integer "estore_id"
    t.string "title"
    t.string "image_urls", array: true
    t.string "memo"
    t.string "start_time"
    t.string "end_time"
    t.string "product_type"
    t.string "status", default: "normal", null: false, comment: "draft | normal | closed"
    t.text "content"
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
    t.text "about"
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
    t.string "sol_address"
    t.string "far_fid"
    t.string "far_address"
    t.string "zupass_edge_event_id"
    t.string "zupass_edge_product_id"
    t.string "zupass_edge_product_name"
    t.date "zupass_edge_start_date"
    t.date "zupass_edge_end_date"
    t.boolean "zupass_edge_weekend", default: false
    t.string "farcaster"
    t.datetime "updated_at"
    t.jsonb "social_links", default: {}
    t.string "handle"
    t.string "mina_address"
    t.string "fuel_address"
    t.jsonb "telegram_data"
    t.string "telegram_id"
    t.index ["address"], name: "index_profiles_on_address", unique: true
    t.index ["email"], name: "index_profiles_on_email", unique: true
    t.index ["phone"], name: "index_profiles_on_phone", unique: true
    t.index ["username"], name: "index_profiles_on_username", unique: true
  end

  create_table "recurrings", force: :cascade do |t|
    t.datetime "start_time"
    t.datetime "end_time"
    t.string "interval"
    t.integer "event_count"
    t.string "timezone"
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

  create_table "submissions", force: :cascade do |t|
    t.string "custom_form_id"
    t.jsonb "answers"
    t.integer "profile_id"
    t.string "subject_type"
    t.integer "subject_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ticket_items", force: :cascade do |t|
    t.string "status"
    t.integer "profile_id"
    t.integer "ticket_id"
    t.integer "event_id"
    t.string "chain"
    t.string "txhash"
    t.integer "amount"
    t.string "ticket_price"
    t.string "discount_value"
    t.string "discount_data"
    t.string "order_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "participant_id"
    t.string "ticket_type", default: "event", comment: "event | group"
    t.integer "group_id"
    t.string "auth_type", comment: "free | payment | zupass | badge | invite"
    t.string "tracks_allowed", array: true
    t.integer "payment_method_id"
    t.integer "token_address"
    t.integer "receiver_address"
    t.integer "coupon_id"
    t.string "sender_address"
    t.string "selector_type"
    t.string "selector_address"
    t.decimal "original_price", precision: 40
    t.string "protocol"
    t.index ["event_id", "status"], name: "index_ticket_items_on_event_id_and_status"
    t.index ["order_number"], name: "index_ticket_items_on_order_number"
    t.index ["profile_id", "status"], name: "index_ticket_items_on_profile_id_and_status"
  end

  create_table "tickets", force: :cascade do |t|
    t.string "title"
    t.string "content"
    t.integer "event_id"
    t.integer "check_badge_class_id"
    t.integer "quantity"
    t.datetime "end_time"
    t.boolean "need_approval"
    t.string "status", default: "normal"
    t.string "payment_chain"
    t.string "payment_token_name"
    t.string "payment_token_address"
    t.string "payment_target_address"
    t.datetime "created_at", null: false
    t.integer "payment_token_price"
    t.jsonb "payment_metadata"
    t.string "ticket_type", default: "event", comment: "event | group"
    t.integer "group_id"
    t.string "zupass_event_id"
    t.string "zupass_product_id"
    t.string "zupass_product_name"
    t.date "start_date"
    t.date "end_date"
    t.date "days_allowed", array: true
    t.datetime "updated_at"
    t.integer "tracks_allowed", default: [], array: true
    t.index ["event_id", "status"], name: "index_tickets_on_event_id_and_status"
    t.index ["group_id", "status"], name: "index_tickets_on_group_id_and_status"
  end

  create_table "track_roles", force: :cascade do |t|
    t.integer "group_id"
    t.integer "track_id"
    t.integer "profile_id"
    t.string "receiver_address"
    t.string "role", default: "member"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.integer "manager_ids", array: true
  end

  create_table "venue_overrides", force: :cascade do |t|
    t.integer "venue_id"
    t.date "day"
    t.boolean "disabled"
    t.string "start_at"
    t.string "end_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role"
  end

  create_table "venue_timeslots", force: :cascade do |t|
    t.integer "venue_id"
    t.string "day_of_week"
    t.boolean "disabled"
    t.string "start_at"
    t.string "end_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role"
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
    t.jsonb "timeslots"
    t.string "link"
    t.integer "capacity"
    t.jsonb "overrides"
    t.boolean "require_approval", default: false
    t.string "tags", array: true
    t.boolean "removed"
    t.string "visibility", comment: "all | manager | none"
    t.datetime "updated_at"
    t.string "location_data"
    t.string "amenities", default: [], array: true
    t.string "image_urls", default: [], array: true
    t.string "featured_image_url"
    t.integer "track_ids", default: [], array: true
    t.index ["group_id", "visibility"], name: "index_venues_on_group_id_and_visibility"
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
    t.string "status", default: "open", null: false, comment: "draft | open | closed | cancel"
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
    t.string "receiver_address_type"
    t.datetime "claimed_at"
    t.boolean "claimed_by_server", default: false
    t.string "strategy", default: "code"
    t.integer "issued_amount"
    t.string "issued_token_ids", array: true
    t.string "minted_tx"
    t.string "minted_address"
    t.string "minted_ids", array: true
    t.datetime "created_at", null: false
    t.jsonb "data", comment: "start_time, end_time, value, transferable, revocable"
    t.index ["sender_id"], name: "index_vouchers_on_sender_id"
  end

  add_foreign_key "activities", "profiles", column: "initiator_id"
  add_foreign_key "contacts", "profiles", column: "source_id"
  add_foreign_key "contacts", "profiles", column: "target_id"
  add_foreign_key "estores", "groups"
  add_foreign_key "estores", "profiles", column: "owner_id"
  add_foreign_key "events", "badge_classes"
  add_foreign_key "events", "profiles", column: "owner_id"
  add_foreign_key "events", "recurrings"
  add_foreign_key "group_invites", "badge_classes"
  add_foreign_key "group_invites", "profiles", column: "receiver_id"
  add_foreign_key "group_invites", "profiles", column: "sender_id"
  add_foreign_key "groups", "groups", column: "parent_id"
  add_foreign_key "map_checkins", "markers"
  add_foreign_key "map_checkins", "profiles"
  add_foreign_key "markers", "badge_classes"
  add_foreign_key "markers", "groups"
  add_foreign_key "markers", "profiles", column: "owner_id"
  add_foreign_key "markers", "vouchers"
  add_foreign_key "memberships", "groups", column: "target_id"
  add_foreign_key "memberships", "profiles"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "product_items"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "estores"
  add_foreign_key "orders", "profiles"
  add_foreign_key "participants", "events"
  add_foreign_key "participants", "profiles"
  add_foreign_key "point_balances", "point_classes"
  add_foreign_key "point_balances", "profiles", column: "creator_id"
  add_foreign_key "point_balances", "profiles", column: "owner_id"
  add_foreign_key "point_classes", "groups"
  add_foreign_key "point_classes", "profiles", column: "creator_id"
  add_foreign_key "point_transfers", "point_classes"
  add_foreign_key "point_transfers", "profiles", column: "receiver_id"
  add_foreign_key "point_transfers", "profiles", column: "sender_id"
  add_foreign_key "product_items", "products"
  add_foreign_key "products", "estores"
  add_foreign_key "vote_options", "groups"
  add_foreign_key "vote_options", "vote_proposals"
  add_foreign_key "vote_proposals", "groups"
  add_foreign_key "vote_proposals", "groups", column: "eligibile_group_id"
  add_foreign_key "vote_proposals", "point_balances", column: "eligibile_point_id"
  add_foreign_key "vote_proposals", "profiles", column: "creator_id"
  add_foreign_key "vote_records", "groups"
  add_foreign_key "vote_records", "profiles", column: "voter_id"
  add_foreign_key "vote_records", "vote_proposals"
  add_foreign_key "vouchers", "badge_classes"
  add_foreign_key "vouchers", "profiles", column: "receiver_id"
  add_foreign_key "vouchers", "profiles", column: "sender_id"
end
