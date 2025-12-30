import ballerina/test;
import ballerina/io;
import ballerina/file;
import ballerina/os;

// Test configuration record
type TestConfig record {|
    string databaseHost = "localhost";
    int databasePort = 5432;
    string databaseUsername?;
    string databasePassword?;
    string logLevel = "INFO";
|};

// Test configuration with required fields
type RequiredConfig record {|
    string requiredField;
    string optionalField = "default";
|};

@test:Config {}
function testLoadConfigFromEnvVariables() returns error? {
    // Store original file contents for restoration
    string? originalAppConfig = ();
    string? originalEnv = ();
    
    if check file:test("AppConfig.toml", file:EXISTS) {
        originalAppConfig = check io:fileReadString("AppConfig.toml");
        check file:remove("AppConfig.toml");
    }
    if check file:test(".env", file:EXISTS) {
        originalEnv = check io:fileReadString(".env");
        check file:remove(".env");
    }
    
    // Set test environment variables
    check os:setEnv("TEST_DATABASE_HOST", "testhost");
    check os:setEnv("TEST_DATABASE_PORT", "3306");
    check os:setEnv("TEST_DATABASE_USERNAME", "testuser");
    
    LoadOptions options = {
        envPrefix: "TEST_"
    };
    
    anydata|ConfigError result = loadConfig(TestConfig, options);
    test:assertTrue(result is TestConfig, "Should successfully load config from environment variables");
    
    if result is TestConfig {
        test:assertEquals(result.databaseHost, "testhost", "Database host should match env var");
        test:assertEquals(result.databasePort, 3306, "Database port should be converted to int");
        test:assertEquals(result.databaseUsername, "testuser", "Username should match env var");
    }
    
    // Clean up
    check os:unsetEnv("TEST_DATABASE_HOST");
    check os:unsetEnv("TEST_DATABASE_PORT");
    check os:unsetEnv("TEST_DATABASE_USERNAME");
    
    // Restore original files if they existed
    if originalAppConfig is string {
        check io:fileWriteString("AppConfig.toml", originalAppConfig);
    }
    if originalEnv is string {
        check io:fileWriteString(".env", originalEnv);
    }
}

@test:Config {}
function testLoadConfigFromDotenvFile() returns error? {
    // Store original file contents for restoration
    string? originalAppConfig = ();
    string? originalEnv = ();
    
    if check file:test("AppConfig.toml", file:EXISTS) {
        originalAppConfig = check io:fileReadString("AppConfig.toml");
        check file:remove("AppConfig.toml");
    }
    if check file:test(".env", file:EXISTS) {
        originalEnv = check io:fileReadString(".env");
        check file:remove(".env");
    }
    
    // Create test .env file
    string testEnvContent = string `DATABASE_HOST=envhost
DATABASE_PORT=5433
DATABASE_USERNAME=envuser
DATABASE_PASSWORD=envpass
LOG_LEVEL=DEBUG`;
    
    check io:fileWriteString("test.env", testEnvContent);
    
    LoadOptions options = {
        dotenvPath: "test.env"
    };
    
    anydata|ConfigError result = loadConfig(TestConfig, options);
    test:assertTrue(result is TestConfig, "Should successfully load config from .env file");
    
    if result is TestConfig {
        test:assertEquals(result.databaseHost, "envhost", "Database host should match .env file");
        test:assertEquals(result.databasePort, 5433, "Database port should be converted to int");
        test:assertEquals(result.databaseUsername, "envuser", "Username should match .env file");
        test:assertEquals(result.logLevel, "DEBUG", "Log level should match .env file");
    }
    
    // Clean up
    check file:remove("test.env");
    
    // Restore original files if they existed
    if originalAppConfig is string {
        check io:fileWriteString("AppConfig.toml", originalAppConfig);
    }
    if originalEnv is string {
        check io:fileWriteString(".env", originalEnv);
    }
}

@test:Config {}
function testLoadConfigFromTomlFile() returns error? {
    // Store original file contents for restoration
    string? originalAppConfig = ();
    string? originalEnv = ();
    
    if check file:test("AppConfig.toml", file:EXISTS) {
        originalAppConfig = check io:fileReadString("AppConfig.toml");
        check file:remove("AppConfig.toml");
    }
    if check file:test(".env", file:EXISTS) {
        originalEnv = check io:fileReadString(".env");
        check file:remove(".env");
    }
    
    // Create test TOML file
    string testTomlContent = string `log_level = "WARN"

[database]
host = "tomlhost"
port = 5434
username = "tomluser"`;
    
    check io:fileWriteString("TestConfig.toml", testTomlContent);
    
    // Mock the loadFromToml function by creating AppConfig.toml
    check io:fileWriteString("AppConfig.toml", testTomlContent);
    
    LoadOptions options = {};
    
    anydata|ConfigError result = loadConfig(TestConfig, options);
    test:assertTrue(result is TestConfig, "Should successfully load config from TOML file");
    
    if result is TestConfig {
        test:assertEquals(result.databaseHost, "tomlhost", "Database host should match TOML file");
        test:assertEquals(result.databasePort, 5434, "Database port should be converted to int");
        test:assertEquals(result.databaseUsername, "tomluser", "Username should match TOML file");
    }
    
    // Clean up
    check file:remove("TestConfig.toml");
    check file:remove("AppConfig.toml");
    
    // Restore original files if they existed
    if originalAppConfig is string {
        check io:fileWriteString("AppConfig.toml", originalAppConfig);
    }
    if originalEnv is string {
        check io:fileWriteString(".env", originalEnv);
    }
}

