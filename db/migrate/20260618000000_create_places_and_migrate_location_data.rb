class CreatePlacesAndMigrateLocationData < ActiveRecord::Migration[7.2]
  def up
    create_table :places, force: :cascade do |t|
      t.string   "address"
      t.decimal  "geo_lat",  precision: 10, scale: 6
      t.decimal  "geo_lng",  precision: 10, scale: 6
      t.string   "name", null: false
      t.text     "location_viewport"
      t.string   "data", comment: "Google Maps place_id"
      t.timestamps null: false
    end
    add_index :places, :name, name: "index_places_on_name"

    add_column :events,  :place_id, :bigint
    add_column :markers, :place_id, :bigint
    add_column :venues,  :place_id, :bigint

    # Batch load all location data from each table in one query each
    all_rows = {}
    %i[events markers venues].each do |tbl|
      all_rows[tbl] = execute(<<~SQL).to_a
        SELECT id, location, formatted_address, location_viewport, geo_lat, geo_lng
        FROM #{tbl}
        WHERE location IS NOT NULL AND location != ''
      SQL
    end

    # Deduplicate in Ruby across all three tables
    unique_places = {}
    all_rows.each_value do |rows|
      rows.each do |row|
        key = place_key(row)
        next if unique_places.key?(key)
        unique_places[key] = {
          name:              row['location'],
          address:           row['formatted_address'],
          geo_lat:           row['geo_lat'],
          geo_lng:           row['geo_lng'],
          location_viewport: row['location_viewport'],
        }
      end
    end

    # Batch insert all unique places
    if unique_places.any?
      now = Time.current.utc
      Place.insert_all!(unique_places.values.map { |attrs| attrs.merge(created_at: now, updated_at: now) })
    end

    # Reload from DB to build lookup — avoids String vs BigDecimal type mismatch
    # that would occur if we used RETURNING directly (AR casts decimals to BigDecimal).
    # The table was just created so every row here came from our insert.
    place_id_lookup = Place.all.each_with_object({}) do |place, map|
      map[place_key_from_model(place)] = place.id
    end

    # Batch update each table with a single VALUES-based UPDATE
    %i[events markers venues].each do |tbl|
      rows = all_rows[tbl]
      next if rows.empty?

      pairs = rows.filter_map do |row|
        place_id = place_id_lookup[place_key(row)]
        next unless place_id
        "(#{row['id'].to_i}, #{place_id.to_i})"
      end
      next if pairs.empty?

      execute(<<~SQL)
        UPDATE #{tbl}
        SET place_id = data.place_id
        FROM (VALUES #{pairs.join(', ')}) AS data(id, place_id)
        WHERE #{tbl}.id = data.id
      SQL
    end

    # Drop the now-redundant location columns
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

  # Key from raw PG execute row — values are Ruby Strings
  def place_key(row)
    [
      row['location'],
      row['formatted_address'],
      normalize_coord(row['geo_lat']),
      normalize_coord(row['geo_lng']),
      row['location_viewport'],
    ]
  end

  # Key from AR model — geo values are BigDecimal
  def place_key_from_model(place)
    [
      place.name,
      place.address,
      normalize_coord(place.geo_lat),
      normalize_coord(place.geo_lng),
      place.location_viewport,
    ]
  end

  # Normalize to a canonical decimal string regardless of input type (String or BigDecimal).
  # BigDecimal("37.774900").to_s('F') => "37.7749"
  # BigDecimal("37.774900") from AR  => same
  # nil stays nil.
  def normalize_coord(v)
    return nil if v.nil?
    BigDecimal(v.to_s).to_s('F')
  end
end
