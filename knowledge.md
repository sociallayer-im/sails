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

## Development Practices
- Run tests with `bin/rails test`
- Check code style with `bin/rubocop`

## Key Concepts
- The application is primarily API-driven with endpoints defined in both `config/routes.rb` and `app/api/core/api.rb`
- Authentication is handled through JWT tokens and Doorkeeper
- The application follows a standard Rails MVC architecture
- Pundit is used for authorization policies

## Architecture
- **Controllers**: Located in `app/controllers/`
- **Models**: Located in `app/models/`
- **API Endpoints**: Defined in both `config/routes.rb` and `app/api/core/api.rb`
- **Views**: Located in `app/views/`
- **Policies**: Located in `app/policies/`

## Deployment
- The application is deployed using Kamal and Docker
- Deployment configuration is in `.kamal/` directory and `config/deploy.yml`