@test:Config {}
function testConfigPrecedenceOrder() returns error? {
    // Store original file contents for restoration
    string? originalAppConfig = ();
    string? originalEnv = ();
    
    if check file:test("AppConfig.toml", file:EXISTS) {
        originalAppConfig = check io:fileReadString("AppConfig.toml");
        check file:remove("AppConfig.toml");
    }
    if check file:test(".env", file:EXISTS) {
        originalEnv = check io:fileReadString(".env");
        check file:remove(".env");
    }
    
    // Create TOML file (lowest priority)
    string tomlContent = string `[database]
host = "tomlhost"
port = 5434`;
    check io:fileWriteString("AppConfig.toml", tomlContent);
    
    // Create .env file (medium priority)
    string envContent = string `DATABASE_HOST=envhost
DATABASE_PORT=5433`;
    check io:fileWriteString("test.env", envContent);
    
    // Set environment variables (highest priority)
    check os:setEnv("TEST_DATABASE_HOST", "systemhost");
    
    LoadOptions options = {
        dotenvPath: "test.env",
        envPrefix: "TEST_"
    };
    
    anydata|ConfigError result = loadConfig(TestConfig, options);
    test:assertTrue(result is TestConfig, "Should successfully merge configs with precedence");
    
    if result is TestConfig {
        // Environment variable should override .env and TOML
        test:assertEquals(result.databaseHost, "systemhost", "Env var should have highest priority");
        // .env should override TOML
        test:assertEquals(result.databasePort, 5433, ".env should override TOML");
    }
    
    // Clean up
    check os:unsetEnv("TEST_DATABASE_HOST");
    check file:remove("AppConfig.toml");
    check file:remove("test.env");
    
    // Restore original files if they existed
    if originalAppConfig is string {
        check io:fileWriteString("AppConfig.toml", originalAppConfig);
    }
    if originalEnv is string {
        check io:fileWriteString(".env", originalEnv);
    }
}

@test:Config {}
function testConfigValidationError() returns error? {
    // Store original file contents for restoration
    string? originalAppConfig = ();
    string? originalEnv = ();
    
    if check file:test("AppConfig.toml", file:EXISTS) {
        originalAppConfig = check io:fileReadString("AppConfig.toml");
        check file:remove("AppConfig.toml");
    }
    if check file:test(".env", file:EXISTS) {
        originalEnv = check io:fileReadString(".env");
        check file:remove(".env");
    }
    
    // Create .env with invalid port
    string envContent = string `DATABASE_HOST=testhost
DATABASE_PORT=invalid_port`;
    check io:fileWriteString("test.env", envContent);
    
    LoadOptions options = {
        dotenvPath: "test.env"
    };
    
    anydata|ConfigError result = loadConfig(TestConfig, options);
    test:assertTrue(result is ConfigError, "Should return error for invalid configuration");
    
    // Clean up
    check file:remove("test.env");
    
    // Restore original files if they existed
    if originalAppConfig is string {
        check io:fileWriteString("AppConfig.toml", originalAppConfig);
    }
    if originalEnv is string {
        check io:fileWriteString(".env", originalEnv);
    }
}

@test:Config {}
function testMissingRequiredField() returns error? {
    // Store original file contents for restoration
    string? originalAppConfig = ();
    string? originalEnv = ();
    
    if check file:test("AppConfig.toml", file:EXISTS) {
        originalAppConfig = check io:fileReadString("AppConfig.toml");
        check file:remove("AppConfig.toml");
    }
    if check file:test(".env", file:EXISTS) {
        originalEnv = check io:fileReadString(".env");
        check file:remove(".env");
    }
    
    // Create config without required field
    string envContent = string `OPTIONAL_FIELD=test`;
    check io:fileWriteString("test.env", envContent);
    
    LoadOptions options = {
        dotenvPath: "test.env"
    };
    
    anydata|ConfigError result = loadConfig(RequiredConfig, options);
    test:assertTrue(result is ConfigError, "Should return error for missing required field");
    
    // Clean up
    check file:remove("test.env");
    
    // Restore original files if they existed
    if originalAppConfig is string {
        check io:fileWriteString("AppConfig.toml", originalAppConfig);
    }
    if originalEnv is string {
        check io:fileWriteString(".env", originalEnv);
    }
}

@test:Config {}
function testEmptyConfiguration() returns error? {
    // Store original file contents for restoration
    string? originalAppConfig = ();
    string? originalEnv = ();
    
    if check file:test("AppConfig.toml", file:EXISTS) {
        originalAppConfig = check io:fileReadString("AppConfig.toml");
        check file:remove("AppConfig.toml");
    }
    if check file:test(".env", file:EXISTS) {
        originalEnv = check io:fileReadString(".env");
        check file:remove(".env");
    }
    
    LoadOptions options = {
        dotenvPath: "nonexistent.env",
        envPrefix: "NONEXISTENT_"
    };
    
    anydata|ConfigError result = loadConfig(TestConfig, options);
    test:assertTrue(result is TestConfig, "Should load with default values when no config found");
    
    if result is TestConfig {
        test:assertEquals(result.databaseHost, "localhost", "Should use default value");
        test:assertEquals(result.databasePort, 5432, "Should use default value");
        test:assertEquals(result.logLevel, "INFO", "Should use default value");
    }
    
    // Restore original files if they existed
    if originalAppConfig is string {
        check io:fileWriteString("AppConfig.toml", originalAppConfig);
    }
    if originalEnv is string {
        check io:fileWriteString(".env", originalEnv);
    }
}