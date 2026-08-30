<p align="center">
  <img src="docs/images/logo.svg" alt="simple_logger logo" width="400">
</p>

# simple_logger

**[Documentation](https://simple-eiffel.github.io/simple_logger/)** | **[GitHub](https://github.com/simple-eiffel/simple_logger)**

Enhanced logging facade for Eiffel with structured fields and JSON output.

## Overview

`simple_logger` provides a standalone `SIMPLE_LOGGER` class with:

- **Structured logging** - Key-value fields in log entries
- **JSON output** - Machine-parseable format for log aggregation
- **Child loggers** - Inherit context fields from parent
- **Enter/exit tracing** - Automatic indentation for call traces
- **Duration logging** - Built-in timer for operation timing

## Installation

1. Clone the repository
2. Set environment variable (one-time setup for all simple_* libraries): `SIMPLE_EIFFEL=D:\prod`
3. Add to your ECF:

```xml
<library name="simple_logger" location="$SIMPLE_EIFFEL/simple_logger/simple_logger.ecf"/>
```

## Dependencies

Simple Eiffel repositories are resolved beneath `$SIMPLE_EIFFEL`; EiffelTime and Eiffel JSON ship with EiffelStudio.

| Library | Purpose | Required by |
|---------|---------|-------------|
| EiffelTime | Log timestamps and timer start time | Library |
| Eiffel JSON | JSON output format and escaping | Library |
| [simple_mml](https://github.com/simple-eiffel/simple_mml) | Contract models | Library |

## Quick Start

```eiffel
local
    log: SIMPLE_LOGGER
do
    -- Basic logging
    create log.make
    log.info ("Application started")
    log.warn ("Low disk space")
    log.error ("Connection failed")

    -- Change log level
    log.set_level (log.Level_debug)
    log.debug_log ("Verbose output")
end
```

## Structured Logging

```eiffel
local
    log: SIMPLE_LOGGER
    fields: HASH_TABLE [ANY, STRING]
do
    create log.make

    -- With HASH_TABLE
    create fields.make (2)
    fields.put ("user123", "user_id")
    fields.put (42, "order_id")
    log.info_with ("Order processed", fields)
    -- Output: 2025-12-06 14:30:00 INFO Order processed user_id=user123 order_id=42

    -- With tuple array (convenience)
    log.info_fields ("Login successful", << ["user", "alice"], ["ip", "192.168.1.1"] >>)
end
```

## JSON Output

The keys `timestamp`, `level`, and `message` are reserved. Context and per-message fields with those names are ignored so they cannot replace core log metadata.

```eiffel
local
    log: SIMPLE_LOGGER
do
    create log.make
    log.set_json_output (True)
    log.info ("Server started")
    -- Output: {"timestamp":"2025-12-06T14:30:00Z","level":"info","message":"Server started"}

    log.info_fields ("Request handled", << ["method", "GET"], ["path", "/api/users"], ["status", 200] >>)
    -- Output: {"timestamp":"2025-12-06T14:30:01Z","level":"info","message":"Request handled","method":"GET","path":"/api/users","status":200}
end
```

## Child Loggers (Context Inheritance)

```eiffel
local
    log, request_log: SIMPLE_LOGGER
do
    create log.make

    -- Create child with request context
    request_log := log.child_with ("request_id", "req-abc-123")

    -- All logs from request_log include request_id
    request_log.info ("Processing request")
    -- Output: 2025-12-06 14:30:00 INFO Processing request request_id=req-abc-123

    request_log.info ("Request complete")
    -- Output: 2025-12-06 14:30:01 INFO Request complete request_id=req-abc-123
end
```

## Enter/Exit Tracing

```eiffel
local
    log: SIMPLE_LOGGER
do
    create log.make_with_level ({SIMPLE_LOGGER}.Level_debug)
    log.enter ("process_order")
        log.info ("Validating order")
        log.enter ("calculate_total")
            log.debug_log ("Applying discount")
        log.exit ("calculate_total")
    log.exit ("process_order")
    -- Output with indentation showing call hierarchy
end
```

## Duration Logging

```eiffel
local
    log: SIMPLE_LOGGER
    timer: SIMPLE_LOG_TIMER
do
    create log.make
    timer := log.start_timer

    -- Do some work
    process_data

    log.log_duration (timer, "Data processing complete")
    -- Output: 2025-12-06 14:30:01 INFO Data processing complete duration_ms=152
end
```

## File Output

```eiffel
local
    log: SIMPLE_LOGGER
do
    -- Direct to file
    create log.make_to_file ("app.log")

    -- Or add file output to existing logger
    create log.make
    log.add_file_output ("app.log")

    log.info ("This goes to console AND file")
end
```

File destinations are validated when configured. Open or write failures raise an exception instead of silently dropping messages, and each write closes its file handle before returning.

## Log Levels

| Level | Constant | Use Case |
|-------|----------|----------|
| DEBUG | `Level_debug` | Verbose debugging information |
| INFO | `Level_info` | Normal operational messages |
| WARN | `Level_warn` | Warning conditions |
| ERROR | `Level_error` | Error conditions |
| FATAL | `Level_fatal` | System failure |

## API Summary

### Creation
- `make` - Console output, INFO level
- `make_with_level (level)` - Console output, specified level
- `make_to_file (path)` - File output

### Configuration
- `set_level (level)` - Change minimum log level
- `set_json_output (enabled)` - Enable/disable JSON format
- `add_context (key, value)` - Add persistent context field
- `add_file_output (path)` - Add file output

### Logging
- `debug_log (message)`, `info (message)`, `warn (message)`, `error (message)`, `fatal (message)`
- `*_with (message, fields)` - With HASH_TABLE fields
- `info_fields (message, tuples)` - With tuple array

### Context
- `child (context)` - Create child logger with context
- `child_with (key, value)` - Convenience for single field

### Tracing
- `enter (feature_name)`, `exit (feature_name)` - Call tracing

### Timing
- `start_timer` - Create timer
- `log_duration (timer, message)` - Log with elapsed time

## Output Behavior

`simple_logger` writes console entries through standard output and file entries directly to the configured path. It does not register writers with `LOG_LOGGING_FACILITY`.

## License

MIT License - Copyright (c) 2024-2025, Larry Rix
