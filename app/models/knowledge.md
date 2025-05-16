# Models Knowledge

## Core Models

### Profile
- Represents user accounts
- Multiple authentication methods
- Handles user permissions and roles
- Manages user relationships and following

### Group
- Represents organizations/communities
- Role-based permissions (owner, manager, operator, member)
- Can organize events
- Supports tracks for event organization
- Can be frozen/unfrozen

### Event
- Represents gatherings/meetings
- Can be recurring
- Supports custom forms
- Has multiple display states (normal, pinned, public, hidden)
- Tracks attendance and participation
- Can issue badges

### Venue
- Represents event locations
- Manages availability
- Handles capacity and amenities
- Supports location data and geocoding

### Ticket
- Manages event attendance
- Supports multiple payment methods
- Handles coupon codes
- Tracks payment status

### Badge
- Represents achievements/credentials
- Can be transferred
- Supports swapping
- Can be burned (invalidated)

## Relationships
- Groups have many events and members
- Events belong to groups and have participants
- Venues are associated with events
- Profiles can be members of multiple groups
- Tickets belong to events and profiles

## Validation Rules
- Handle unique constraints
- Validate status transitions
- Check permissions and ownership
- Ensure data integrity

## Best Practices
- Use appropriate callbacks
- Keep business logic in models
- Write comprehensive tests
- Document complex methods
