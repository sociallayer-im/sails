class Submission < ApplicationRecord
  belongs_to :custom_form
  belongs_to :profile
  belongs_to :subject, polymorphic: true
end
