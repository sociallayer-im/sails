class AddKeyToProfiles < ActiveRecord::Migration[7.2]
  def up
    add_column :profiles, :key, :string
    add_index :profiles, :key, unique: true

    generator = Tsid::Generator.new
    Profile.order(:created_at, :id).find_in_batches(batch_size: 2000) do |batch|
      records = batch.map do |profile|
        { id: profile.id, key: generator.generate(profile.created_at) }
      end
      Profile.upsert_all(records, update_only: [:key])
    end
  end

  def down
    remove_column :profiles, :key
  end
end
