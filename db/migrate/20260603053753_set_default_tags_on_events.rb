class SetDefaultTagsOnEvents < ActiveRecord::Migration[7.2]
  def change
    change_column_default :events, :tags, from: nil, to: []
    # Backfill existing NULL rows
    execute "UPDATE events SET tags = '{}' WHERE tags IS NULL"
  end
end
