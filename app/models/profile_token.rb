class ProfileToken < ApplicationRecord
  validates :context, inclusion: { in: %w(email-verify email-signin) }
end
