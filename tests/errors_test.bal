// Copyright (c) 2024, thambaru. All Rights Reserved.

import ballerina/test;

@test:Config {}
function testCreateConfigError() {
    string message = "Test configuration error";
    ConfigError err = createConfigError(message);
    
    test:assertEquals(err.message(), message, "Error message should match input");

}

@test:Config {}
function testCreateMissingFieldError() {
    string fieldName = "requiredField";
    ConfigError err = createMissingFieldError(fieldName);
    
    string expectedMessage = string `Missing required config field '${fieldName}'`;
    test:assertEquals(err.message(), expectedMessage, "Error message should include field name");

}

@test:Config {}
function testCreateTypeMismatchError() {
    string fieldName = "port";
    string expectedType = "int";
    string actualValue = "invalid_port";
    
    ConfigError err = createTypeMismatchError(fieldName, expectedType, actualValue);
    
    string expectedMessage = string `Invalid type for field '${fieldName}'. Expected ${expectedType}, found ${actualValue}`;
    test:assertEquals(err.message(), expectedMessage, "Error message should include all details");

}

@test:Config {}
function testConfigErrorDistinctType() {
    error genericErr = error("Generic error");
    
    // test:assertTrue(configErr is ConfigError, "Should be ConfigError type");
    test:assertFalse(genericErr is ConfigError, "Generic error should not be ConfigError type");
}

@test:Config {}
function testErrorMessagesWithSpecialCharacters() {
    string fieldWithSpecialChars = "field'with\"special&chars";
    ConfigError err = createMissingFieldError(fieldWithSpecialChars);
    
    test:assertTrue(err.message().includes(fieldWithSpecialChars), "Should handle special characters in field names");
}

@test:Config {}
function testErrorMessagesWithEmptyStrings() {
    ConfigError err1 = createConfigError("");
    test:assertEquals(err1.message(), "", "Should handle empty error message");
    
    ConfigError err2 = createMissingFieldError("");
    test:assertTrue(err2.message().includes("Missing required config field"), "Should handle empty field name");
    
    ConfigError err3 = createTypeMismatchError("", "", "");
    test:assertTrue(err3.message().includes("Invalid type for field"), "Should handle empty parameters");
}

@test:Config {}
function testMultipleErrorCreation() {
    ConfigError[] errors = [];
    
    errors.push(createConfigError("Error 1"));
    errors.push(createMissingFieldError("field1"));
    errors.push(createTypeMismatchError("field2", "string", "123"));
    
    test:assertEquals(errors.length(), 3, "Should create multiple distinct errors");
    
    foreach ConfigError err in errors {
        // test:assertTrue(err is ConfigError, "All errors should be ConfigError type");
        test:assertTrue(err.message().length() > 0, "All errors should have non-empty messages");
    }
}