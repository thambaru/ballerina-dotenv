// Copyright (c) 2024, thambaru. All Rights Reserved.

# Configuration loading options
#
# + envPrefix - Prefix for environment variables (e.g. `APP_`)
# + dotenvPath - Path to the .env file
# + failFast - Whether to fail on the first error
# + allowUnknown - Whether to allow unknown configuration fields
public type LoadOptions record {|
    string envPrefix = "";
    string dotenvPath = ".env";
    boolean failFast = true;
    boolean allowUnknown = false;
|};

# Internal configuration source data
#
# + name - Name of the source
# + data - Configuration data
# + priority - Priority of the source
public type ConfigSource record {|
    string name;
    map<anydata> data;
    int priority;
|};