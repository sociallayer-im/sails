#!/usr/bin/env ruby

require_relative '../config/environment'
require 'fileutils'
require 'json'

# Configuration
OUTPUT_DIR = ENV['DUMP_DIR'] || 'db/dumps'
BATCH_SIZE = ENV['BATCH_SIZE']&.to_i || 1000
USE_MODELS = ENV['USE_MODELS']&.downcase == 'true'
INCLUDE_TIMESTAMPS = ENV['INCLUDE_TIMESTAMPS']&.downcase != 'false'
EXCLUDE_TABLES = (ENV['EXCLUDE_TABLES'] || '').split(',').map(&:strip)
ONLY_TABLES = (ENV['ONLY_TABLES'] || '').split(',').map(&:strip).reject(&:empty?)

# Create output directory
FileUtils.mkdir_p(OUTPUT_DIR)

# Get all tables
all_tables = ActiveRecord::Base.connection.tables
  .reject { |t| t.start_with?('pg_') || t == 'schema_migrations' }
  .reject { |t| EXCLUDE_TABLES.include?(t) }

tables = if ONLY_TABLES.any?
          all_tables.select { |t| ONLY_TABLES.include?(t) }
         else
          all_tables
         end

puts "Dumping #{tables.length} tables to #{OUTPUT_DIR}..."
puts "Using Models: #{USE_MODELS}"
puts "Include Timestamps: #{INCLUDE_TIMESTAMPS}"
puts ""

total_records = 0
failed_tables = []

tables.each do |table_name|
  output_file = File.join(OUTPUT_DIR, "#{table_name}.jsonl")
  count = 0

  begin
    if USE_MODELS
      # Use ActiveRecord models for proper serialization
      model_class = table_name.classify.constantize rescue nil

      if model_class
        model_class.find_in_batches(batch_size: BATCH_SIZE) do |batch|
          File.open(output_file, count.zero? ? 'w' : 'a') do |file|
            batch.each do |record|
              json_data = record.attributes.dup
              json_data.reject! { |k, _v| k.end_with?('_at') } unless INCLUDE_TIMESTAMPS
              file.puts(json_data.to_json)
              count += 1
            end
          end
        end
      else
        # Fallback to raw SQL if model doesn't exist
        dump_table_raw_sql(table_name, output_file)
        count = get_record_count(table_name)
      end
    else
      # Use raw SQL for faster dumping
      dump_table_raw_sql(table_name, output_file)
      count = get_record_count(table_name)
    end

    puts "✓ #{table_name}: #{count} records → #{output_file}"
    total_records += count
  rescue StandardError => e
    puts "✗ #{table_name}: #{e.message}"
    failed_tables << table_name
  end
end

puts "\n" + "=" * 60
puts "Dump Summary"
puts "=" * 60
puts "Total records dumped: #{total_records}"
puts "Output directory: #{File.expand_path(OUTPUT_DIR)}"
puts "Failed tables: #{failed_tables.join(', ')}" if failed_tables.any?
puts "✓ Dump completed!"

def dump_table_raw_sql(table_name, output_file)
  connection = ActiveRecord::Base.connection
  result = connection.execute("SELECT * FROM #{table_name}")

  File.open(output_file, 'w') do |file|
    result.each do |row|
      file.puts(row.to_json)
    end
  end
end

def get_record_count(table_name)
  ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM #{table_name}").first['count']
end
