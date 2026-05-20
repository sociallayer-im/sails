class AddKeyToEvents < ActiveRecord::Migration[7.2]
  def up
    add_column :events, :key, :string unless column_exists?(:events, :key)
    add_index :events, :key, unique: true unless index_exists?(:events, :key)

    generator = Tsid::Generator.new
    Event.where(key: nil).order(:created_at, :id).find_in_batches(batch_size: 2000) do |batch|
      records = batch.map do |event|
        timestamp = event.start_time || event.created_at
        { id: event.id, key: generator.generate(timestamp) }
      end
      Event.upsert_all(records, update_only: [:key])
    end

    # change_column_null :events, :key, false
  end

  def down
    remove_column :events, :key
  end
end
