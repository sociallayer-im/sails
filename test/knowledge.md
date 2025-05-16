# Testing Knowledge

## Overview
The application uses Rails' default testing framework with fixtures.

## Test Organization
- **Model Tests**: `test/models/`
  - Validate associations
  - Test business logic
  - Check validations
  - Verify callbacks

- **Controller Tests**: `test/controllers/`
  - Test API endpoints
  - Verify authentication
  - Check authorization
  - Validate responses

- **Integration Tests**: `test/integration/`
  - Test complex workflows
  - Verify system interactions
  - Check end-to-end functionality

- **Mailer Tests**: `test/mailers/`
  - Test email content
  - Verify recipients
  - Check attachments

## Fixtures
- Located in `test/fixtures/`
- Use meaningful names
- Keep data minimal
- Maintain relationships

## Running Tests
```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/profile_test.rb

# Run specific test
bin/rails test test/models/profile_test.rb:10
```

## Best Practices
- Write descriptive test names
- One assertion per test when possible
- Use appropriate fixtures
- Test edge cases
- Keep tests focused and isolated
- Clean up after tests

## Test Coverage
- SimpleCov is used to measure test coverage
- Coverage reports are generated when tests are run
