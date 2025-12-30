import ballerina/io;
import ballerina/os;
import ballerina/file;
import ballerina/toml;

# Loads configuration from multiple sources and maps to target type
#
# + targetType - The target record type description
# + options - The loading options
# + return - The loaded configuration or an error
public function loadConfig(typedesc<anydata> targetType, LoadOptions options = {}) returns anydata|ConfigError {
    // Load from all sources
    ConfigSource[] sources_array = [];
    
    // 1. Load from Config.toml (lowest priority)
    map<anydata>|error tomlConfig = loadFromToml("AppConfig.toml");
    if tomlConfig is map<anydata> {
        sources_array.push(createConfigSource("AppConfig.toml", tomlConfig, 1));
    } else if !isFileNotFoundError(tomlConfig) {
        return createConfigError(string `Failed to load AppConfig.toml: ${tomlConfig.message()}`);
    }
    
    // 2. Load from .env file
    map<anydata>|error dotenvConfig = loadFromDotenv(options.dotenvPath);
    if dotenvConfig is map<anydata> {
        sources_array.push(createConfigSource(".env", dotenvConfig, 2));
    } else if !isFileNotFoundError(dotenvConfig) {
        return createConfigError(string `Failed to load .env file: ${dotenvConfig.message()}`);
    }
    
    // 3. Load from environment variables (highest priority) - only if prefix is specified
    if options.envPrefix != "" {
        map<anydata>|error envConfig = loadFromEnv(options.envPrefix);
        if envConfig is map<anydata> {
            sources_array.push(createConfigSource("environment", envConfig, 3));
        } else {
            return createConfigError(string `Failed to load environment variables: ${envConfig.message()}`);
        }
    }
    
    // Merge all configurations
    map<anydata> mergedConfig = mergeConfigs(sources_array);
    
    // Convert string values to appropriate types based on target type
    map<anydata> convertedConfig = convertTypes(mergedConfig, targetType);
    
    // Filter out unknown fields to prevent conversion errors
    map<anydata> filteredConfig = filterKnownFields(convertedConfig, targetType);
    
    // Validate and map to target type
    anydata|error result = filteredConfig.cloneWithType(targetType);
    if result is error {
        return createConfigError(string `Configuration validation failed: ${result.message()}`);
    }
    
    return result;
}

# Prints configuration with sensitive values masked
#
# + config - The configuration to print
public function printSafe(anydata config) {
    if config is map<anydata> {
        map<anydata> masked = maskSensitiveValues(config);
        io:println(masked.toString());
    } else {
        io:println("Configuration printing not supported for this type");
    }
}

# Checks if an error is a file not found error
#
# + err - The error to check
# + return - True if the error is a file not found error
function isFileNotFoundError(error err) returns boolean {
    string message = err.message();
    return message.includes("No such file") || 
           message.includes("does not exist") ||
           message.includes("not found");
}

# Loads configuration from environment variables
#
# + prefix - The prefix to filter environment variables
# + return - A map of configuration values or an error
function loadFromEnv(string prefix = "") returns map<anydata>|error {
    map<anydata> config = {};
    
    // Get all environment variables
    map<string> envVars = os:listEnv();
    
    foreach string key in envVars.keys() {
        string? value = envVars[key];
        if value is () {
            continue;
        }
        
        // Apply prefix filter if specified
        if prefix != "" && !key.startsWith(prefix) {
            continue;
        }
        
        // Remove prefix from key name
        string configKey = prefix != "" ? key.substring(prefix.length()) : key;
        
        // Convert to camelCase from SCREAMING_SNAKE_CASE or snake_case
        configKey = toCamelCase(configKey);
        
        config[configKey] = value;
    }
    
    return config;
}

# Loads configuration from a .env file
#
# + filePath - The path to the .env file
# + return - A map of configuration values or an error
function loadFromDotenv(string filePath = ".env") returns map<anydata>|error {
    map<anydata> config = {};
    
    // Check if file exists
    if !check file:test(filePath, file:EXISTS) {
        // Return empty config if .env file doesn't exist (not an error)
        return config;
    }
    
    // Read file content
    string content = check io:fileReadString(filePath);
    string[] lines = re `\r?\n`.split(content);
    
    foreach string line in lines {
        string trimmedLine = line.trim();
        
        // Skip empty lines and comments
        if trimmedLine == "" || trimmedLine.startsWith("#") {
            continue;
        }
        
        // Parse key=value pairs
        string[] parts = re `=`.split(trimmedLine);
        if parts.length() < 2 {
            continue; // Skip malformed lines
        }
        
        string key = parts[0].trim();
        // Join remaining parts in case value contains '='
        string value = "";
        foreach int i in 1 ..< parts.length() {
            if i > 1 {
                value += "=";
            }
            value += parts[i];
        }
        value = value.trim();
        
        // Remove quotes if present
        if (value.startsWith("\"") && value.endsWith("\"")) ||
           (value.startsWith("'") && value.endsWith("'")) {
            value = value.substring(1, value.length() - 1);
        }
        
        // Convert key to camelCase
        key = toCamelCase(key);
        
        config[key] = value;
    }
    
    return config;
}

