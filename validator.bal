# Checks if a field name indicates a sensitive value
#
# + fieldName - The name of the field to check
# + return - True if the field is sensitive, false otherwise
public function isSensitiveField(string fieldName) returns boolean {
    string lowerName = fieldName.toLowerAscii();
    return lowerName.includes("password") || 
           lowerName.includes("secret") || 
           lowerName.includes("token") || 
           lowerName.includes("key") ||
           lowerName.includes("auth");
}

# Masks sensitive values in configuration for safe printing
#
# + config - The configuration map
# + return - The configuration map with sensitive values masked
public function maskSensitiveValues(map<anydata> config) returns map<anydata> {
    map<anydata> masked = {};
    
    foreach string key in config.keys() {
        anydata value = config[key];
        if isSensitiveField(key) {
            masked[key] = "***MASKED***";
        } else {
            masked[key] = value;
        }
    }
    
    return masked;
}