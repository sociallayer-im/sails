# Testing Knowledge

## Overview
The application uses the default Rails testing framework.

## Test Types
- **Model Tests**: Test model validations, associations, and methods
- **Controller Tests**: Test API endpoints and controller actions
- **Integration Tests**: Test interactions between components
- **Mailer Tests**: Test email functionality

## Fixtures
- Test data is defined in YAML fixtures in the `fixtures/` directory
- Fixtures are used to set up test data for all test types

## Running Tests
- Run all tests with `bin/rails test`
- Run specific tests with `bin/rails test test/models/profile_test.rb`
- Run specific test methods with `bin/rails test test/models/profile_test.rb:10`

## Test Coverage
- SimpleCov is used to measure test coverage
- Coverage reports are generated when tests are run
