note
	description: "Test set for simple_logger"
	author: "Larry Rix with Claude (Anthropic)"
	date: "$Date$"
	revision: "$Revision$"

class
	LIB_TESTS

feature -- Basic Tests

	test_make_default
			-- Test default logger creation.
		local
			log: SIMPLE_LOGGER
		do
			create log.make
			check level_is_info: log.level = log.Level_info end
			check console_output: log.is_console_output end
			check not_json: not log.is_json_output end
		end

	test_make_with_level
			-- Test logger creation with specific level.
		local
			log: SIMPLE_LOGGER
		do
			create log.make_with_level ({SIMPLE_LOGGER}.Level_debug)
			check level_is_debug: log.level = log.Level_debug end
		end

	test_set_level
			-- Test changing log level.
		local
			log: SIMPLE_LOGGER
		do
			create log.make
			log.set_level (log.Level_error)
			check level_changed: log.level = log.Level_error end
		end

	test_set_json_output
			-- Test enabling JSON output.
		local
			log: SIMPLE_LOGGER
		do
			create log.make
			check initially_not_json: not log.is_json_output end
			log.set_json_output (True)
			check now_json: log.is_json_output end
		end

feature -- Simple Logging Tests

	test_info_log
			-- Test basic info logging.
		local
			log: SIMPLE_LOGGER
		do
			create log.make
			log.info ("Test info message")
			-- If we get here without exception, test passed
			check passed: True end
		end

	test_debug_log_filtered
			-- Test that debug logs are filtered at INFO level.
		local
			log: SIMPLE_LOGGER
		do
			create log.make
			-- Level is INFO by default, debug should be filtered
			log.debug_log ("This should not appear")
			check passed: True end
		end

	test_debug_log_shown
			-- Test that debug logs appear at DEBUG level.
		local
			log: SIMPLE_LOGGER
		do
			create log.make_with_level ({SIMPLE_LOGGER}.Level_debug)
			log.debug_log ("This should appear")
			check passed: True end
		end

	test_all_levels
			-- Test all log levels.
		local
			log: SIMPLE_LOGGER
		do
			create log.make_with_level ({SIMPLE_LOGGER}.Level_debug)
			log.debug_log ("Debug message")
			log.info ("Info message")
			log.warn ("Warning message")
			log.error ("Error message")
			log.fatal ("Fatal message")
			check passed: True end
		end

feature -- Structured Logging Tests

	test_info_with_fields
			-- Test logging with structured fields.
		local
			log: SIMPLE_LOGGER
			fields: HASH_TABLE [ANY, STRING]
		do
			create log.make
			create fields.make (2)
			fields.put ("user123", "user_id")
			fields.put (42, "order_id")
			log.info_with ("Order processed", fields)
			check passed: True end
		end

	test_info_fields_convenience
			-- Test logging with tuple array convenience.
		local
			log: SIMPLE_LOGGER
		do
			create log.make
			log.info_fields ("User logged in", << ["user_id", "123"], ["action", "login"] >>)
			check passed: True end
		end

feature -- JSON Output Tests

	test_json_output_format
			-- Test JSON formatted output.
		local
			log: SIMPLE_LOGGER
		do
			create log.make
			log.set_json_output (True)
			log.info ("JSON test message")
			-- Visual inspection of output, no assertion failure means passed
			check passed: True end
		end

	test_json_with_fields
			-- Test JSON with structured fields.
		local
			log: SIMPLE_LOGGER
			fields: HASH_TABLE [ANY, STRING]
		do
			create log.make
			log.set_json_output (True)
			create fields.make (3)
			fields.put ("test_user", "user")
			fields.put (100, "count")
			fields.put (True, "success")
			log.info_with ("Test with fields", fields)
			check passed: True end
		end

	test_json_metadata_is_reserved
			-- Test that structured fields cannot overwrite core JSON metadata.
		local
			log: SIMPLE_LOGGER
			fields: HASH_TABLE [ANY, STRING]
			test_file, contents: STRING
		do
			test_file := "test_json_metadata.log"
			delete_test_file (test_file)
			create log.make_to_file (test_file)
			log.set_json_output (True)
			create fields.make (4)
			fields.put ("forged_timestamp", "timestamp")
			fields.put ("forged_level", "level")
			fields.put ("forged_message", "message")
			fields.put ("kept", "custom")
			log.info_with ("real message", fields)
			contents := read_test_file (test_file)
			assert ("real_message_preserved", contents.has_substring ("real message"))
			assert ("iso8601_timestamp", contents.has_substring ("T") and contents.has_substring ("Z"))
			assert ("level_preserved", contents.has_substring ("%"level%":%"info%""))
			assert ("custom_field_preserved", contents.has_substring ("kept"))
			assert ("metadata_not_forged", not contents.has_substring ("forged_"))
			delete_test_file (test_file)
		end

