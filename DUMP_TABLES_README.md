# Database Dump and Load Scripts

This toolkit provides multiple ways to backup and restore your Rails database using JSONL (JSON Lines) format.

## Quick Summary

| Task | Command | Use Case |
|------|---------|----------|
| **Dump** | `bin/dump_tables.rb` | Quick backup to JSONL files |
| **Dump (Advanced)** | `bin/dump_tables_advanced.rb` | Backup with filtering options |
| **Load** | `bin/load_tables.rb` | Simple restore from JSONL |
| **Load (Advanced)** | `bin/load_tables_advanced.rb` | Restore with safety options |
| **Rake: Backup** | `rake db:backup` | Create timestamped backup |
| **Rake: List** | `rake db:list_dumps` | View available backups |
| **Rake: Dump** | `rake db:dump` | Backup using Rake |
| **Rake: Load** | `rake db:load` | Restore using Rake (dry-run first) |

## Overview

Two scripts are provided to dump all database tables into JSONL format:

## Quick Start

### Basic Dump (Raw SQL - Fastest)
```bash
bin/dump_tables.rb
```

This will dump all tables to `db/dumps/` directory with one JSON object per line in each `.jsonl` file.

### Advanced Dump (With Options)
```bash
bin/dump_tables_advanced.rb
```

## Configuration via Environment Variables

### Basic Script
- `DUMP_DIR`: Output directory (default: `db/dumps`)
- `BATCH_SIZE`: Records per batch (default: `1000`)

Example:
```bash
DUMP_DIR=db/backup/latest BATCH_SIZE=5000 bin/dump_tables.rb
```

### Advanced Script
- `DUMP_DIR`: Output directory (default: `db/dumps`)
- `BATCH_SIZE`: Records per batch (default: `1000`) - only used with `USE_MODELS=true`
- `USE_MODELS`: Use ActiveRecord models for serialization (default: `false`)
- `INCLUDE_TIMESTAMPS`: Include `*_at` timestamp fields (default: `true`)
- `EXCLUDE_TABLES`: Comma-separated list of tables to skip (default: empty)
- `ONLY_TABLES`: Comma-separated list of tables to dump only (default: empty)

Examples:
```bash
# Dump only specific tables
ONLY_TABLES=events,groups bin/dump_tables_advanced.rb

# Exclude sensitive tables and system tables
EXCLUDE_TABLES=users,passwords bin/dump_tables_advanced.rb

# Use Rails models and exclude timestamps
USE_MODELS=true INCLUDE_TIMESTAMPS=false bin/dump_tables_advanced.rb

# Dump to custom location with batch processing
DUMP_DIR=/tmp/db_backup USE_MODELS=true BATCH_SIZE=2000 bin/dump_tables_advanced.rb
```

## Output Format

Files are created with the naming convention: `{table_name}.jsonl`

Example output (`events.jsonl`):
```json
{"id":1,"title":"Event 1","start_time":"2025-01-18T10:00:00.000Z","created_at":"2025-01-18T10:00:00.000Z"}
{"id":2,"title":"Event 2","start_time":"2025-01-18T11:00:00.000Z","created_at":"2025-01-18T11:00:00.000Z"}
```

## Performance Notes

- **Basic Script**: Faster for large tables, uses raw SQL directly
- **Advanced Script**: Slower but provides better integration with Rails models
- For very large tables, use `USE_MODELS=false` (default) for better performance
- Adjust `BATCH_SIZE` based on available memory for your dataset size

## Loading Data from Dumps

Two scripts are provided to load JSONL files back into the database:

### Basic Load (Simple)
```bash
bin/load_tables.rb
```

This will load all JSONL files from `db/dumps/` into their corresponding database tables.

### Advanced Load (With Options)
```bash
bin/load_tables_advanced.rb
```

## Load Configuration

### Basic Script
- `DUMP_DIR`: Input directory (default: `db/dumps`)
- `BATCH_SIZE`: Records per batch (default: `1000`)
- `PATTERN`: File pattern to match (default: `*.jsonl`)

Example:
```bash
DUMP_DIR=db/backup/latest bin/load_tables.rb
```

### Advanced Script
All basic options plus:
- `CLEAR_TABLES`: Clear tables before loading (default: `false`)
- `SKIP_ERRORS`: Skip individual record errors and continue (default: `false`)
- `UPDATE_EXISTING`: Use upsert to update existing records by ID (default: `false`)
- `SKIP_TABLES`: Comma-separated list of tables to skip (default: empty)
- `ONLY_TABLES`: Comma-separated list of tables to load only (default: empty)
- `DRY_RUN`: Simulate loading without writing to database (default: `false`)

Examples:

```bash
# Simple load - append to existing data
bin/load_tables.rb

# Clear all tables and reload
CLEAR_TABLES=true bin/load_tables_advanced.rb

# Load only specific tables
ONLY_TABLES=events,groups bin/load_tables_advanced.rb

# Skip certain tables
SKIP_TABLES=good_jobs,oauth_access_tokens bin/load_tables_advanced.rb

# Update existing records instead of creating duplicates
UPDATE_EXISTING=true bin/load_tables_advanced.rb

# Skip individual record errors but continue loading
SKIP_ERRORS=true bin/load_tables_advanced.rb

# Test without actually writing to database
DRY_RUN=true bin/load_tables_advanced.rb

# Combined options
CLEAR_TABLES=true SKIP_ERRORS=true UPDATE_EXISTING=true bin/load_tables_advanced.rb
```

