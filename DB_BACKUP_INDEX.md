# Database Backup & Load Toolkit - File Index

## Created Files

### Executable Scripts (in `bin/`)

| File | Size | Purpose |
|------|------|---------|
| `bin/dump_tables.rb` | 1.1K | Basic database dump - fastest, raw SQL |
| `bin/dump_tables_advanced.rb` | 2.8K | Advanced dump with filtering and options |
| `bin/load_tables.rb` | 1.5K | Basic database load from JSONL |
| `bin/load_tables_advanced.rb` | 3.8K | Advanced load with safety features |

All scripts are **executable** (`chmod +x`) and **tested** for syntax correctness.

### Rake Tasks (in `lib/tasks/`)

| File | Purpose |
|------|---------|
| `lib/tasks/db_dump.rake` | Rake tasks for backup/restore operations |

**Available Rake tasks:**
- `rake db:backup` - Create timestamped backup
- `rake db:dump` - Dump database to JSONL
- `rake db:dump_tables` - Dump specific tables
- `rake db:load` - Load with dry-run check (safe)
- `rake db:load_force` - Force load without dry-run
- `rake db:load_tables` - Load specific tables
- `rake db:list_dumps` - List available backups

### Documentation

| File | Purpose |
|------|---------|
| `DUMP_TABLES_README.md` | Complete technical documentation |
| `QUICKSTART_DB_BACKUP.md` | Quick start guide for common tasks |
| `DB_BACKUP_INDEX.md` | This file - overview of all components |

---

## Quick Start

### Recommended: Use Rake Tasks

```bash
# Backup
rake db:backup

# View backups
rake db:list_dumps

# Restore (safe - runs dry-run first)
rake db:load DUMP_DIR=db/backups/20250118_164530

# Force restore
rake db:load_force DUMP_DIR=db/backups/20250118_164530
```

### Alternative: Use Scripts Directly

```bash
# Dump all tables
bin/dump_tables.rb

# Load all tables
bin/load_tables.rb

# With options
ONLY_TABLES=events,groups bin/dump_tables_advanced.rb
CLEAR_TABLES=true bin/load_tables_advanced.rb
```

---

## Feature Comparison

### Dump Scripts

**`dump_tables.rb` (Basic)**
- ✓ Fast (raw SQL)
- ✓ Simple usage
- ✗ No filtering
- Configuration: `DUMP_DIR`, `BATCH_SIZE`

**`dump_tables_advanced.rb` (Advanced)**
- ✓ Fast (raw SQL)
- ✓ Table filtering
- ✓ Selective export
- ✓ Progress reporting
- Configuration: `DUMP_DIR`, `BATCH_SIZE`, `USE_MODELS`, `INCLUDE_TIMESTAMPS`, `EXCLUDE_TABLES`, `ONLY_TABLES`

### Load Scripts

**`load_tables.rb` (Basic)**
- ✓ Simple usage
- ✓ Creates records
- ✗ No safety features
- Configuration: `DUMP_DIR`, `BATCH_SIZE`, `PATTERN`

**`load_tables_advanced.rb` (Advanced)**
- ✓ Dry-run mode
- ✓ Error recovery (`SKIP_ERRORS`)
- ✓ Update existing records (`UPDATE_EXISTING`)
- ✓ Clear tables before load (`CLEAR_TABLES`)
- ✓ Selective loading
- ✓ Batch processing
- ✓ Detailed reporting
- Configuration: All basic options plus `CLEAR_TABLES`, `SKIP_ERRORS`, `UPDATE_EXISTING`, `SKIP_TABLES`, `ONLY_TABLES`, `DRY_RUN`

### Rake Tasks

**`db_dump.rake`**
- ✓ Timestamped backups
- ✓ Dry-run by default on load
- ✓ List and browse backups
- ✓ Progress reporting
- ✓ Combines dump/load with options
- ✓ Backup/restore workflow integration

---

## Usage Scenarios

### Scenario 1: Daily Backup
```bash
rake db:backup
# Creates db/backups/20250118_164530/ with all tables
```

### Scenario 2: Export Specific Tables for Testing
```bash
ONLY_TABLES=events,participants bin/dump_tables_advanced.rb
# Creates db/dumps/events.jsonl and db/dumps/participants.jsonl
```

