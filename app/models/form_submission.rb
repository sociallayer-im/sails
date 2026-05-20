class FormSubmission < ApplicationRecord
  TSID_GENERATOR = Tsid::Generator.new

  belongs_to :form, foreign_key: :form_id, primary_key: :id
  has_many :form_answers, foreign_key: :form_submission_id, primary_key: :id

  before_create :set_id

  def profile
    Profile.find_by(id: user_id.to_i)
  end

  private

  def set_id
    self.id ||= TSID_GENERATOR.generate.to_s
  end
end
