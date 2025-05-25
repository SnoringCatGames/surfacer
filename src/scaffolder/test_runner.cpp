#include "scaffolder/test_runner.h"

#ifdef DEBUG_ENABLED

namespace godot {

bool TestRunnerFocusable::should_run() const {
	return is_focused || (!runner->are_any_tests_focused && !is_excluded);
}

void TestRunnerSpec::run() {
	runner->is_spec_running = true;
	runner->is_current_spec_passing = true;

	callback();

	if (!runner->is_current_spec_passing) {
		// Print the TestRunnerSuite path, if we aren't already printing all
		// results.
		if (!runner->print_passing_units) {
			godot::UtilityFunctions::print_rich(
					godot::vformat(
							"%s [color=white]>[/color]",
							TestRunnerSuite->get_combined_rich_description()));
		}
		godot::UtilityFunctions::print_rich(
				godot::vformat(
						"%s: [color=purple]%s[/color]", _X_MARK,
						description.c_str()));
	} else if (runner->print_passing_units) {
		godot::UtilityFunctions::print_rich(
				godot::vformat(
						"%s: [color=purple]%s[/color]", _CHECKMARK,
						description.c_str()));
	}

	runner->is_spec_running = false;
}

godot::String TestRunnerSuite::get_combined_rich_description() const {
	godot::String combined_description =
			godot::vformat("[color=cyan]%s[/color]", description.c_str());
	const TestRunnerSuite *current_suite = parent_suite;
	while (current_suite) {
		// Skip the empty root description.
		if (!current_suite->description.empty()) {
			combined_description = godot::vformat(
					"[color=dark_slate_gray]%s[/color] "
					"[color=white]>[/color] "
					"%s",
					current_suite->description.c_str(), combined_description);
		}
		current_suite = current_suite->parent_suite;
	}
	return combined_description;
}

void TestRunnerSuite::run() {
	runner->running_suite_count++;
	const bool was_parent_suite_passing = runner->is_current_suite_passing;
	runner->is_current_suite_passing = true;

	if (runner->print_passing_units) {
		godot::UtilityFunctions::print_rich(get_combined_rich_description());
	}

	// Execute any before_all.
	for (const TestRunnerCallable &TestRunnerCallable : before_alls) {
		TestRunnerCallable.callback();
	}

	// Execute specs for this TestRunnerSuite.
	for (TestRunnerSpec &TestRunnerSpec : specs) {
		if (TestRunnerSpec.should_run()) {
			// Execute any before_each.
			for (const TestRunnerCallable &TestRunnerCallable : before_eaches) {
				TestRunnerCallable.callback();
			}

			runner->is_spec_running = true;

			TestRunnerSpec.run();

			runner->is_spec_running = false;

			// Execute any after_each.
			for (const TestRunnerCallable &TestRunnerCallable : after_eaches) {
				TestRunnerCallable.callback();
			}
		}
	}

	// Recurse.
	for (TestRunnerSuite &TestRunnerSuite : suites) {
		if (TestRunnerSuite.should_run()) {
			TestRunnerSuite.run();
		}
	}

	// Execute any after_all.
	for (const TestRunnerCallable &TestRunnerCallable : after_alls) {
		TestRunnerCallable.callback();
	}

	runner->is_current_suite_passing =
			was_parent_suite_passing && runner->is_current_suite_passing;
	runner->running_suite_count--;
}

void TestRunner::create_suite(
		const std::string &p_description,
		const std::function<void()> &p_callback,
		bool p_is_focused,
		bool p_is_excluded) {
	compiling_suite_count++;

	if (p_is_focused) {
		are_any_tests_focused = true;
	}

	TestRunnerSuite TestRunnerSuite;
	TestRunnerSuite.runner = this;
	TestRunnerSuite.description = p_description;
	TestRunnerSuite.callback = p_callback;
	TestRunnerSuite.is_focused = p_is_focused || compiling_suite->is_focused;
	TestRunnerSuite.is_excluded = p_is_excluded || compiling_suite->is_excluded;
	TestRunnerSuite.parent_suite = compiling_suite;

	compiling_suite->suites.push_back(std::move(TestRunnerSuite));

	compiling_suite = &compiling_suite->suites.back();

	compiling_suite->callback();

	compiling_suite = compiling_suite->parent_suite;

	compiling_suite_count--;
}

void TestRunner::create_spec(
		const std::string &p_description,
		const std::function<void()> &p_callback,
		bool p_is_focused,
		bool p_is_excluded) {
	if (p_is_focused) {
		are_any_tests_focused = true;
	}

	TestRunnerSpec TestRunnerSpec;
	TestRunnerSpec.runner = this;
	TestRunnerSpec.description = p_description;
	TestRunnerSpec.callback = p_callback;
	TestRunnerSpec.is_focused = p_is_focused || compiling_suite->is_focused;
	TestRunnerSpec.is_excluded = p_is_excluded || compiling_suite->is_excluded;
	TestRunnerSpec.TestRunnerSuite = compiling_suite;

	compiling_suite->specs.push_back(std::move(TestRunnerSpec));
}

void TestRunner::run_all_tests() {
	godot::UtilityFunctions::print_rich(
			"\n" _REVERSE_RAINBOW_BAR
			" [color=white]Running tests[/color] " _RAINBOW_BAR);

	failing_spec_count = 0;

	// Register the top-level describes.
	for (const TestRunnerModule &module : test_modules) {
		module.callback();
	}

	root_suite.run();

	if (is_current_suite_passing) {
		godot::UtilityFunctions::print_rich(
				"\n" _REVERSE_RAINBOW_BAR
				" [color=green]All tests passed![/color] " _RAINBOW_BAR "\n");
	} else {
		godot::UtilityFunctions::print_rich(
				godot::vformat(
						"\n" _REVERSE_RAINBOW_BAR
						"[color=red]%d specs failed![/color] " _RAINBOW_BAR
						"\n",
						failing_spec_count));
	}
}

} //namespace godot

#endif // DEBUG_ENABLED
