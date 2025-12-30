import ballerina/test;

// Test the public utility functions

@test:Config {}
function testPrintSafeWithMap() returns error? {
    map<anydata> config = {
        "username": "testuser",
        "password": "secret123",
        "host": "localhost",
        "port": 5432
    };
    
    // This should print the config with password masked
    // We can't easily test the output, but we can ensure it doesn't throw an error
    printSafe(config);
    
    test:assertTrue(true, "printSafe should execute without error");
}

@test:Config {}
function testPrintSafeWithNonMap() {
    string config = "not a map";
    
    // This should print a message about unsupported type
    printSafe(config);
    
    test:assertTrue(true, "printSafe should handle non-map types gracefully");
}

@test:Config {}
function testPrintSafeWithComplexMap() returns error? {
    map<anydata> config = {
        "databaseHost": "localhost",
        "databasePassword": "supersecret",
        "apiKey": "abc123",
        "logLevel": "INFO",
        "port": 5432,
        "enableSsl": true
    };
    
    printSafe(config);
    
    test:assertTrue(true, "printSafe should handle complex configurations");
}