## Load Order Considerations

For tables with foreign key constraints, load in the correct order:

```bash
# Example: Load dependencies first
ONLY_TABLES=profiles,groups bin/load_tables_advanced.rb
ONLY_TABLES=events,memberships bin/load_tables_advanced.rb
ONLY_TABLES=participants bin/load_tables_advanced.rb
```

Key dependencies in this schema:
- **profiles** and **groups** (base tables)
- **events**, **memberships**, **badge_classes** (depend on groups/profiles)
- **participants**, **tickets** (depend on events/profiles)
- **badges**, **vouchers** (depend on badge_classes/profiles)

## Safety Features

- **DRY_RUN**: Always test with `DRY_RUN=true` first on production backups
- **SKIP_ERRORS**: Useful for partial restores or when some records may conflict
- **UPDATE_EXISTING**: Prevents duplicate key errors when reloading the same dump
- Progress reporting shows exactly what was loaded

## Restore from Dump (Step by Step)

```bash
# 1. Verify files exist
ls db/dumps/

# 2. Test the load with dry run
DRY_RUN=true bin/load_tables_advanced.rb

# 3. For fresh database, clear and reload
CLEAR_TABLES=true bin/load_tables_advanced.rb

# 4. For existing database, use upsert to avoid conflicts
UPDATE_EXISTING=true SKIP_ERRORS=true bin/load_tables_advanced.rb
```

## Using Rake Tasks

Alternatively, use the provided Rake tasks for easier management:

### Create Timestamped Backup
```bash
rake db:backup
# Creates: db/backups/20250118_164530/ with all JSONL files
```

### List Available Backups
```bash
rake db:list_dumps
# Shows timestamped backups and their sizes
```

### Dump Using Rake
```bash
rake db:dump
rake db:dump DUMP_DIR=/tmp/my_backup
```

### Load Using Rake
```bash
# This runs a dry-run first as a safety check
rake db:load DUMP_DIR=db/backups/20250118_164530

# Force load (skip dry-run)
rake db:load_force DUMP_DIR=db/backups/20250118_164530

# Load with options
rake db:load_force DUMP_DIR=db/backups/20250118_164530 CLEAR_TABLES=true UPDATE_EXISTING=true
```

### Load Specific Tables Using Rake
```bash
rake db:load_tables ONLY_TABLES=events,groups DUMP_DIR=db/dumps
```

## Typical Workflow

### Regular Backups
```bash
# Daily backup to timestamped directory
rake db:backup

# View available backups
rake db:list_dumps

# Restore from specific backup
rake db:load_force DUMP_DIR=db/backups/20250118_164530
```

### Selective Export/Import
```bash
# Export only events and participants
ONLY_TABLES=events,participants bin/dump_tables_advanced.rb

# Import only those tables
ONLY_TABLES=events,participants bin/load_tables_advanced.rb

# Or with Rake
rake db:load_tables ONLY_TABLES=events,participants DUMP_DIR=db/dumps
```

### Disaster Recovery
```bash
# Fresh restore on new server
CLEAR_TABLES=true bin/load_tables_advanced.rb

# Or with Rake
rake db:load_force DUMP_DIR=db/backups/20250118_164530 CLEAR_TABLES=true
```

## Best Practices

1. **Always dry-run first**: Use `DRY_RUN=true` before production restores
2. **Test on dev/staging**: Verify backups and restores in non-production first
3. **Monitor disk space**: JSONL files can be large - ensure adequate disk space
4. **Regular backups**: Use cron or scheduled tasks to create regular backups
5. **Version control**: Keep backup scripts in version control
6. **Document procedures**: Maintain runbooks for your specific restore procedures

## Troubleshooting

### "Model not found" errors
This occurs when Rails can't find a model for a table name. Check:
```bash
# Verify model exists
ls app/models/{table_name_singular}.rb

# Or check model class name
rails console
> YourModel.table_name
```

### Foreign key constraint errors
Load tables in dependency order:
```bash
ONLY_TABLES=profiles,groups bin/load_tables_advanced.rb
ONLY_TABLES=events,memberships bin/load_tables_advanced.rb
ONLY_TABLES=participants bin/load_tables_advanced.rb
```

Or disable constraints temporarily:
```sql
-- In PostgreSQL
ALTER TABLE table_name DISABLE TRIGGER ALL;
-- ... load data ...
ALTER TABLE table_name ENABLE TRIGGER ALL;
```

### Out of memory on large datasets
Reduce batch size:
```bash
BATCH_SIZE=100 bin/load_tables_advanced.rb
```

### Files taking too long to load
Check for timeout and try skipping errors:
```bash
SKIP_ERRORS=true bin/load_tables_advanced.rb
```
