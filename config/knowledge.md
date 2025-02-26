# Configuration Knowledge

## Overview
This directory contains configuration files for the Rails application.

## Key Files
- **application.rb**: Main application configuration
- **routes.rb**: Defines the application routes
- **database.yml**: Database configuration
- **environments/**: Environment-specific configurations
- **initializers/**: Initialization code that runs when the app starts

## Routes
- API routes are defined in `routes.rb` under the `api` namespace
- The application also includes some web routes for sessions and home pages

## Database
- PostgreSQL is used as the database
- Configuration is in `database.yml`
- Different environments (development, test, production) have separate database configurations

## Initializers
- **doorkeeper.rb**: Configuration for OAuth provider
- **assets.rb**: Asset pipeline configuration
- Other initializers for various gems and features

## Deployment
- Deployment configuration is in `deploy.yml`
- The application is deployed using Kamal and Docker
