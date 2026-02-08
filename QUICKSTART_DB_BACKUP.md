# Database Backup & Restore Quick Start

## 5-Minute Setup

### 1. Create Your First Backup

```bash
# Option A: Using Rake (Recommended)
rake db:backup

# Option B: Direct script
bin/dump_tables.rb
```

This creates JSONL files (one JSON object per line) of all your tables.

### 2. Verify the Backup

```bash
# List backups
rake db:list_dumps

# Or manually
ls -lh db/dumps/ db/backups/
```

### 3. Restore from Backup

```bash
# Safe restore with dry-run first
rake db:load DUMP_DIR=db/backups/20250118_164530

# Then force load (after reviewing dry-run output)
rake db:load_force DUMP_DIR=db/backups/20250118_164530
```

## Common Commands

### Quick Backup
```bash
rake db:backup
# → Creates timestamped backup in db/backups/YYYYMMDD_HHMMSS/
```

### Quick Restore
```bash
rake db:load_force DUMP_DIR=db/backups/20250118_164530
```

### Backup Specific Tables
```bash
ONLY_TABLES=events,groups,profiles bin/dump_tables_advanced.rb
```

### Restore Specific Tables
```bash
ONLY_TABLES=events,groups bin/load_tables_advanced.rb
```

### Fresh Database Restore
```bash
rake db:load_force DUMP_DIR=db/backups/20250118_164530 CLEAR_TABLES=true
```

## What Gets Backed Up?

All database tables **except**:
- `schema_migrations` (managed by Rails)
- `good_jobs*` (job queue - can be regenerated)
- `pg_*` (PostgreSQL system tables)

## File Structure

```
db/
├── dumps/              # Default backup location
│   ├── events.jsonl
│   ├── groups.jsonl
│   ├── profiles.jsonl
│   └── ... (one file per table)
└── backups/            # Timestamped backups
    └── 20250118_164530/
        ├── events.jsonl
        └── ...
```

## Safety Tips

1. **Always dry-run first**: `rake db:load` does this automatically
2. **Backup before testing**: `rake db:backup` before major operations
3. **Test on dev/staging**: Verify restores work before production
4. **Keep backups**: Store old backups for recovery
5. **Monitor disk space**: JSONL files can be large

## Troubleshooting

**"No JSONL files found"**
```bash
# Create backup first
rake db:backup
```

**"Model not found" errors**
```bash
# Some tables might not have models - this is OK
# Use SKIP_ERRORS flag
SKIP_ERRORS=true rake db:load_force DUMP_DIR=db/backups/...
```

**Running out of memory**
```bash
# Reduce batch size
BATCH_SIZE=100 bin/load_tables_advanced.rb
```

## Full Documentation

See `DUMP_TABLES_README.md` for complete options and advanced usage.

## Example Workflow

```bash
# Day 1: Create initial backup
rake db:backup
# → db/backups/20250118_140000/

# Day 2: Create another backup
rake db:backup
# → db/backups/20250118_160000/

# Day 3: List all backups
rake db:list_dumps

# Day 4: Restore from Day 1 backup
rake db:load_force DUMP_DIR=db/backups/20250118_140000 CLEAR_TABLES=true

# Day 5: Backup just events table
ONLY_TABLES=events bin/dump_tables_advanced.rb
# → db/dumps/events.jsonl

# Day 6: Restore just events table
ONLY_TABLES=events bin/load_tables_advanced.rb
```

---

**Questions?** Check `DUMP_TABLES_README.md` for detailed documentation.
