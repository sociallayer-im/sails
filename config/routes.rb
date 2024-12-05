Rails.application.routes.draw do
  use_doorkeeper
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  namespace :api, path: "" do
    post "service/send_email", to: "service#send_email"
    post "service/upload_image", to: "service#upload_image"

    get "siwe/nonce", to: "profile#nonce"
    post "siwe/verify", to: "profile#verify"

    post "form/submit", to: "form#submit"

    get  "profile/me", to: "profile#me"
    post "profile/create", to: "profile#create"
    post "profile/update", to: "profile#update"
    get  "profile/get_by_email", to: "profile#get_by_email"
    get  "profile/get_by_handle", to: "profile#get_by_handle"
    post "profile/signin_with_email", to: "profile#signin_with_email"
    post "profile/set_verified_email", to: "profile#set_verified_email"
    post "profile/signin_with_zkemail", to: "profile#signin_with_zkemail"
    post "profile/signin_with_multi_zupass", to: "profile#signin_with_multi_zupass"
    post "profile/signin_with_solana", to: "profile#signin_with_solana"
    post "profile/signin_with_farcaster", to: "profile#signin_with_farcaster"
    post "profile/signin_with_world_id", to: "profile#signin_with_world_id"
    post "profile/signin_with_mina", to: "profile#signin_with_mina"
    post "profile/signin_with_fuel", to: "profile#signin_with_fuel"
    post "profile/track_list", to: "profile#track_list"

    post "group/create", to: "group#create"
    post "group/update", to: "group#update"
    post "group/freeze", to: "group#freeze_group"
    post "group/transfer_owner", to: "group#transfer_owner"
    post "group/freeze_group", to: "group#freeze_group"
    get  "group/is_manager", to: "group#is_manager"
    get  "group/is_operator", to: "group#is_operator"
    get  "group/is_member", to: "group#is_member"
    post "group/remove_member", to: "group#remove_member"
    post "group/remove_operator", to: "group#remove_operator"
    post "group/remove_manager", to: "group#remove_manager"
    post "group/add_manager", to: "group#add_manager"
    post "group/add_operator", to: "group#add_operator"
    post "group/leave", to: "group#leave"

    post "group/update_track", to: "group#update_track"

    post "group/send_invite", to: "group_invite#send_invite"
    post "group/accept_invite", to: "group_invite#accept_invite"
    post "group/cancel_invite", to: "group_invite#cancel_invite"
    post "group/revoke_invite", to: "group_invite#revoke_invite"
    post "group/request_invite", to: "group_invite#request_invite"
    post "group/accept_request", to: "group_invite#accept_request"
    post "group/send_invite_by_email", to: "group_invite#send_invite_by_email"

    get "event/get", to: "event#get"
    post "event/create", to: "event#create"
    post "event/update", to: "event#update"
    post "event/unpublish", to: "event#unpublish"
    post "event/check_group_permission", to: "event#check_group_permission"
    post "event/join", to: "event#join"
    post "event/check", to: "event#check"
    post "event/cancel", to: "event#cancel"
    post "event/remove_participant", to: "event#remove_participant"
    post "event/set_notes", to: "event#set_notes"

    get "event/discover", to: "event#discover"
    get "event/list", to: "event#list"
    get "event/my_stars", to: "event#my_stars"
    get "event/list_for_calendar", to: "event#list"
    get "event/private_list", to: "event#private_list"
    get "event/private_track_list", to: "event#private_track_list"
    get "event/my_event_list", to: "event#my_event_list"
    get "event/starred_event_list", to: "event#starred_event_list"
    get "event/created_by_me", to: "event#created_by_me"
    get "event/latest_changed", to: "event#latest_changed"
    get "event/themes_list", to: "event#themes_list"

    post "comment/list", to: "comment#list"
    post "comment/create", to: "comment#create"
    post "comment/remove", to: "comment#remove"
    post "comment/star", to: "comment#star"
    post "comment/unstar", to: "comment#unstar"

    post "recurring/create", to: "recurring#create"
    post "recurring/update", to: "recurring#update"

    post "ticket/rsvp", to: "ticket#rsvp"
    post "ticket/set_payment_status", to: "ticket#set_payment_status"
    post "ticket/cancel_unpaid_item", to: "ticket#cancel_unpaid_item"
    post "ticket/stripe_callback", to: "ticket#stripe_callback"
    post "ticket/stripe_client_secret", to: "ticket#stripe_client_secret"
    post "ticket/stripe_config", to: "ticket#stripe_config"
    post "ticket/add_group_ticket_item", to: "ticket#add_group_ticket_item"
    get  "ticket/list_group_ticket_types", to: "ticket#list_group_ticket_types"
    post "ticket/daimo_create_payment_link", to: "ticket#daimo_create_payment_link"
    post "ticket/daimo_webhook", to: "ticket#daimo_webhook"

    post "marker/create", to: "marker#create"
    post "marker/update", to: "marker#update"
    post "marker/remove", to: "marker#remove"
    post "marker/checkin", to: "marker#checkin"

    post "badge_class/create", to: "badge_class#create"

    get  "remember/meta", to: "remember#meta"
    post "remember/create", to: "remember#create"
    post "remember/join", to: "remember#join"
    post "remember/cancel", to: "remember#cancel"
    get  "remember/get", to: "remember#get"
    post "remember/mint", to: "remember#mint"

    post "voucher/create", to: "voucher#create"
    post "voucher/use", to: "voucher#use"
    get  "voucher/get_code", to: "voucher#get_code"
    post "voucher/revoke", to: "voucher#revoke"
    post "voucher/send_badge", to: "voucher#send_badge"
    post "voucher/send_badge_by_address", to: "voucher#send_badge_by_address"
    post "voucher/send_badge_by_email", to: "voucher#send_badge_by_email"
    post "voucher/accept_badge", to: "voucher#accept_badge"
    post "voucher/reject_badge", to: "voucher#reject_badge"

    post "venue/create", to: "venue#create"
    post "venue/update", to: "venue#update"
    post "venue/remove", to: "venue#remove"
    post "venue/check_availability", to: "venue#check_availability"

    post "point_class/create", to: "point_class#create"
    post "point/create", to: "point#create"
    post "point/accept", to: "point#accept"
    post "point/reject", to: "point#reject"
    post "point/transfer", to: "point#transfer"

    post "vote/create", to: "vote#create"
    post "vote/update", to: "vote#update"
    post "vote/cancel", to: "vote#cancel"
    post "vote/cast_vote", to: "vote#cast_vote"

    get "service/get_participanted_events_by_email", to: "service#get_participanted_events_by_email"
    get "service/get_hosted_events_by_email", to: "service#get_hosted_events_by_email"
    get "service/get_user_related_groups", to: "service#get_user_related_groups"
  end

  get    "sign_in",  to: "sessions#new"
  post   "sign_in",  to: "sessions#create"
  post   "verify",   to: "sessions#verify"
  get    "verifier",   to: "sessions#verifier"
  delete "sign_out", to: "sessions#destroy"
  resources :sessions, only: [:index, :show]

  # Defines the root path route ("/")
  get  "demo",  to: "home#demo"
  root "home#index"
end
