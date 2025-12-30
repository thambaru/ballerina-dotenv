// Copyright (c) 2024, thambaru. All Rights Reserved.

# Configuration loading options
public type LoadOptions record {|
    string envPrefix = "";
    string dotenvPath = ".env";
    boolean failFast = true;
    boolean allowUnknown = false;
|};

# Internal configuration source data
public type ConfigSource record {|
    string name;
    map<anydata> data;
    int priority;
|};