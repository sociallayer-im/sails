# Database Knowledge

## Overview
The application uses PostgreSQL as its database system.

## Key Tables
- `profiles`: User accounts and authentication
- `groups`: Organizations and communities
- `events`: Gatherings and meetings
- `venues`: Event locations
- `tickets`: Event attendance and payments
- `badges`: Achievements and credentials
- `participants`: Event attendance tracking
- `memberships`: Group membership management
- `comments`: User feedback and interactions
- `activities`: User activity tracking

## Migrations
- Located in `db/migrate/`
- Follow timestamp naming convention
- Include both up and down migrations
- Document complex migrations

## Schema
- Defined in `db/schema.rb`
- Generated from migrations
- Do not edit directly
- Keep under version control

## Best Practices
- Write reversible migrations
- Add appropriate indexes
- Use foreign key constraints
- Document complex changes
- Back up data before migrations
- Test migrations in development

## Common Operations
```bash
# Create database
bin/rails db:create

# Run migrations
bin/rails db:migrate

# Rollback last migration
bin/rails db:rollback

# Load seed data
bin/rails db:seed
```
