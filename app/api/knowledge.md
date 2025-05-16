# API Layer Knowledge

## Overview
The API layer uses two approaches:
1. Grape API (`app/api/core/api.rb`)
2. Rails API controllers (`app/controllers/api/`)

## Authentication
- JWT token-based authentication
- Doorkeeper OAuth integration
- `current_profile` and `current_profile!` methods for auth
- Multiple signin methods supported:
  - Email
  - Google
  - Solana
  - Farcaster
  - World ID
  - Mina
  - Fuel
  - Telegram
  - ZK Email
  - Multi Zupass

## Error Handling
- `AppError` for general application errors
- `AuthTokenError` for authentication errors
- Consistent error response format:
  ```json
  {
    "result": "error",
    "message": "error description"
  }
  ```

## API Entities
- `ProfileEntity`: User profile data
- `VenueEntity`: Venue/location data
- `GroupEntity`: Group information
- `TicketEntity`: Ticket details
- `EventRoleEntity`: Event role assignments
- `FormFieldEntity`: Custom form fields
- `CustomFormEntity`: Event forms
- `EventEntity`: Event information
- `PopupCityEntity`: Popup city data

## Key Endpoints
- Profile management
- Event operations
- Group management
- Ticket handling
- Venue management
- Badge and point systems
- Voting mechanisms
- Activity tracking

## Best Practices
- Use appropriate HTTP methods
- Validate input parameters
- Handle errors consistently
- Document API changes
- Test new endpoints
