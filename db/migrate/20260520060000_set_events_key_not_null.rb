class SetEventsKeyNotNull < ActiveRecord::Migration[7.2]
  def up
    col = Event.connection.columns(:events).find { |c| c.name == "key" }
    change_column_null :events, :key, false if col&.null
  end

  def down
    change_column_null :events, :key, true
  end
end