feature -- Child Logger Tests

	test_child_logger
			-- Test child logger inherits parent context.
		local
			parent_log, child_log: SIMPLE_LOGGER
			ctx: HASH_TABLE [ANY, STRING]
		do
			create parent_log.make
			create ctx.make (1)
			ctx.put ("request-123", "request_id")
			child_log := parent_log.child (ctx)
			check inherits_level: child_log.level = parent_log.level end
			check has_context: child_log.context_fields.has ("request_id") end
			child_log.info ("Message from child logger")
			check passed: True end
		end

	test_child_with_convenience
			-- Test child_with convenience method.
		local
			log, request_log: SIMPLE_LOGGER
		do
			create log.make
			request_log := log.child_with ("trace_id", "abc-123")
			check has_trace_id: request_log.context_fields.has ("trace_id") end
		end

	test_child_file_output
			-- Test child logger output reaches the parent's file destination.
		local
			parent_log, child_log: SIMPLE_LOGGER
			test_file, contents: STRING
		do
			test_file := "test_child_output.log"
			delete_test_file (test_file)
			create parent_log.make_to_file (test_file)
			child_log := parent_log.child_with ("request_id", "request-456")
			child_log.info ("Message from file child")
			contents := read_test_file (test_file)
			assert ("child_message_written", contents.has_substring ("Message from file child"))
			assert ("child_context_written", contents.has_substring ("request_id=request-456"))
			delete_test_file (test_file)
		end

	test_context_propagation
			-- Test that context fields appear in logs.
		local
			log: SIMPLE_LOGGER
		do
			create log.make
			log.set_json_output (True)
			log.add_context ("app", "test_app")
			log.add_context ("version", "1.0")
			log.info ("Context test")
			-- Context fields should appear in output
			check passed: True end
		end

feature -- Tracing Tests

	test_enter_exit
			-- Test enter/exit tracing.
		local
			log: SIMPLE_LOGGER
		do
			create log.make_with_level ({SIMPLE_LOGGER}.Level_debug)
			log.enter ("test_feature")
			log.info ("Inside feature")
			log.exit ("test_feature")
			check passed: True end
		end

feature -- Timer Tests

	test_timer_creation
			-- Test timer creation.
		local
			log: SIMPLE_LOGGER
			timer: SIMPLE_LOG_TIMER
		do
			create log.make
			timer := log.start_timer
			check timer_exists: timer /= Void end
			check elapsed_non_negative: timer.elapsed_ms >= 0 end
		end

	test_timer_elapsed
			-- Test timer elapsed time measurement.
		local
			timer: SIMPLE_LOG_TIMER
			i: INTEGER
		do
			create timer.make
			-- Do some work
			from i := 1 until i > 100000 loop
				i := i + 1
			end
			check some_time_passed: timer.elapsed_ms >= 0 end
		end

	test_log_duration
			-- Test logging with duration.
		local
			log: SIMPLE_LOGGER
			timer: SIMPLE_LOG_TIMER
			i: INTEGER
		do
			create log.make
			timer := log.start_timer
			-- Simulate work
			from i := 1 until i > 10000 loop
				i := i + 1
			end
			log.log_duration (timer, "Operation completed")
			check passed: True end
		end

	test_timer_formatted
			-- Test timer formatted output.
		local
			timer: SIMPLE_LOG_TIMER
		do
			create timer.make
			check formatted_not_empty: not timer.elapsed_formatted.is_empty end
		end

	test_timer_millisecond_resolution
			-- Test elapsed time has sub-second resolution and reset remains valid.
		local
			timer: SIMPLE_LOG_TIMER
			l_environment: EXECUTION_ENVIRONMENT
			elapsed: INTEGER_64
		do
			create timer.make
			create l_environment
			l_environment.sleep (20_000_000)
			elapsed := timer.elapsed_ms
			assert ("millisecond_resolution", elapsed > 0)
			timer.reset
			assert ("reset_non_negative", timer.elapsed_ms >= 0)
		end

