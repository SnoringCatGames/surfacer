#include "snore_core/time/stopwatch.h"

#include "snore_core/internal/internal_debug_utils.h"

#include <godot_cpp/classes/time.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/error_macros.hpp>

using namespace godot;

void Stopwatch::_bind_methods() {
	ClassDB::bind_method(D_METHOD("start", "metric_key"), &Stopwatch::start);
	ClassDB::bind_method(D_METHOD("stop", "metric_key"), &Stopwatch::stop);
}

void Stopwatch::start(const StringName &p_metric_key) {
	const int64_t start_time_usec = Time::get_singleton()->get_ticks_usec();
	ENSURE(!_start_times_usec.count(p_metric_key) ||
				   _start_times_usec[p_metric_key] == -1,
		   "Stopwatch already active for metric: " + p_metric_key);
	_start_times_usec[p_metric_key] = start_time_usec;
}

double Stopwatch::stop(const StringName &p_metric_key) {
	const int64_t stop_time_usec = Time::get_singleton()->get_ticks_usec();
	if (!ENSURE(_start_times_usec.count(p_metric_key),
				"No start time found for metric: " + p_metric_key)) {
		return -1.0;
	}

	const int64_t start_time_usec = _start_times_usec[p_metric_key];
	if (!ENSURE(start_time_usec >= 0,
				"Invalid start time for metric: " + p_metric_key)) {
		return -1.0;
	}

	const int64_t elapsed_time_usec = stop_time_usec - start_time_usec;
	_start_times_usec[p_metric_key] = -1;

	// Return the elapsed time in milliseconds.
	return static_cast<double>(elapsed_time_usec) / 1000.0;
}