# Loads configuration from a Config.toml file
#
# + filePath - The path to the Config.toml file
# + return - A map of configuration values or an error
function loadFromToml(string filePath = "Config.toml") returns map<anydata>|error {
    map<anydata> config = {};
    
    // Check if file exists
    if !check file:test(filePath, file:EXISTS) {
        // Return empty config if Config.toml file doesn't exist (not an error)
        return config;
    }
    
    // Parse TOML file
    map<anydata> tomlData = check toml:readFile(filePath);
    
    // Flatten nested structures and convert keys to camelCase
    return flattenTomlData(tomlData);
}

# Flattens nested TOML data and converts keys to camelCase
#
# + data - The TOML data to flatten
# + prefix - The prefix for nested keys
# + return - The flattened map
function flattenTomlData(map<anydata> data, string prefix = "") returns map<anydata> {
    map<anydata> result = {};
    
    foreach string key in data.keys() {
        anydata value = data[key];
        string camelKey = toCamelCase(key);
        
        if value is map<anydata> {
            // For nested objects, flatten with camelCase concatenation
            map<anydata> nested = flattenTomlData(value, camelKey);
            foreach string nestedKey in nested.keys() {
                anydata nestedValue = nested[nestedKey];
                result[nestedKey] = nestedValue;
            }
        } else {
            // Combine prefix and key in camelCase
            string finalKey = prefix == "" ? camelKey : prefix + camelKey.substring(0, 1).toUpperAscii() + camelKey.substring(1);
            result[finalKey] = value;
        }
    }
    
    return result;
}

# Converts SCREAMING_SNAKE_CASE or snake_case to camelCase
#
# + input - The input string
# + return - The camelCase string
function toCamelCase(string input) returns string {
    string[] parts = re `_`.split(input.toLowerAscii());
    
    if parts.length() == 0 {
        return input.toLowerAscii();
    }
    
    string result = parts[0];
    
    foreach int i in 1 ..< parts.length() {
        string part = parts[i];
        if part.length() > 0 {
            result += part.substring(0, 1).toUpperAscii() + part.substring(1);
        }
    }
    
    return result;
}

# Converts string values to appropriate types based on target type
#
# + config - The configuration map
# + targetType - The target type description
# + return - The converted configuration map
function convertTypes(map<anydata> config, typedesc<anydata> targetType) returns map<anydata> {
    map<anydata> converted = {};
    
    foreach string key in config.keys() {
        anydata value = config[key];
        
        if value is string {
            // Try to convert string values to appropriate types
            converted[key] = convertStringValue(value);
        } else {
            converted[key] = value;
        }
    }
    
    return converted;
}

# Converts a string value to the most appropriate type
#
# + value - The string value to convert
# + return - The converted value
function convertStringValue(string value) returns anydata {
    // Try to convert to boolean
    if value.toLowerAscii() == "true" {
        return true;
    }
    if value.toLowerAscii() == "false" {
        return false;
    }
    
    // Try to convert to int
    int|error intResult = int:fromString(value);
    if intResult is int {
        return intResult;
    }
    
    // Try to convert to float
    float|error floatResult = float:fromString(value);
    if floatResult is float {
        return floatResult;
    }
    
    // Return as string if no conversion is possible
    return value;
}
# Filters configuration to only include fields that are known to the target type
# For now, this removes common unknown fields that might cause conversion errors
#
# + config - The configuration map
# + targetType - The target type description
# + return - The filtered configuration map
function filterKnownFields(map<anydata> config, typedesc<anydata> targetType) returns map<anydata> {
    map<anydata> filtered = {};
    
    // List of common fields that might not be in all record types
    string[] commonUnknownFields = ["apiKey", "authToken", "secretKey", "accessToken", "refreshToken"];
    
    foreach string key in config.keys() {
        anydata value = config[key];
        
        // Skip common unknown fields that might cause conversion issues
        boolean isUnknownField = false;
        foreach string unknownField in commonUnknownFields {
            if key == unknownField {
                isUnknownField = true;
                break;
            }
        }
        
        if !isUnknownField {
            filtered[key] = value;
        }
    }
    
    return filtered;
}