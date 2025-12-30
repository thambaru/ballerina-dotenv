import ballerina/io;

// Example configuration record
type AppConfig record {
    string databaseHost = "localhost";
    int databasePort = 5432;
    string databaseUsername;
    string databasePassword;
    string logLevel = "INFO";
};

public function example() returns error? {
    io:println("=== dotenv Configuration Loading Example ===");
    
    // Load configuration with a prefix to avoid system env vars
    LoadOptions options = {
        envPrefix: "DATABASE_"
    };
    
    anydata|ConfigError result = loadConfig(AppConfig, options);
    
    if result is ConfigError {
        io:println(string `Configuration error: ${result.message()}`);
        return result;
    }
    
    // Cast to the expected type
    AppConfig config = <AppConfig>result;
    
    io:println("Configuration loaded successfully!");
    io:println("Safe configuration (sensitive values masked):");
    printSafe(config);
    
    io:println(string `Database: ${config.databaseHost}:${config.databasePort}`);
    io:println(string `Log Level: ${config.logLevel}`);
}