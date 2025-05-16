# Configuration Knowledge

## Key Configuration Files

### Application Configuration
- `config/application.rb`: Main Rails configuration
- `config/environments/`: Environment-specific settings
- `config/database.yml`: Database configuration
- `config/routes.rb`: Application routing

### Initializers
- `config/initializers/doorkeeper.rb`: OAuth provider setup
- `config/initializers/assets.rb`: Asset pipeline config
- `config/initializers/inflections.rb`: Custom pluralization rules
- Other initializers for various gems

### Localization
- `config/locales/en.yml`: English translations
- `config/locales/doorkeeper.en.yml`: OAuth translations

### Deployment
- `config/deploy.yml`: Kamal deployment configuration
- `config/dockerfile.yml`: Docker build configuration

## Environment Variables
Required environment variables:
- `RAILS_MAX_THREADS`: Database connection pool size
- `SOLIA_DATABASE_PASSWORD`: Production database password
- Other sensitive credentials in `credentials.yml.enc`

## Database Configuration
- Development: `solia_development`
- Test: `solia_test`
- Production: `solia_production`

## Best Practices
- Keep sensitive data in credentials
- Use environment variables for configuration
- Document configuration changes
- Test configuration updates
