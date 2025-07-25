class CreateOperatorNotes < ActiveRecord::Migration[7.2]
  def change
    create_table :operator_notes do |t|
      t.integer :author_id
      t.integer :event_id
      t.text :content
      t.integer :mentions, array: true, default: []

      t.timestamps
    end
  end
end
