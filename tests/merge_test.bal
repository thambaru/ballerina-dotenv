import ballerina/test;

@test:Config {}
function testMergeConfigsEmptyArray() {
    ConfigSource[] sources = [];
    map<anydata> result = mergeConfigs(sources);
    
    test:assertEquals(result.length(), 0, "Empty sources should result in empty config");
}

@test:Config {}
function testMergeConfigsSingleSource() {
    map<anydata> data = {
        "host": "localhost",
        "port": 5432
    };
    
    ConfigSource[] sources = [createConfigSource("test", data, 1)];
    map<anydata> result = mergeConfigs(sources);
    
    test:assertEquals(result["host"], "localhost", "Single source data should be preserved");
    test:assertEquals(result["port"], 5432, "Single source data should be preserved");
}

@test:Config {}
function testMergeConfigsMultipleSources() {
    // Lower priority source
    map<anydata> lowPriorityData = {
        "host": "localhost",
        "port": 5432,
        "username": "defaultuser"
    };
    
    // Higher priority source
    map<anydata> highPriorityData = {
        "host": "production.db.com",
        "port": 3306
        // username not specified, should use default
    };
    
    ConfigSource[] sources = [
        createConfigSource("default", lowPriorityData, 1),
        createConfigSource("production", highPriorityData, 2)
    ];
    
    map<anydata> result = mergeConfigs(sources);
    
    // Higher priority values should override
    test:assertEquals(result["host"], "production.db.com", "Higher priority should override host");
    test:assertEquals(result["port"], 3306, "Higher priority should override port");
    
    // Lower priority values should be preserved when not overridden
    test:assertEquals(result["username"], "defaultuser", "Lower priority username should be preserved");
}

@test:Config {}
function testMergeConfigsThreeSources() {
    // TOML config (lowest priority)
    map<anydata> tomlData = {
        "host": "localhost",
        "port": 5432,
        "username": "tomluser",
        "timeout": 30
    };
    
    // .env config (medium priority)
    map<anydata> envData = {
        "host": "env.host.com",
        "port": 3306,
        "password": "envpass"
    };
    
    // Environment variables (highest priority)
    map<anydata> sysEnvData = {
        "host": "prod.host.com",
        "username": "produser"
    };
    
    ConfigSource[] sources = [
        createConfigSource("toml", tomlData, 1),
        createConfigSource("env", envData, 2),
        createConfigSource("sysenv", sysEnvData, 3)
    ];
    
    map<anydata> result = mergeConfigs(sources);
    
    // Highest priority (sysenv) should win
    test:assertEquals(result["host"], "prod.host.com", "System env should have highest priority");
    test:assertEquals(result["username"], "produser", "System env should override username");
    
    // Medium priority (.env) should override low priority
    test:assertEquals(result["port"], 3306, ".env should override TOML port");
    test:assertEquals(result["password"], "envpass", ".env password should be preserved");
    
    // Lowest priority should be preserved when not overridden
    test:assertEquals(result["timeout"], 30, "TOML timeout should be preserved");
}

@test:Config {}
function testCreateConfigSource() {
    map<anydata> data = {
        "key1": "value1",
        "key2": 42
    };
    
    ConfigSource 'source = createConfigSource("test-source", data, 5);
    
    test:assertEquals('source.name, "test-source", "Source name should match");
    test:assertEquals('source.priority, 5, "Source priority should match");
    test:assertEquals('source.data["key1"], "value1", "Source data should be preserved");
    test:assertEquals('source.data["key2"], 42, "Source data should be preserved");
}

@test:Config {}
function testMergeConfigsOverwriteAllValues() {
    map<anydata> lowData = {
        "a": "low_a",
        "b": "low_b",
        "c": "low_c"
    };
    
    map<anydata> highData = {
        "a": "high_a",
        "b": "high_b",
        "c": "high_c"
    };
    
    ConfigSource[] sources = [
        createConfigSource("low", lowData, 1),
        createConfigSource("high", highData, 2)
    ];
    
    map<anydata> result = mergeConfigs(sources);
    
    test:assertEquals(result["a"], "high_a", "All values should be overwritten by higher priority");
    test:assertEquals(result["b"], "high_b", "All values should be overwritten by higher priority");
    test:assertEquals(result["c"], "high_c", "All values should be overwritten by higher priority");
}

@test:Config {}
function testMergeConfigsWithNullValues() {
    map<anydata> data1 = {
        "key1": "value1",
        "key2": ()
    };
    
    map<anydata> data2 = {
        "key2": "value2",
        "key3": ()
    };
    
    ConfigSource[] sources = [
        createConfigSource("source1", data1, 1),
        createConfigSource("source2", data2, 2)
    ];
    
    map<anydata> result = mergeConfigs(sources);
    
    test:assertEquals(result["key1"], "value1", "Non-null value should be preserved");
    test:assertEquals(result["key2"], "value2", "Higher priority should override null");
    test:assertEquals(result["key3"], (), "Null value should be preserved when no override");
}