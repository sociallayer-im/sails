class ChangeChatTopicItemType < ActiveRecord::Migration[7.1]
  def change
    change_column :chat_messages, :topic_item_type, :string
  end
end
