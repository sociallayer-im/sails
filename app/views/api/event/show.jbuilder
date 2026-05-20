json.partial! 'api/event/event', event: @event
json.partial! 'api/profile/profile_or_nil', profile: @event.owner
json.partial! 'api/venue/venue_or_nil', venue: @event.venue
json.partial! 'api/group/group_or_nil', group: @event.group

json.tickets @event.tickets do |ticket|
  json.extract! ticket, :id, :title, :content, :ticket_type, :quantity, :end_time, :need_approval, :status, :zupass_event_id, :zupass_product_id, :zupass_product_name, :start_date, :end_date, :days_allowed, :tracks_allowed
  json.payment_methods ticket.payment_methods do |pm|
    json.extract! pm, :id, :chain, :token_name, :token_address, :receiver_address, :price
  end
end

json.event_roles @event.event_roles do |event_role|
  json.extract! event_role, :id, :role, :item_id, :item_type, :nickname, :image_url
  if event_role.item_type == 'Profile' && event_role.item_id
    profile = Profile.find_by(id: event_role.item_id)
    json.profile profile ? profile.as_json(only: [:id, :handle, :nickname, :image_url]) : nil
  elsif event_role.item_type == 'Group' && event_role.item_id
    group = Group.find_by(id: event_role.item_id)
    json.group group ? group.as_json(only: [:id, :handle, :nickname, :image_url]) : nil
  end
end

json.partial! 'api/event/custom_form', custom_form: @event.custom_form

if @event.form
  json.form do
    json.extract! @event.form, :id, :title, :description
    json.fields @event.form.form_fields do |field|
      json.extract! field, :id, :label, :field_type, :required, :position
    end
  end
else
  json.form nil
end
