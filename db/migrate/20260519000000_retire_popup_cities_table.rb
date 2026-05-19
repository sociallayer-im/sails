class RetirePopupCitiesTable < ActiveRecord::Migration[7.2]
  def up
    # Copy best popup_city data into each group (prefer :featured ones when multiple exist)
    execute <<-SQL
      UPDATE groups g
      SET
        start_date = COALESCE(g.start_date, pc.start_date),
        end_date   = COALESCE(g.end_date,   pc.end_date),
        location   = COALESCE(g.location,   pc.location),
        website    = COALESCE(g.website,    pc.website),
        group_tags = ARRAY(
          SELECT DISTINCT unnest(
            COALESCE(g.group_tags, ARRAY[]::varchar[]) ||
            COALESCE(pc.group_tags, ARRAY[]::varchar[])
          )
        )
      FROM (
        SELECT DISTINCT ON (group_id)
          group_id, start_date, end_date, location, website, group_tags
        FROM popup_cities
        ORDER BY group_id,
          CASE WHEN group_tags @> ARRAY[':featured']::varchar[] THEN 0 ELSE 1 END,
          id DESC
      ) pc
      WHERE g.id = pc.group_id
    SQL

    drop_table :popup_cities
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
