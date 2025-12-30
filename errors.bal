// Copyright (c) 2024, thambaru. All Rights Reserved.

# Configuration loading error
public type ConfigError distinct error;

# Creates a configuration error with a descriptive message
public function createConfigError(string message) returns ConfigError {
    return error ConfigError(message);
}

# Creates a validation error for missing required fields
public function createMissingFieldError(string fieldName) returns ConfigError {
    return error ConfigError(string `Missing required config field '${fieldName}'`);
}

# Creates a type mismatch error
public function createTypeMismatchError(string fieldName, string expectedType, string actualValue) returns ConfigError {
    return error ConfigError(string `Invalid type for field '${fieldName}'. Expected ${expectedType}, found ${actualValue}`);
}