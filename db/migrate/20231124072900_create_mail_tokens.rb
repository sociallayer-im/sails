class CreateMailTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :mail_tokens do |t|
      t.string "email"
      t.string "code"
      t.boolean "verified", default: false
      t.datetime "created_at", null: false
    end
  end
end
