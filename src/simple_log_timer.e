note
	description: "Timer for measuring operation duration in logging"
	author: "Larry Rix with Claude (Anthropic)"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_LOG_TIMER

create
	make

feature {NONE} -- Initialization

	make
			-- Create and start timer.
		do
			create start_time.make_now
			start_tick := monotonic_milliseconds
		ensure
			started: start_time /= Void
		end

feature -- Access

	start_time: DATE_TIME
			-- When the timer was started.

	elapsed_ms: INTEGER_64
			-- Milliseconds elapsed since timer started.
		do
			Result := monotonic_milliseconds - start_tick
			if Result < 0 then
				Result := 0
			end
		ensure
			non_negative: Result >= 0
		end

	elapsed_seconds: REAL_64
			-- Seconds elapsed since timer started (with fractional part).
		do
			Result := elapsed_ms / 1000.0
		ensure
			non_negative: Result >= 0.0
		end

	elapsed_formatted: STRING
			-- Human-readable elapsed time string.
		local
			l_ms: INTEGER_64
		do
			l_ms := elapsed_ms
			if l_ms < 1000 then
				Result := l_ms.out + "ms"
			elseif l_ms < 60000 then
				Result := (l_ms / 1000.0).truncated_to_real.out + "s"
			else
				Result := (l_ms // 60000).out + "m " + ((l_ms \\ 60000) // 1000).out + "s"
			end
		ensure
			not_empty: not Result.is_empty
		end

feature -- Operations

	reset
			-- Reset the timer to current time.
		do
			create start_time.make_now
			start_tick := monotonic_milliseconds
		ensure
			reset: elapsed_ms >= 0
		end

feature {NONE} -- Monotonic clock

	start_tick: INTEGER_64
			-- Monotonic millisecond count captured at the last start or reset.

	monotonic_milliseconds: INTEGER_64
			-- Platform monotonic clock in milliseconds.
		external
			"C inline use %"eif_time.h%", <time.h>"
		alias
			"[
			#ifdef EIF_WINDOWS
				LARGE_INTEGER counter;
				LARGE_INTEGER frequency;
				QueryPerformanceCounter(&counter);
				QueryPerformanceFrequency(&frequency);
				return (EIF_INTEGER_64) ((counter.QuadPart / frequency.QuadPart) * 1000 +
					((counter.QuadPart % frequency.QuadPart) * 1000 / frequency.QuadPart));
			#elif defined(CLOCK_MONOTONIC)
				struct timespec value;
				if (clock_gettime(CLOCK_MONOTONIC, &value) == 0) {
					return (EIF_INTEGER_64) value.tv_sec * 1000 + value.tv_nsec / 1000000;
				}
				{
					struct timeval fallback;
					gettimeofday(&fallback, NULL);
					return (EIF_INTEGER_64) fallback.tv_sec * 1000 + fallback.tv_usec / 1000;
				}
			#else
				struct timeval value;
				gettimeofday(&value, NULL);
				return (EIF_INTEGER_64) value.tv_sec * 1000 + value.tv_usec / 1000;
			#endif
			]"
		end

invariant
	start_time_not_void: start_time /= Void

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"

end
