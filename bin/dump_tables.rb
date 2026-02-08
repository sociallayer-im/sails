#!/usr/bin/env ruby

require_relative '../config/environment'

# Configuration
OUTPUT_DIR = ENV['DUMP_DIR'] || 'db/dumps'
BATCH_SIZE = ENV['BATCH_SIZE']&.to_i || 1000

# Create output directory
FileUtils.mkdir_p(OUTPUT_DIR)

# Get all tables
tables = ActiveRecord::Base.connection.tables.reject { |t| t.start_with?('pg_') || t == 'schema_migrations' }

puts "Dumping #{tables.length} tables to #{OUTPUT_DIR}..."

tables.each do |table_name|
  output_file = File.join(OUTPUT_DIR, "#{table_name}.jsonl")
  count = 0

  begin
    # Use raw SQL to fetch all rows to avoid model instantiation overhead
    connection = ActiveRecord::Base.connection
    result = connection.execute("SELECT * FROM #{table_name}")

    File.open(output_file, 'w') do |file|
      result.each do |row|
        # Convert row to hash and write as JSON line
        file.puts(row.to_json)
        count += 1
      end
    end

    puts "✓ #{table_name}: #{count} records"
  rescue StandardError => e
    puts "✗ #{table_name}: #{e.message}"
  end
end

puts "\n✓ Dump completed! Files saved to #{OUTPUT_DIR}"
