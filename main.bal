import ballerina/io;

public function main() returns error? {
    io:println("dotenv library loaded successfully");
    
    // Run the example
    error? result = example();
    if result is error {
        io:println(string `Example failed: ${result.message()}`);
        return result;
    }
}