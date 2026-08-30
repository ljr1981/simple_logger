note
	description: "Test application for simple_logger"
	author: "Larry Rix with Claude (Anthropic)"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run tests.
		local
			tests: LIB_TESTS
		do
			create tests
			io.put_string ("simple_logger test runner%N")
			io.put_string ("===========================%N%N")

			passed := 0
			failed := 0

			-- Basic Tests
			io.put_string ("Basic Tests%N")
			io.put_string ("-----------%N")
			run_test (agent tests.test_make_default, "test_make_default")
			run_test (agent tests.test_make_with_level, "test_make_with_level")
			run_test (agent tests.test_set_level, "test_set_level")
			run_test (agent tests.test_set_json_output, "test_set_json_output")

			-- Simple Logging Tests
			io.put_string ("%NSimple Logging Tests%N")
			io.put_string ("--------------------%N")
			run_test (agent tests.test_info_log, "test_info_log")
			run_test (agent tests.test_debug_log_filtered, "test_debug_log_filtered")
			run_test (agent tests.test_debug_log_shown, "test_debug_log_shown")
			run_test (agent tests.test_all_levels, "test_all_levels")

			-- Structured Logging Tests
			io.put_string ("%NStructured Logging Tests%N")
			io.put_string ("------------------------%N")
			run_test (agent tests.test_info_with_fields, "test_info_with_fields")
			run_test (agent tests.test_info_fields_convenience, "test_info_fields_convenience")

			-- JSON Output Tests
			io.put_string ("%NJSON Output Tests%N")
			io.put_string ("-----------------%N")
			run_test (agent tests.test_json_output_format, "test_json_output_format")
			run_test (agent tests.test_json_with_fields, "test_json_with_fields")
			run_test (agent tests.test_json_metadata_is_reserved, "test_json_metadata_is_reserved")

			-- Child Logger Tests
			io.put_string ("%NChild Logger Tests%N")
			io.put_string ("------------------%N")
			run_test (agent tests.test_child_logger, "test_child_logger")
			run_test (agent tests.test_child_with_convenience, "test_child_with_convenience")
			run_test (agent tests.test_child_file_output, "test_child_file_output")
			run_test (agent tests.test_context_propagation, "test_context_propagation")

			-- Tracing Tests
			io.put_string ("%NTracing Tests%N")
			io.put_string ("-------------%N")
			run_test (agent tests.test_enter_exit, "test_enter_exit")

			-- Timer Tests
			io.put_string ("%NTimer Tests%N")
			io.put_string ("-----------%N")
			run_test (agent tests.test_timer_creation, "test_timer_creation")
			run_test (agent tests.test_timer_elapsed, "test_timer_elapsed")
			run_test (agent tests.test_log_duration, "test_log_duration")
			run_test (agent tests.test_timer_formatted, "test_timer_formatted")
			run_test (agent tests.test_timer_millisecond_resolution, "test_timer_millisecond_resolution")

			-- File Output Tests
			io.put_string ("%NFile Output Tests%N")
			io.put_string ("-----------------%N")
			run_test (agent tests.test_file_output, "test_file_output")
			run_test (agent tests.test_add_file_output, "test_add_file_output")
			run_test (agent tests.test_file_setup_failure, "test_file_setup_failure")

			io.put_string ("%N===========================%N")
			io.put_string ("Results: " + passed.out + " passed, " + failed.out + " failed%N")

			if failed > 0 then
				io.put_string ("TESTS FAILED%N")
				(create {EXCEPTIONS}).die (1)
			else
				io.put_string ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Implementation

	passed: INTEGER
	failed: INTEGER

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run a single test and update counters.
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				io.put_string ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			io.put_string ("  FAIL: " + a_name + "%N")
			failed := failed + 1
			l_retried := True
			retry
		end

end
