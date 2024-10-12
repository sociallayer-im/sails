class CreateFormFields < ActiveRecord::Migration[7.2]
  def change
    create_table :form_fields do |t|
      t.string :label
      t.string :description
      t.string :field_type
      t.jsonb  :field_options
      t.string :required
      t.string :custom_form_id
      t.integer :position
      t.timestamps
    end
  end
end
