class FormAnswer < ApplicationRecord
  TSID_GENERATOR = Tsid::Generator.new

  belongs_to :form_submission, foreign_key: :form_submission_id, primary_key: :id
  belongs_to :form_field, foreign_key: :form_field_id, primary_key: :id

  before_create :set_id

  private

  def set_id
    self.id ||= TSID_GENERATOR.generate.to_s
  end
end
