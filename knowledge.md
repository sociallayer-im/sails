# Sails Project Knowledge

## Project Overview
Sails is a Ruby on Rails application that provides API endpoints for managing events, groups, profiles, and other related entities. The application uses a RESTful API design pattern and includes authentication via JWT tokens and Doorkeeper.

## Technology Stack
- **Framework**: Ruby on Rails 7.2
- **Database**: PostgreSQL
- **API**: Grape for API endpoints
- **Authentication**: JWT tokens and Doorkeeper
- **Frontend**: Rails with Stimulus, Turbo, and Tailwind CSS
- **Testing**: Rails default testing framework
- **Deployment**: Kamal and Docker

## Development Practices
- Run tests with `bin/rails test`
- Check code style with `bin/rubocop`
- Run type checking before commits
- Follow Ruby style guide

## Key Features
- Event management with recurring events support
- Group management with roles (owner, manager, operator, member)
- Profile system with multiple authentication methods
- Ticket system with payment integration (Stripe, Daimo)
- Badge and point system
- Venue management with availability checking
- Custom forms for events
- Voting system
- Activity tracking
- Email notifications

## Architecture
- **API Layer**: 
  - Grape API in `app/api/core/api.rb`
  - Rails controllers in `app/controllers/api/`
- **Models**: Business logic and data models in `app/models/`
- **Policies**: Authorization rules in `app/policies/`
- **Mailers**: Email templates in `app/mailers/`
- **Views**: Frontend templates in `app/views/`

## Testing
- Model tests for validations and business logic
- Controller tests for API endpoints
- Integration tests for complex workflows
- Fixtures for test data

## Deployment
- Uses Kamal for deployment orchestration
- Docker containerization
- Configuration in `.kamal/` and `config/deploy.yml`
