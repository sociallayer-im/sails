class AddKeyToEvents < ActiveRecord::Migration[7.2]
  def up
    add_column :events, :key, :string unless column_exists?(:events, :key)
    add_index :events, :key, unique: true unless index_exists?(:events, :key)

    # generator = Tsid::Generator.new
    # Event.where(key: nil).order(:created_at, :id).find_in_batches(batch_size: 500) do |batch|
    #   batch.each do |event|
    #     timestamp = event.start_time || event.created_at
    #     event.update_column(:key, generator.generate(timestamp))
    #   end
    # end

    # change_column_null :events, :key, false
  end

  def down
    remove_column :events, :key
  end
end
