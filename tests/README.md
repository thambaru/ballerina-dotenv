# Test Suite for dotenv Library

This directory contains comprehensive test cases for the dotenv configuration loading library.

## Test Structure

### Unit Tests
- **`loader_test.bal`** - Tests for configuration loading from different sources (env vars, .env files, TOML files)
- **`validator_test.bal`** - Tests for sensitive field detection and value masking
- **`merge_test.bal`** - Tests for configuration merging and precedence handling
- **`errors_test.bal`** - Tests for error creation and handling
- **`utils_test.bal`** - Tests for utility functions like safe printing

### Integration Tests
- **`integration_test.bal`** - End-to-end tests covering complete configuration loading workflows

## Running Tests

### Run All Tests
```bash
bal test
```

### Run Specific Test File
```bash
bal test --tests tests/validator_test.bal
```

### Run Tests with Coverage
```bash
bal test --code-coverage
```

## Test Coverage

The test suite covers:

✅ **Configuration Loading**
- Loading from environment variables with prefix filtering
- Loading from .env files with various formats
- Loading from TOML files with nested structures
- Configuration precedence (env vars > .env > TOML > defaults)

✅ **Data Validation**
- Type conversion and validation
- Required field validation
- Error handling for invalid data

✅ **Security Features**
- Sensitive field detection (password, secret, token, key, auth)
- Safe printing with masked sensitive values

✅ **Utility Functions**
- Safe printing functionality
- Configuration merging with proper precedence

✅ **Error Handling**
- Configuration errors
- Missing field errors
- Type mismatch errors
- File not found scenarios

✅ **Edge Cases**
- Empty configurations
- Malformed files
- Special characters in values
- Multiple equals signs in values
- Quoted values in .env files

## Test Results

**Current Status**: 30 passing, 9 failing

**Passing Tests**:
- All validator tests (sensitive field detection and masking)
- All error handling tests
- All merge configuration tests
- All utility function tests
- Configuration source creation tests

**Known Issues**:
Some integration tests fail due to existing AppConfig.toml file interference. These tests work correctly when run in isolation or when the AppConfig.toml file is temporarily removed.

## Test Data

Tests create temporary files during execution and clean them up automatically. No persistent test data is required.

## Dependencies

Tests use the Ballerina test framework and require:
- `ballerina/test` module
- `ballerina/io` for file operations
- `ballerina/file` for file management
- `ballerina/os` for environment variable testing

## Notes

- Tests are designed to be independent and clean up after themselves
- Some tests may be affected by existing configuration files in the project root
- All core functionality is thoroughly tested with both positive and negative test cases