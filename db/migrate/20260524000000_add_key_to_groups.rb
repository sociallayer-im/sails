class AddKeyToGroups < ActiveRecord::Migration[7.2]
  def up
    add_column :groups, :key, :string
    add_index :groups, :key, unique: true

    generator = Tsid::Generator.new
    Group.order(:created_at, :id).find_in_batches(batch_size: 2000) do |batch|
      records = batch.map do |group|
        { id: group.id, key: generator.generate(group.created_at) }
      end
      Group.upsert_all(records, update_only: [:key])
    end
  end

  def down
    remove_column :groups, :key
  end
end
