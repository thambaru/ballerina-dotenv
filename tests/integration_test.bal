import ballerina/test;
import ballerina/io;
import ballerina/file;
import ballerina/os;

// Integration test configuration
type IntegrationConfig record {|
    string databaseHost = "localhost";
    int databasePort = 5432;
    string databaseUsername?;
    string databasePassword?;
    string logLevel = "INFO";
    boolean enableSsl = false;
    int connectionTimeout = 30;
|};

@test:Config {}
function testCompleteConfigurationFlow() returns error? {
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
    
    // Setup: Create all configuration sources
    
    // 1. Create TOML configuration (lowest priority)
    string tomlContent = string `log_level = "DEBUG"
enable_ssl = true
connection_timeout = 60

[database]
host = "toml-host"
port = 5433
username = "toml-user"`;
    
    check io:fileWriteString("AppConfig.toml", tomlContent);
    
    // 2. Create .env file (medium priority)
    string envContent = string `DATABASE_HOST=env-host
DATABASE_PORT=3306
DATABASE_PASSWORD=env-secret
LOG_LEVEL=WARN
ENABLE_SSL=false`;
    
    check io:fileWriteString("integration.env", envContent);
    
    // 3. Set environment variables (highest priority)
    check os:setEnv("INTEGRATION_DATABASE_HOST", "system-host");
    check os:setEnv("INTEGRATION_DATABASE_USERNAME", "system-user");
    check os:setEnv("INTEGRATION_LOG_LEVEL", "ERROR");
    
    // Load configuration with all sources
    LoadOptions options = {
        dotenvPath: "integration.env",
        envPrefix: "INTEGRATION_"
    };
    
    anydata|ConfigError result = loadConfig(IntegrationConfig, options);
    test:assertTrue(result is IntegrationConfig, "Should successfully load complete configuration");
    
    if result is IntegrationConfig {
        // Verify precedence: system env > .env > TOML > defaults
        test:assertEquals(result.databaseHost, "system-host", "System env should override all");
        test:assertEquals(result.databaseUsername, "system-user", "System env username should be used");
        test:assertEquals(result.logLevel, "ERROR", "System env log level should override");
        
        test:assertEquals(result.databasePort, 3306, ".env should override TOML port");
        test:assertEquals(result.databasePassword, "env-secret", ".env password should be used");
        test:assertEquals(result.enableSsl, false, ".env should override TOML SSL setting");
        
        test:assertEquals(result.connectionTimeout, 60, "TOML timeout should be used when not overridden");
    }
    
    // Test safe printing
    if result is IntegrationConfig {
        // This should mask the password
        printSafe(result);
    }
    
    // Cleanup
    check os:unsetEnv("INTEGRATION_DATABASE_HOST");
    check os:unsetEnv("INTEGRATION_DATABASE_USERNAME");
    check os:unsetEnv("INTEGRATION_LOG_LEVEL");
    check file:remove("AppConfig.toml");
    check file:remove("integration.env");
    
    // Restore original files if they existed
    if originalAppConfig is string {
        check io:fileWriteString("AppConfig.toml", originalAppConfig);
    }
    if originalEnv is string {
        check io:fileWriteString(".env", originalEnv);
    }
}

@test:Config {}
function testConfigurationWithOnlyDefaults() returns error? {
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
    
    // Test loading configuration when no external sources are available
    LoadOptions options = {
        dotenvPath: "nonexistent.env",
        envPrefix: "NONEXISTENT_"
    };
    
    anydata|ConfigError result = loadConfig(IntegrationConfig, options);
    test:assertTrue(result is IntegrationConfig, "Should load with defaults when no sources available");
    
    if result is IntegrationConfig {
        test:assertEquals(result.databaseHost, "localhost", "Should use default host");
        test:assertEquals(result.databasePort, 5432, "Should use default port");
        test:assertEquals(result.logLevel, "INFO", "Should use default log level");
        test:assertEquals(result.enableSsl, false, "Should use default SSL setting");
        test:assertEquals(result.connectionTimeout, 30, "Should use default timeout");
        test:assertTrue(result.databaseUsername is (), "Optional field should be nil");
        test:assertTrue(result.databasePassword is (), "Optional field should be nil");
    }
    
    // Restore original files if they existed
    if originalAppConfig is string {
        check io:fileWriteString("AppConfig.toml", originalAppConfig);
    }
    if originalEnv is string {
        check io:fileWriteString(".env", originalEnv);
    }
}

