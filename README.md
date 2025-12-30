# dotenv - Ballerina Configuration Loader

A Ballerina library that provides a **Secrets & Configuration Loader** for backend services.

## Features

- Load configuration from **multiple sources**
- Merge them deterministically with clear precedence order
- Map them into **type-safe Ballerina records**
- Provide **clear validation errors**
- **Mask sensitive values** for safe logging
- Follow Ballerina's idiomatic style and best practices

## Installation

Add this to your `Ballerina.toml`:

```toml
[package]
org = "thambaru"
name = "your_project"
version = "0.1.0"

[[dependency]]
org = "thambaru"
name = "dotenv"
version = "0.1.0"
```

## Configuration Sources & Precedence

Configuration is loaded from multiple sources in this order (highest priority first):

1. **Environment Variables** (highest priority)
2. **`.env` file**
3. **`Config.toml`**
4. **Record default values** (lowest priority)

## Quick Start

### 1. Define Your Configuration Record

```ballerina
import thambaru/dotenv;

type DatabaseConfig record {|
    string host = "localhost";
    int port = 5432;
    string database;
    string username;
    string password;
|};
```

### 2. Load Configuration

```ballerina
public function main() returns error? {
    DatabaseConfig|dotenv:ConfigError config = dotenv:loadConfig(DatabaseConfig);
    
    if config is dotenv:ConfigError {
        return config;
    }
    
    // Use your configuration
    io:println(string `Connecting to ${config.host}:${config.port}`);
}
```

### 3. Create Configuration Files

**`.env`:**
```
DATABASE_HOST=prod-db.example.com
DATABASE_USERNAME=myapp
DATABASE_PASSWORD=secret123
```

**`Config.toml`:**
```toml
[database]
host = "dev-db.example.com"
port = 5433
database = "myapp_dev"
```

## API Reference

### Main Functions

#### `loadConfig(typedesc<anydata> targetType, LoadOptions options = {}) returns anydata|ConfigError`

Loads configuration from all sources and maps to the target record type.

**Parameters:**
- `targetType` - The record type to map configuration to
- `options` - Loading options (optional)

**Returns:** Configured record or ConfigError

#### `printSafe(anydata config)`

Prints configuration with sensitive values masked.

### Types

#### `LoadOptions`

```ballerina
type LoadOptions record {|
    string envPrefix = "";      // Prefix for environment variables
    string dotenvPath = ".env"; // Path to .env file
    boolean failFast = true;    // Stop at first validation error
    boolean allowUnknown = false; // Ignore unknown config keys
|};
```

#### `ConfigError`

```ballerina
type ConfigError distinct error;
```

## Advanced Usage

### Environment Variable Prefixes

```ballerina
LoadOptions options = {
    envPrefix: "MYAPP_"
};

DatabaseConfig|ConfigError config = dotenv:loadConfig(DatabaseConfig, options);
```

With this configuration, environment variables like `MYAPP_DATABASE_HOST` will be mapped to `databaseHost`.

### Key Name Conversion

The library automatically converts between different naming conventions:

- Environment variables: `DATABASE_HOST` → `databaseHost`
- TOML nested keys: `database.host` → `database.host`
- All keys are converted to camelCase in the final record

### Safe Printing

```ballerina
// This will mask sensitive fields like passwords, secrets, tokens, etc.
dotenv:printSafe(config);
```

Output:
```
{host: "prod-db.example.com", port: 5432, username: "myapp", password: "***MASKED***"}
```

## Error Handling

The library provides clear, actionable error messages:

```ballerina
DatabaseConfig|dotenv:ConfigError config = dotenv:loadConfig(DatabaseConfig);

if config is dotenv:ConfigError {
    io:println(config.message());
    // Example: "Missing required config field 'database'"
    return config;
}
```

## Examples

### Web Service Configuration

```ballerina
type ServerConfig record {|
    string host = "0.0.0.0";
    int port = 8080;
    string logLevel = "INFO";
    boolean enableMetrics = false;
|};

public function main() returns error? {
    ServerConfig|dotenv:ConfigError config = dotenv:loadConfig(ServerConfig);
    
    if config is dotenv:ConfigError {
        return config;
    }
    
    // Start your server with the loaded configuration
    // ...
}
```

### Database with Connection Pool

```ballerina
type DatabaseConfig record {|
    string host = "localhost";
    int port = 5432;
    string database;
    string username;
    string password;
    int maxConnections = 10;
    int connectionTimeout = 30;
|};
```

## Best Practices

1. **Always handle ConfigError** - Don't ignore configuration loading errors
2. **Use meaningful defaults** - Provide sensible defaults in your record types
3. **Group related configuration** - Use nested records for complex configurations
4. **Use printSafe for logging** - Never log raw configuration that might contain secrets
5. **Validate early** - Load and validate configuration at application startup

## License

Copyright (c) 2024, thambaru. All Rights Reserved.