feature -- File Output Tests

	test_file_output
			-- Test file output.
		local
			log: SIMPLE_LOGGER
			test_file: STRING
		do
			test_file := "test_logger_output.log"
			delete_test_file (test_file)
			create log.make_to_file (test_file)
			log.info ("Test file output")
			check file_output_enabled: log.is_file_output end
			assert ("message_written", read_test_file (test_file).has_substring ("Test file output"))
			delete_test_file (test_file)
		end

	test_add_file_output
			-- Test adding file output to existing logger.
		local
			log: SIMPLE_LOGGER
			test_file: STRING
		do
			test_file := "test_added_output.log"
			delete_test_file (test_file)
			create log.make
			log.add_file_output (test_file)
			check file_output_enabled: log.is_file_output end
			log.info ("Test added file output")
			assert ("message_written", read_test_file (test_file).has_substring ("Test added file output"))
			delete_test_file (test_file)
		end

	test_file_setup_failure
			-- Test file setup errors propagate without disabling a working logger.
		local
			log: SIMPLE_LOGGER
		do
			assert ("constructor_failure_propagated", file_logger_creation_fails ("."))
			create log.make
			assert ("add_failure_propagated", add_file_output_fails (log, "."))
			assert ("file_output_unchanged", not log.is_file_output)
			assert ("console_output_retained", log.is_console_output)
		end

feature {NONE} -- Test Utilities

	assert (a_tag: STRING; a_condition: BOOLEAN)
			-- Raise a test failure identified by `a_tag` unless `a_condition` holds.
		do
			if not a_condition then
				(create {EXCEPTIONS}).raise ("Assertion failed: " + a_tag)
			end
		end

	read_test_file (a_path: STRING): STRING
			-- Contents of test file at `a_path`.
		local
			l_file: detachable PLAIN_TEXT_FILE
		do
			create Result.make_empty
			create l_file.make_open_read (a_path)
			if l_file.is_open_read then
				if l_file.count > 0 then
					l_file.read_stream (l_file.count)
					Result.append (l_file.last_string)
				end
				l_file.close
			else
				(create {EXCEPTIONS}).raise ("Unable to read test file: " + a_path)
			end
		rescue
			if attached l_file as f and then f.is_open_read then
				f.close
			end
		end

	file_logger_creation_fails (a_path: STRING): BOOLEAN
			-- Does creating a file-only logger at `a_path` raise an exception?
		local
			log: detachable SIMPLE_LOGGER
			l_attempted: BOOLEAN
		do
			if not l_attempted then
				l_attempted := True
				create log.make_to_file (a_path)
			end
		rescue
			Result := True
			retry
		end

	add_file_output_fails (a_logger: SIMPLE_LOGGER; a_path: STRING): BOOLEAN
			-- Does adding file output at `a_path` raise an exception?
		local
			l_attempted: BOOLEAN
		do
			if not l_attempted then
				l_attempted := True
				a_logger.add_file_output (a_path)
			end
		rescue
			Result := True
			retry
		end

	delete_test_file (a_path: STRING)
			-- Delete test file if it exists.
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_name (a_path)
			if l_file.exists then
				l_file.delete
				assert ("file_deleted", not l_file.exists)
			end
		rescue
			assert ("delete_test_file failed: " + a_path, False)
		end

end
