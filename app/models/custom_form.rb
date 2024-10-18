class CustomForm < ApplicationRecord
  has_many :form_fields
  has_many :submissions
  belongs_to :group, optional: true
  belongs_to :item, polymorphic: true, optional: true
end
