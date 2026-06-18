class CreatePlacesAndMigrateLocationData < ActiveRecord::Migration[7.2]
  def up
    create_table :places, force: :cascade do |t|
      t.string   "address"
      t.text     "description"
      t.decimal  "geo_lat",  precision: 10, scale: 6
      t.decimal  "geo_lng",  precision: 10, scale: 6
      t.string   "name", null: false
      t.text     "location_viewport"
      t.timestamps null: false
    end
    add_index :places, :name, name: "index_places_on_name"

    add_column :events,  :place_id, :bigint
    add_column :markers, :place_id, :bigint
    add_column :venues,  :place_id, :bigint

    [
      { table: :events,  name_col: :location },
      { table: :markers, name_col: :location },
      { table: :venues,  name_col: :location },
    ].each do |cfg|
      execute(<<~SQL).each do |row|
        SELECT id, #{cfg[:name_col]}, formatted_address, location_viewport, geo_lat, geo_lng
        FROM #{cfg[:table]}
        WHERE #{cfg[:name_col]} IS NOT NULL AND #{cfg[:name_col]} != ''
      SQL
        place = find_or_create_place(
          name:              row["location"],
          address:           row["formatted_address"],
          location_viewport: row["location_viewport"],
          geo_lat:           row["geo_lat"],
          geo_lng:           row["geo_lng"],
        )
        execute("UPDATE #{cfg[:table]} SET place_id = #{place.id} WHERE id = #{row["id"]}")
      end
    end

    %i[events markers venues].each do |tbl|
      remove_column tbl, :location
      remove_column tbl, :formatted_address
      remove_column tbl, :location_viewport
      remove_column tbl, :geo_lat
      remove_column tbl, :geo_lng
    end
  end

  def down
    %i[events markers venues].each do |tbl|
      add_column tbl, :location,          :string
      add_column tbl, :formatted_address, :string
      add_column tbl, :location_viewport, :text
      add_column tbl, :geo_lat,           :decimal, precision: 10, scale: 6
      add_column tbl, :geo_lng,           :decimal, precision: 10, scale: 6

      execute(<<~SQL)
        UPDATE #{tbl}
        SET
          location          = places.name,
          formatted_address = places.address,
          location_viewport = places.location_viewport,
          geo_lat           = places.geo_lat,
          geo_lng           = places.geo_lng
        FROM places
        WHERE #{tbl}.place_id = places.id
      SQL

      remove_column tbl, :place_id
    end

    drop_table :places
  end

  private

  def find_or_create_place(name:, address:, location_viewport:, geo_lat:, geo_lng:)
    Place.find_or_create_by(
      name:              name,
      address:           address,
      geo_lat:           geo_lat,
      geo_lng:           geo_lng,
      location_viewport: location_viewport,
    )
  end
end
