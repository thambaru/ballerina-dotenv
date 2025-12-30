// Copyright (c) 2024, thambaru. All Rights Reserved.

# Merges multiple configuration sources according to precedence order
#
# + sources - The list of configuration sources
# + return - The merged configuration map
public function mergeConfigs(ConfigSource[] sources) returns map<anydata> {
    map<anydata> merged = {};
    
    // Process sources in priority order (lowest priority first)
    // This ensures higher priority sources override lower ones
    int maxPriority = 0;
    foreach ConfigSource 'source in sources {
        if 'source.priority > maxPriority {
            maxPriority = 'source.priority;
        }
    }
    
    // Process from priority 1 to maxPriority
    foreach int priority in 1 ... maxPriority {
        foreach ConfigSource 'source in sources {
            if 'source.priority == priority {
                foreach string key in 'source.data.keys() {
                    anydata value = 'source.data[key];
                    merged[key] = value;
                }
            }
        }
    }
    
    return merged;
}

# Creates a configuration source
#
# + name - The name of the source
# + data - The configuration data
# + priority - The priority of the source
# + return - The created configuration source
public function createConfigSource(string name, map<anydata> data, int priority) returns ConfigSource {
    return {
        name: name,
        data: data,
        priority: priority
    };
}