#!/usr/bin/env ruby

require_relative '../config/environment'
require 'fileutils'
require 'json'

# Configuration
INPUT_DIR = ENV['DUMP_DIR'] || 'db/dumps'
BATCH_SIZE = ENV['BATCH_SIZE']&.to_i || 1000
PATTERN = ENV['PATTERN'] || '*.jsonl'

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

puts "Loading #{files.length} files from #{INPUT_DIR}..."
puts ""

total_records = 0
failed_tables = []

files.each do |file|
  table_name = File.basename(file, '.jsonl')
  count = 0

  begin
    # Get model class
    model_class = table_name.classify.constantize

    File.foreach(file) do |line|
      data = JSON.parse(line.strip)
      model_class.create!(data)
      count += 1
    end

    puts "✓ #{table_name}: #{count} records loaded"
    total_records += count
  rescue Errno::ENOENT => e
    puts "✗ #{table_name}: File not found - #{e.message}"
    failed_tables << table_name
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
puts "Total records loaded: #{total_records}"
puts "Failed tables: #{failed_tables.join(', ')}" if failed_tables.any?
puts "✓ Load completed!"
