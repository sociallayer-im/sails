class CreateChatMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :chat_messages do |t|
      t.integer  :topic_title
      t.integer  :topic_item_type
      t.integer  :topic_item_id
      t.integer  :reply_parent_id
      t.text     :content
      t.string   :content_type, default: "text"
      t.integer  :sender_id
      t.boolean  :removed
      t.datetime :created_at
    end
  end
end
