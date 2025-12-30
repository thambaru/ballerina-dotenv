# Configuration loading error
public type ConfigError distinct error;

# Creates a configuration error with a descriptive message
#
# + message - The error message
# + return - The configuration error
public function createConfigError(string message) returns ConfigError {
    return error ConfigError(message);
}

# Creates a validation error for missing required fields
#
# + fieldName - The name of the missing field
# + return - The configuration error
public function createMissingFieldError(string fieldName) returns ConfigError {
    return error ConfigError(string `Missing required config field '${fieldName}'`);
}

# Creates a type mismatch error
#
# + fieldName - The name of the field
# + expectedType - The expected type
# + actualValue - The actual value found
# + return - The configuration error
public function createTypeMismatchError(string fieldName, string expectedType, string actualValue) returns ConfigError {
    return error ConfigError(string `Invalid type for field '${fieldName}'. Expected ${expectedType}, found ${actualValue}`);
}