#!/usr/bin/env ruby

require_relative '../config/environment'
require 'fileutils'
require 'json'

# Configuration
INPUT_DIR = ENV['DUMP_DIR'] || 'db/dumps'
BATCH_SIZE = ENV['BATCH_SIZE']&.to_i || 1000
PATTERN = ENV['PATTERN'] || '*.jsonl'
CLEAR_TABLES = ENV['CLEAR_TABLES']&.downcase == 'true'
SKIP_TABLES = (ENV['SKIP_TABLES'] || '').split(',').map(&:strip)
ONLY_TABLES = (ENV['ONLY_TABLES'] || '').split(',').map(&:strip).reject(&:empty?)
SKIP_ERRORS = ENV['SKIP_ERRORS']&.downcase == 'true'
UPDATE_EXISTING = ENV['UPDATE_EXISTING']&.downcase == 'true'
DRY_RUN = ENV['DRY_RUN']&.downcase == 'true'

unless Dir.exist?(INPUT_DIR)
  puts "Error: Directory #{INPUT_DIR} does not exist"
  exit 1
end

# Find all JSONL files
files = Dir.glob(File.join(INPUT_DIR, PATTERN)).sort

unless files.any?
  puts "Error: No JSONL files found in #{INPUT_DIR}"
  exit 1
end

puts "=" * 60
puts "Database Load Configuration"
puts "=" * 60
puts "Input directory: #{INPUT_DIR}"
puts "Batch size: #{BATCH_SIZE}"
puts "Clear tables before loading: #{CLEAR_TABLES}"
puts "Skip errors: #{SKIP_ERRORS}"
puts "Update existing records: #{UPDATE_EXISTING}"
puts "Dry run: #{DRY_RUN}"
puts "Files to load: #{files.length}"
puts ""

if DRY_RUN
  puts "⚠️  DRY RUN MODE - No data will be written to database"
  puts ""
end

total_records = 0
failed_tables = []
skipped_records = []

files.each do |file|
  table_name = File.basename(file, '.jsonl')

  # Skip if in skip list
  if SKIP_TABLES.include?(table_name)
    puts "⊘ #{table_name}: Skipped (in skip list)"
    next
  end

  # Skip if not in only list (if provided)
  if ONLY_TABLES.any? && !ONLY_TABLES.include?(table_name)
    puts "⊘ #{table_name}: Skipped (not in only list)"
    next
  end

  count = 0
  failed_count = 0
  batch = []

  begin
    # Get model class
    model_class = table_name.classify.constantize

    # Clear table if requested
    if CLEAR_TABLES && !DRY_RUN
      puts "Clearing #{table_name}..."
      model_class.delete_all
    end

    File.foreach(file) do |line|
      data = JSON.parse(line.strip)
      batch << data

      # Process batch
      if batch.size >= BATCH_SIZE
        batch_result = process_batch(model_class, batch, DRY_RUN, UPDATE_EXISTING, SKIP_ERRORS)
        count += batch_result[:success]
        failed_count += batch_result[:failed]
        batch.clear
      end
    end

    # Process remaining records
    unless batch.empty?
      batch_result = process_batch(model_class, batch, DRY_RUN, UPDATE_EXISTING, SKIP_ERRORS)
      count += batch_result[:success]
      failed_count += batch_result[:failed]
    end

    puts "✓ #{table_name}: #{count} records loaded (#{failed_count} failed)" if failed_count > 0
    puts "✓ #{table_name}: #{count} records loaded" if failed_count == 0
    total_records += count
  rescue NameError => e
    puts "✗ #{table_name}: Model not found - #{e.message}"
    failed_tables << table_name
  rescue StandardError => e
    puts "✗ #{table_name}: #{e.message}"
    failed_tables << table_name
  end
end

puts "\n" + "=" * 60
puts "Load Summary"
puts "=" * 60
puts "Total records processed: #{total_records}"
puts "Input directory: #{File.expand_path(INPUT_DIR)}"
puts "Mode: #{'DRY RUN' if DRY_RUN}#{'LIVE' unless DRY_RUN}"
puts "Failed tables: #{failed_tables.join(', ')}" if failed_tables.any?
puts "✓ Load completed!"

def process_batch(model_class, batch, dry_run, update_existing, skip_errors)
  success_count = 0
  failed_count = 0

  batch.each do |data|
    begin
      unless dry_run
        if update_existing && data['id']
          model_class.upsert(data)
        else
          model_class.create!(data)
        end
      end
      success_count += 1
    rescue StandardError => e
      if skip_errors
        failed_count += 1
      else
        raise
      end
    end
  end

  { success: success_count, failed: failed_count }
end
