# API Knowledge

## Overview
The API layer in this application is implemented using two approaches:
1. Grape API in `app/api/core/api.rb`
2. Rails controllers in `app/controllers/api/`

## Grape API
- Located in `app/api/core/api.rb`
- Uses Grape entities for serialization
- Provides endpoints for core functionality
- Handles authentication via JWT tokens
- Includes error handling for AppError and AuthTokenError

## Rails API Controllers
- Located in `app/controllers/api/`
- Inherit from `ApiController` which handles authentication and error handling
- Use Pundit for authorization
- Return JSON responses

## Authentication
- JWT tokens are used for authentication
- `current_profile` and `current_profile!` methods are used to get the authenticated user
- Doorkeeper is also integrated for OAuth authentication

## Error Handling
- `AppError` for general application errors
- `AuthTokenError` for authentication errors
- Both are rescued and return appropriate HTTP status codes and error messages
