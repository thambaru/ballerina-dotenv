import ballerina/test;

@test:Config {}
function testIsSensitiveFieldPassword() {
    test:assertTrue(isSensitiveField("password"), "Should detect 'password' as sensitive");
    test:assertTrue(isSensitiveField("PASSWORD"), "Should detect 'PASSWORD' as sensitive");
    test:assertTrue(isSensitiveField("userPassword"), "Should detect 'userPassword' as sensitive");
    test:assertTrue(isSensitiveField("database_password"), "Should detect 'database_password' as sensitive");
}

@test:Config {}
function testIsSensitiveFieldSecret() {
    test:assertTrue(isSensitiveField("secret"), "Should detect 'secret' as sensitive");
    test:assertTrue(isSensitiveField("SECRET"), "Should detect 'SECRET' as sensitive");
    test:assertTrue(isSensitiveField("apiSecret"), "Should detect 'apiSecret' as sensitive");
    test:assertTrue(isSensitiveField("client_secret"), "Should detect 'client_secret' as sensitive");
}

@test:Config {}
function testIsSensitiveFieldToken() {
    test:assertTrue(isSensitiveField("token"), "Should detect 'token' as sensitive");
    test:assertTrue(isSensitiveField("TOKEN"), "Should detect 'TOKEN' as sensitive");
    test:assertTrue(isSensitiveField("accessToken"), "Should detect 'accessToken' as sensitive");
    test:assertTrue(isSensitiveField("auth_token"), "Should detect 'auth_token' as sensitive");
}

@test:Config {}
function testIsSensitiveFieldKey() {
    test:assertTrue(isSensitiveField("key"), "Should detect 'key' as sensitive");
    test:assertTrue(isSensitiveField("KEY"), "Should detect 'KEY' as sensitive");
    test:assertTrue(isSensitiveField("apiKey"), "Should detect 'apiKey' as sensitive");
    test:assertTrue(isSensitiveField("private_key"), "Should detect 'private_key' as sensitive");
}

@test:Config {}
function testIsSensitiveFieldAuth() {
    test:assertTrue(isSensitiveField("auth"), "Should detect 'auth' as sensitive");
    test:assertTrue(isSensitiveField("AUTH"), "Should detect 'AUTH' as sensitive");
    test:assertTrue(isSensitiveField("authHeader"), "Should detect 'authHeader' as sensitive");
    test:assertTrue(isSensitiveField("basic_auth"), "Should detect 'basic_auth' as sensitive");
}

@test:Config {}
function testIsSensitiveFieldNonSensitive() {
    test:assertFalse(isSensitiveField("username"), "Should not detect 'username' as sensitive");
    test:assertFalse(isSensitiveField("host"), "Should not detect 'host' as sensitive");
    test:assertFalse(isSensitiveField("port"), "Should not detect 'port' as sensitive");
    test:assertFalse(isSensitiveField("database"), "Should not detect 'database' as sensitive");
    test:assertFalse(isSensitiveField("logLevel"), "Should not detect 'logLevel' as sensitive");
    test:assertFalse(isSensitiveField("timeout"), "Should not detect 'timeout' as sensitive");
}

@test:Config {}
function testMaskSensitiveValues() {
    map<anydata> config = {
        "username": "testuser",
        "password": "secret123",
        "host": "localhost",
        "apiKey": "abc123xyz",
        "port": 5432,
        "authToken": "bearer_token_here",
        "logLevel": "INFO"
    };
    
    map<anydata> masked = maskSensitiveValues(config);
    
    // Non-sensitive values should remain unchanged
    test:assertEquals(masked["username"], "testuser", "Username should not be masked");
    test:assertEquals(masked["host"], "localhost", "Host should not be masked");
    test:assertEquals(masked["port"], 5432, "Port should not be masked");
    test:assertEquals(masked["logLevel"], "INFO", "LogLevel should not be masked");
    
    // Sensitive values should be masked
    test:assertEquals(masked["password"], "***MASKED***", "Password should be masked");
    test:assertEquals(masked["apiKey"], "***MASKED***", "API key should be masked");
    test:assertEquals(masked["authToken"], "***MASKED***", "Auth token should be masked");
}

@test:Config {}
function testMaskSensitiveValuesEmptyMap() {
    map<anydata> config = {};
    map<anydata> masked = maskSensitiveValues(config);
    
    test:assertEquals(masked.length(), 0, "Empty map should remain empty");
}

@test:Config {}
function testMaskSensitiveValuesAllSensitive() {
    map<anydata> config = {
        "password": "secret123",
        "apiKey": "abc123",
        "token": "xyz789",
        "secret": "hidden"
    };
    
    map<anydata> masked = maskSensitiveValues(config);
    
    foreach string key in masked.keys() {
        test:assertEquals(masked[key], "***MASKED***", string `All values should be masked for key: ${key}`);
    }
}

@test:Config {}
function testMaskSensitiveValuesAllNonSensitive() {
    map<anydata> config = {
        "username": "testuser",
        "host": "localhost",
        "port": 5432,
        "database": "testdb"
    };
    
    map<anydata> masked = maskSensitiveValues(config);
    
    foreach string key in config.keys() {
        test:assertEquals(masked[key], config[key], string `Non-sensitive value should not be masked for key: ${key}`);
    }
}