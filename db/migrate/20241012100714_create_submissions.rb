class CreateSubmissions < ActiveRecord::Migration[7.2]
  def change
    create_table :submissions do |t|
      t.string :custom_form_id
      t.jsonb :answers
      t.integer :profile_id
      t.string :subject_type
      t.integer :subject_id
      t.timestamps
    end
  end
end