@test:Config {}
function testConfigurationErrorHandling() returns error? {
    // Create .env with invalid data type
    string invalidEnvContent = string `DATABASE_HOST=valid-host
DATABASE_PORT=not-a-number
LOG_LEVEL=INFO`;
    
    check io:fileWriteString("invalid.env", invalidEnvContent);
    
    LoadOptions options = {
        dotenvPath: "invalid.env"
    };
    
    anydata|ConfigError result = loadConfig(IntegrationConfig, options);
    test:assertTrue(result is ConfigError, "Should return error for invalid configuration");
    
    if result is ConfigError {
        test:assertTrue(result.message().includes("validation failed"), "Error should mention validation failure");
    }
    
    // Cleanup
    check file:remove("invalid.env");
}

@test:Config {}
function testSensitiveDataMasking() returns error? {
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
    
    // Create configuration with sensitive data
    string envContent = string `DATABASE_HOST=localhost
DATABASE_USERNAME=testuser
DATABASE_PASSWORD=supersecret123
API_KEY=abc123xyz789
AUTH_TOKEN=bearer_token_here
LOG_LEVEL=INFO`;
    
    check io:fileWriteString("sensitive.env", envContent);
    
    LoadOptions options = {
        dotenvPath: "sensitive.env"
    };
    
    anydata|ConfigError result = loadConfig(IntegrationConfig, options);
    test:assertTrue(result is IntegrationConfig, "Should load configuration with sensitive data");
    
    if result is IntegrationConfig {
        // Verify that sensitive data is properly loaded (not masked in the actual config)
        test:assertEquals(result.databasePassword, "supersecret123", "Actual config should contain real password");
        
        // Test that masking works for display
        map<anydata> configMap = {
            "databaseHost": result.databaseHost,
            "databasePassword": result.databasePassword,
            "logLevel": result.logLevel
        };
        
        map<anydata> masked = maskSensitiveValues(configMap);
        test:assertEquals(masked["databaseHost"], "localhost", "Non-sensitive data should not be masked");
        test:assertEquals(masked["databasePassword"], "***MASKED***", "Sensitive data should be masked");
        test:assertEquals(masked["logLevel"], "INFO", "Non-sensitive data should not be masked");
    }
    
    // Cleanup
    check file:remove("sensitive.env");
    
    // Restore original files if they existed
    if originalAppConfig is string {
        check io:fileWriteString("AppConfig.toml", originalAppConfig);
    }
    if originalEnv is string {
        check io:fileWriteString(".env", originalEnv);
    }
}

@test:Config {}
function testCamelCaseConversion() returns error? {
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
    
    // Test that various naming conventions are properly converted to camelCase
    string envContent = string `DATABASE_HOST=localhost
database_port=5432
Database_Username=testuser
LOG_LEVEL=INFO
api_key=secret123
AUTH_TOKEN=token456`;
    
    check io:fileWriteString("camelcase.env", envContent);
    
    LoadOptions options = {
        dotenvPath: "camelcase.env"
    };
    
    anydata|ConfigError result = loadConfig(IntegrationConfig, options);
    test:assertTrue(result is IntegrationConfig, "Should handle various naming conventions");
    
    if result is IntegrationConfig {
        test:assertEquals(result.databaseHost, "localhost", "SCREAMING_SNAKE_CASE should convert to camelCase");
        test:assertEquals(result.databasePort, 5432, "snake_case should convert to camelCase");
        test:assertEquals(result.databaseUsername, "testuser", "Mixed_Case should convert to camelCase");
        test:assertEquals(result.logLevel, "INFO", "SCREAMING_SNAKE_CASE should convert to camelCase");
    }
    
    // Cleanup
    check file:remove("camelcase.env");
    
    // Restore original files if they existed
    if originalAppConfig is string {
        check io:fileWriteString("AppConfig.toml", originalAppConfig);
    }
    if originalEnv is string {
        check io:fileWriteString(".env", originalEnv);
    }
}