### Scenario 3: Restore from Disaster
```bash
# List available backups
rake db:list_dumps

# Restore latest
rake db:load_force DUMP_DIR=db/backups/20250118_164530 CLEAR_TABLES=true
```

### Scenario 4: Migrate Data Between Environments
```bash
# On source environment
DUMP_DIR=/tmp/migrate bin/dump_tables_advanced.rb

# Transfer /tmp/migrate files to target

# On target environment
DUMP_DIR=/tmp/migrate rake db:load_force
```

### Scenario 5: Partial Restore with Error Handling
```bash
SKIP_ERRORS=true UPDATE_EXISTING=true bin/load_tables_advanced.rb
```

---

## File Locations

```
project_root/
├── bin/
│   ├── dump_tables.rb                 ← Dump script (basic)
│   ├── dump_tables_advanced.rb        ← Dump script (advanced)
│   ├── load_tables.rb                 ← Load script (basic)
│   └── load_tables_advanced.rb        ← Load script (advanced)
├── lib/
│   └── tasks/
│       └── db_dump.rake               ← Rake tasks
├── db/
│   ├── dumps/                         ← Default output directory
│   │   ├── events.jsonl
│   │   ├── groups.jsonl
│   │   └── ...
│   └── backups/                       ← Timestamped backups
│       ├── 20250118_140000/
│       ├── 20250118_160000/
│       └── ...
├── DUMP_TABLES_README.md              ← Full documentation
├── QUICKSTART_DB_BACKUP.md            ← Quick start guide
└── DB_BACKUP_INDEX.md                 ← This file
```

---

## Configuration Guide

### Environment Variables for Scripts

```bash
# Common to all scripts
DUMP_DIR=path/to/dumps        # Default: db/dumps
BATCH_SIZE=1000               # Default: 1000

# Dump-specific
USE_MODELS=true               # Default: false
INCLUDE_TIMESTAMPS=false      # Default: true
EXCLUDE_TABLES=table1,table2  # Default: empty
ONLY_TABLES=table1,table2     # Default: empty
PATTERN=*.jsonl               # Default: *.jsonl

# Load-specific
CLEAR_TABLES=true             # Default: false
SKIP_ERRORS=true              # Default: false
UPDATE_EXISTING=true          # Default: false
DRY_RUN=true                  # Default: false
```

### Rake Task Usage

```bash
# Pass environment variables
rake db:backup DUMP_DIR=/custom/path

# Multiple options
rake db:load_force DUMP_DIR=db/backups/20250118_164530 CLEAR_TABLES=true UPDATE_EXISTING=true
```

---

## Output Format

All tools output JSONL files (JSON Lines):

**File:** `events.jsonl`
```
{"id":1,"title":"Event 1","start_time":"2025-01-18T10:00:00Z","created_at":"2025-01-18T10:00:00Z"}
{"id":2,"title":"Event 2","start_time":"2025-01-18T11:00:00Z","created_at":"2025-01-18T11:00:00Z"}
```

Benefits:
- One JSON object per line (easily parseable)
- Streaming-friendly (process huge files line-by-line)
- Works with standard Unix tools (`grep`, `sed`, `jq`)
- Human-readable
- No file size limits

---

## Support & Documentation

### Quick Links

- **Getting Started**: `QUICKSTART_DB_BACKUP.md`
- **Full Documentation**: `DUMP_TABLES_README.md`
- **This Guide**: `DB_BACKUP_INDEX.md`

### Common Commands Reference

```bash
# Create backup
rake db:backup

# List backups
rake db:list_dumps

# Export specific tables
ONLY_TABLES=events,groups bin/dump_tables_advanced.rb

# Safe restore (dry-run first)
rake db:load DUMP_DIR=db/backups/20250118_164530

# Force restore
rake db:load_force DUMP_DIR=db/backups/20250118_164530

# Clear and restore
rake db:load_force DUMP_DIR=db/backups/20250118_164530 CLEAR_TABLES=true

# Test without writing
DRY_RUN=true bin/load_tables_advanced.rb
```

---

## Version Info

- **Created**: 2025-01-18
- **Rails Version**: 7.2+ (tested on this project)
- **Ruby Version**: 3.0+ (uses modern Ruby syntax)
- **Database**: PostgreSQL (uses JSONL format - DB agnostic)

---

**Ready to use!** Start with `rake db:backup` or see `QUICKSTART_DB_BACKUP.md`.
