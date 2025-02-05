if group.present?
  json.group do
  json.extract! group, :id, :handle, :username, :nickname, :timezone
  end
else
  json.group nil
end
