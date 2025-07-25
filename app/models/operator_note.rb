class OperatorNote < ApplicationRecord
  belongs_to :author, class_name: "Profile"
  belongs_to :event
end
