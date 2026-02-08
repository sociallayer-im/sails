namespace :db do
  desc "Dump all database tables to JSONL files"
  task :dump => :environment do
    # Configuration
    output_dir = ENV['DUMP_DIR'] || 'db/dumps'

    puts "Dumping database tables to #{output_dir}..."
    system("bin/dump_tables_advanced.rb")
  end

  desc "Dump specific tables to JSONL files"
  task :dump_tables => :environment do
    # Usage: rake db:dump_tables ONLY_TABLES=events,groups DUMP_DIR=db/backup
    tables = ENV['ONLY_TABLES'] || ''
    output_dir = ENV['DUMP_DIR'] || 'db/dumps'

    unless tables.empty?
      puts "Dumping tables: #{tables}"
      system("ONLY_TABLES=#{tables} DUMP_DIR=#{output_dir} bin/dump_tables_advanced.rb")
    else
      puts "Usage: rake db:dump_tables ONLY_TABLES=table1,table2 [DUMP_DIR=path]"
    end
  end

  desc "Load all JSONL dump files to database"
  task :load => :environment do
    # Configuration
    input_dir = ENV['DUMP_DIR'] || 'db/dumps'

    unless Dir.exist?(input_dir)
      puts "Error: Directory #{input_dir} does not exist"
      exit 1
    end

    # Always use dry run first as a safety check
    puts "=" * 60
    puts "Running dry-run first to check for errors..."
    puts "=" * 60
    system("DRY_RUN=true DUMP_DIR=#{input_dir} bin/load_tables_advanced.rb")

    puts "\n" + "=" * 60
    puts "Dry-run complete. To load data, run:"
    puts "=" * 60
    puts "DUMP_DIR=#{input_dir} bin/load_tables_advanced.rb"
    puts "or:"
    puts "rake db:load_force DUMP_DIR=#{input_dir}"
  end

  desc "Force load all JSONL dump files to database (skips dry-run)"
  task :load_force => :environment do
    # Usage: rake db:load_force DUMP_DIR=path CLEAR_TABLES=true
    input_dir = ENV['DUMP_DIR'] || 'db/dumps'
    clear_tables = ENV['CLEAR_TABLES'] || 'false'
    skip_errors = ENV['SKIP_ERRORS'] || 'false'
    update_existing = ENV['UPDATE_EXISTING'] || 'false'

    unless Dir.exist?(input_dir)
      puts "Error: Directory #{input_dir} does not exist"
      exit 1
    end

    puts "Loading database from #{input_dir}..."
    puts "CLEAR_TABLES: #{clear_tables}"
    puts "UPDATE_EXISTING: #{update_existing}"
    puts "SKIP_ERRORS: #{skip_errors}"
    puts ""

    system("DUMP_DIR=#{input_dir} CLEAR_TABLES=#{clear_tables} UPDATE_EXISTING=#{update_existing} SKIP_ERRORS=#{skip_errors} bin/load_tables_advanced.rb")
  end

  desc "Load specific tables from JSONL dumps"
  task :load_tables => :environment do
    # Usage: rake db:load_tables ONLY_TABLES=events,groups DUMP_DIR=db/backup
    tables = ENV['ONLY_TABLES'] || ''
    input_dir = ENV['DUMP_DIR'] || 'db/dumps'

    unless tables.empty?
      puts "Loading tables: #{tables}"
      system("DUMP_DIR=#{input_dir} ONLY_TABLES=#{tables} bin/load_tables_advanced.rb")
    else
      puts "Usage: rake db:load_tables ONLY_TABLES=table1,table2 [DUMP_DIR=path]"
    end
  end

  desc "Backup database (dump) and show status"
  task :backup => :environment do
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    backup_dir = "db/backups/#{timestamp}"

    puts "Creating backup in #{backup_dir}..."
    system("DUMP_DIR=#{backup_dir} bin/dump_tables_advanced.rb")

    if $?.success?
      puts "\n✓ Backup complete!"
      puts "To restore this backup, run:"
      puts "  rake db:load_force DUMP_DIR=#{backup_dir}"
    else
      puts "\n✗ Backup failed"
      exit 1
    end
  end

  desc "List available dumps"
  task :list_dumps => :environment do
    puts "Available dumps:\n\n"

    # List timestamped backups
    if Dir.exist?('db/backups')
      backups = Dir.glob('db/backups/*').sort.reverse
      if backups.any?
        puts "Timestamped Backups:"
        backups.each do |backup|
          file_count = Dir.glob("#{backup}/*.jsonl").count
          size = `du -sh "#{backup}" 2>/dev/null`.split.first || "?"
          puts "  #{File.basename(backup)}: #{file_count} files (#{size})"
        end
        puts ""
      end
    end

    # List default dumps
    if Dir.exist?('db/dumps')
      files = Dir.glob('db/dumps/*.jsonl').sort
      if files.any?
        puts "Default Dumps (db/dumps):"
        files.each do |file|
          count = File.readlines(file).count
          size = File.size(file)
          puts "  #{File.basename(file)}: #{count} records (#{humanize_bytes(size)})"
        end
      else
        puts "No dumps found in db/dumps/"
      end
    else
      puts "No db/dumps directory found"
    end
  end
end

def humanize_bytes(bytes)
  units = ['B', 'KB', 'MB', 'GB']
  size = bytes.to_f
  unit_index = 0

  while size >= 1024 && unit_index < units.length - 1
    size /= 1024
    unit_index += 1
  end

  "#{size.round(2)} #{units[unit_index]}"
end
