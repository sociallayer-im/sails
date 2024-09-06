class CreateProfileTokens < ActiveRecord::Migration[7.2]
  def change
    create_table :profile_tokens do |t|
      t.string "context"
      t.string "sent_to"
      t.string "code"
      t.boolean "verified", default: false
      t.datetime "created_at", null: false
    end
  end
end
