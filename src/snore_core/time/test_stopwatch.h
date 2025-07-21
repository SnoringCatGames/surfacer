#ifndef TEST_STOPWATCH_H
#define TEST_STOPWATCH_H

#ifdef DEBUG_ENABLED

#include "snore_core/time/stopwatch.h"

#include "snore_core/internal/test_utils.h"
#include <godot_cpp/classes/ref.hpp>

using namespace godot;

TEST(StopwatchTest, TestBasicStartStop) {
	Ref<Stopwatch> stopwatch;
	stopwatch.instantiate();

	String metric_key = "test_metric";

	// Start the stopwatch.
	stopwatch->start(metric_key);

	// Stop the stopwatch and get elapsed time.
	double elapsed_time = stopwatch->stop(metric_key);

	// Elapsed time should be non-negative and small (less than 1 second for
	// this test).
	EXPECT_GE(elapsed_time, 0.0);
	EXPECT_LT(elapsed_time, 1000.0); // Less than 1 second in milliseconds.
}

TEST(StopwatchTest, TestMultipleMetrics) {
	Ref<Stopwatch> stopwatch;
	stopwatch.instantiate();

	String metric1 = "metric1";
	String metric2 = "metric2";

	// Start both metrics.
	stopwatch->start(metric1);
	stopwatch->start(metric2);

	// Stop them in reverse order.
	double elapsed2 = stopwatch->stop(metric2);
	double elapsed1 = stopwatch->stop(metric1);

	// Both should have positive elapsed times.
	EXPECT_GE(elapsed1, 0.0);
	EXPECT_GE(elapsed2, 0.0);

	// metric1 should have taken longer (started first, stopped last).
	EXPECT_GE(elapsed1, elapsed2);
}

#endif // DEBUG_ENABLED

#endif // TEST_STOPWATCH_H
