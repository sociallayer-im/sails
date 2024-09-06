class Community < ApplicationRecord
  belongs_to :group
  enum :kind, { popup_city: 'popup_city', community: 'community' }
end
