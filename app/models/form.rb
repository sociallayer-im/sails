class Form < ApplicationRecord
  TSID_GENERATOR = Tsid::Generator.new

  has_many :form_fields, -> { order(:position) }, foreign_key: :form_id, primary_key: :id
  has_many :form_submissions, foreign_key: :form_id, primary_key: :id

  before_create :set_id

  private

  def set_id
    self.id ||= TSID_GENERATOR.generate.to_s
    self.slug ||= self.id
  end
end
