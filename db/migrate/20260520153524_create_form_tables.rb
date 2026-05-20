class CreateFormTables < ActiveRecord::Migration[7.1]
  def up
    drop_table :form_fields if table_exists?(:form_fields)

    create_table :forms, id: :string, force: :cascade do |t|
      t.string :title, null: false
      t.text :description
      t.string :slug, null: false
      t.boolean :published, default: false, null: false
      t.text :submission_message
      t.string :created_by_id
      t.timestamps
      t.index :slug, unique: true
      t.index :created_by_id
    end

    create_table :form_fields, id: :string, force: :cascade do |t|
      t.string :form_id, null: false
      t.string :label, null: false
      t.string :field_type, null: false
      t.boolean :required, default: false, null: false
      t.boolean :for_admin, default: false
      t.integer :position, default: 0, null: false
      t.jsonb :options, default: []
      t.timestamps
      t.index [:form_id, :position]
    end

    create_table :form_submissions, id: :string, force: :cascade do |t|
      t.string :form_id, null: false
      t.string :user_id, null: false
      t.string :status, default: 'pending', null: false
      t.boolean :starred, default: false, null: false
      t.text :admin_note
      t.datetime :submitted_at, default: -> { 'CURRENT_TIMESTAMP' }, null: false
      t.timestamps
      t.index [:form_id, :status]
      t.index [:form_id, :user_id], unique: true
      t.index :user_id
    end

    create_table :form_answers, id: :string, force: :cascade do |t|
      t.string :form_submission_id, null: false
      t.string :form_field_id, null: false
      t.text :value
      t.timestamps
      t.index :form_submission_id
      t.index :form_field_id
    end

    add_column :events, :form_id, :string unless column_exists?(:events, :form_id)
  end

  def down
    remove_column :events, :form_id if column_exists?(:events, :form_id)
    drop_table :form_answers
    drop_table :form_submissions
    drop_table :form_fields
    drop_table :forms
  end
end
