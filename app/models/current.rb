class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :user_agent, :ip_address
end
