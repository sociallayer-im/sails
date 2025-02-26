# Models Knowledge

## Overview
The application uses ActiveRecord models to represent the domain entities and their relationships.

## Key Models
- **Profile**: Represents users of the application
- **Group**: Represents groups that can organize events
- **Event**: Represents events organized by groups or profiles
- **Venue**: Represents locations where events can be held
- **Badge**: Represents badges that can be awarded to profiles
- **Ticket**: Represents tickets for events
- **Participant**: Represents profiles participating in events
- **Membership**: Represents profiles' membership in groups
- **Comment**: Represents comments on various entities
- **Marker**: Represents map markers
- **Vote**: Represents voting mechanisms

## Relationships
- Groups have many events and members (profiles)
- Events belong to groups and have many participants
- Profiles can be members of multiple groups and participate in multiple events
- Venues are associated with events

## Validation and Business Logic
- Models contain validation rules and business logic
- Some models include methods for checking permissions and status
