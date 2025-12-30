## Project Overview

This repository contains a **Ballerina library** that provides a **Secrets & Configuration Loader** for backend services.

The goal of this library is to:

* Load configuration from **multiple sources**
* Merge them deterministically
* Map them into **type-safe Ballerina records**
* Provide **clear validation errors**
* Follow Ballerina’s idiomatic style and best practices

This library is intended to be published to **Ballerina Central**.

---

## Package Name

**Working name:** `dotenv`
**Module path:** `thambaru/dotenv`

---

## Core Design Principles

When generating or modifying code, always follow these principles:

1. **Type safety over convenience**
2. **Fail fast on invalid or missing config**
3. **Predictable override order**
4. **Minimal dependencies**
5. **Extensible architecture**
6. **Production-first behavior**

Avoid adding unnecessary abstractions or reflection-heavy logic.

---

## Supported Configuration Sources (v1)

The following sources MUST be supported:

1. **Environment variables** (highest priority)
2. **`.env` file**
3. **`Config.toml`**
4. **Defaults defined in user record types** (lowest priority)

Later cloud providers (AWS, Vault, Kubernetes) are out of scope unless explicitly requested.

---

## Configuration Precedence Order

Always merge configuration values in this order (highest overrides lowest):

```
Environment Variables
↓
.env file
↓
Config.toml
↓
Record default values
```

This behavior must be documented and enforced consistently.

---

## Public API Guidelines

### Primary Entry Point

The main API should be a single function:

```ballerina
public function loadConfig<T>(LoadOptions options = {})
    returns T|ConfigError;
```

* Uses generics to infer the target record type
* Automatically maps values
* Validates required fields
* Applies defaults

---

### LoadOptions Record

```ballerina
public type LoadOptions record {
    string envPrefix = "";
    string dotenvPath = ".env";
    boolean failFast = true;
    boolean allowUnknown = false;
};
```

* `envPrefix`: Prefix for env vars (e.g. `APP_`)
* `dotenvPath`: Path to `.env`
* `failFast`: Stop at first validation error
* `allowUnknown`: Ignore unknown config keys if true

---

## Error Handling Rules

### ConfigError Type

All errors must be wrapped in a domain-specific error:

```ballerina
public type ConfigError distinct error;
```

Error messages should be:

* Human-readable
* Actionable
* Deterministic

Examples:

* `Missing required config field 'dbPassword'`
* `Invalid type for field 'dbPort'. Expected int, found string`

Do **not** expose internal stack traces to users.

---

## Secrets Handling Rules

* Treat values with names like `password`, `secret`, `token`, `key` as **sensitive**
* Never log secret values in plain text
* Provide a helper to print masked configs for debugging

Example:

```ballerina
dotenv:printSafe(config);
```

---

## Internal Architecture Guidelines

The package should follow a modular structure:

```
dotenv/
 ├── loader.bal
 ├── merge.bal
 ├── validator.bal
 ├── errors.bal
 ├── types.bal
 └── sources/
     ├── env.bal
     ├── dotenv.bal
     └── toml.bal
```

Each source module must:

* Return `map<anydata>`
* Perform no validation
* Never panic

---

## Mapping & Validation Rules

* Field names are matched case-insensitively
* Snake_case and SCREAMING_SNAKE_CASE env vars must map to camelCase fields
* Missing non-defaulted fields must cause an error
* Default values defined in record types must be respected

Avoid using reflection unless absolutely required.

---

## Testing Expectations

All generated code should be testable.

Testing guidelines:

* Unit tests for each source loader
* Merge precedence tests
* Validation error tests
* Edge cases (missing fields, type mismatch, empty configs)

Prefer **small focused tests** over large integration tests.

---

## Documentation Expectations

Every public function and type must include:

* Ballerina doc comments
* Usage examples

README examples must be:

* Copy-paste runnable
* Minimal
* Realistic

---

## Style Guidelines

* Follow official Ballerina formatting
* Use explicit types
* Prefer immutability
* Avoid magic strings
* Keep functions small and focused

---

## Out of Scope (Unless Explicitly Requested)

Do NOT generate:

* Cloud provider SDK integrations
* Runtime hot reloading
* File watchers
* CLI tools
* YAML or JSON config support
* Framework-specific bindings

---

## Success Criteria

Code generated for this repository should:

* Compile without warnings
* Be suitable for Ballerina Central publication
* Be understandable by mid-level Ballerina developers
* Be production-ready by default

---

## Final Reminder

This is a **library**, not an application.

Prioritize:

* Stability
* Clarity
* Predictability

Over:

* Cleverness
* Overengineering
* Hidden magic