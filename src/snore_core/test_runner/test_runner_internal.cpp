#include "snore_core/test_runner/test_runner.h"

#ifdef DEBUG_ENABLED

namespace godot {

TestRunner TestRunnerInternal::runner = TestRunner();

bool TestRunnerFocusable::should_run() const {
	return is_focused || (!runner->are_any_tests_focused && !is_excluded);
}

void TestRunnerSpec::run() {
	runner->is_spec_running = true;
	runner->is_current_spec_passing = true;

	if (suite->fixture) {
		callback_with_fixture.value()(suite->fixture);
	} else {
		callback.value()();
	}

	if (!runner->is_current_spec_passing) {
		// Print the TestRunnerSuite path, if we aren't already printing all
		// results.
		if (!runner->print_passing_units) {
			godot::UtilityFunctions::print_rich(
					godot::vformat(
							"%s [color=white]>[/color]",
							suite->get_combined_rich_description()));
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
	if (fixture) {
		fixture->before_all();
	}

	// Execute specs for this TestRunnerSuite.
	for (TestRunnerSpec &TestRunnerSpec : specs) {
		if (TestRunnerSpec.should_run()) {
			// Execute before_eaches.
			before_spec();

			TestRunnerSpec.run();

			// Execute after_eaches.
			after_spec();
		}
	}

	// Recurse.
	for (TestRunnerSuite &suite : suites) {
		if (suite.should_run()) {
			suite.run();
		}
	}

	// Execute any after_all.
	if (fixture) {
		fixture->after_all();
	}

	runner->is_current_suite_passing =
			was_parent_suite_passing && runner->is_current_suite_passing;
	runner->running_suite_count--;
}

void TestRunnerSuite::before_spec() {
	// Execute any before_each.
	if (fixture) {
		fixture->before_each();
	}
	// Execute ancestor before_eaches.
	if (parent_suite) {
		parent_suite->before_spec();
	}
}

void TestRunnerSuite::after_spec() {
	// Execute any after_each.
	if (fixture) {
		fixture->after_each();
	}
	// Execute ancestor after_eaches.
	if (parent_suite) {
		parent_suite->after_spec();
	}
}

void TestRunner::create_suite(
		std::shared_ptr<TestRunnerFixture> p_fixture,
		std::string &&p_description,
		CallbackWithoutFixture &&p_callback,
		bool p_is_focused,
		bool p_is_excluded) {
	compiling_suite_count++;

	if (p_is_focused) {
		are_any_tests_focused = true;
	}

	TestRunnerSuite suite;
	suite.fixture = std::move(p_fixture);
	suite.runner = this;
	suite.description = std::move(p_description);
	suite.callback = std::move(p_callback);
	suite.is_focused = p_is_focused || compiling_suite->is_focused;
	suite.is_excluded = p_is_excluded || compiling_suite->is_excluded;
	suite.parent_suite = compiling_suite;

	compiling_suite->suites.push_back(std::move(suite));

	compiling_suite = &compiling_suite->suites.back();

	compiling_suite->callback();

	compiling_suite = compiling_suite->parent_suite;

	compiling_suite_count--;
}

void TestRunner::create_spec(
		std::string &&p_description,
		std::optional<CallbackWithFixture> p_callback_with_fixture,
		std::optional<CallbackWithoutFixture> p_callback,
		bool p_is_focused,
		bool p_is_excluded) {
	if (p_is_focused) {
		are_any_tests_focused = true;
	}

	TestRunnerSpec TestRunnerSpec;
	TestRunnerSpec.runner = this;
	TestRunnerSpec.description = std::move(p_description);
	TestRunnerSpec.callback_with_fixture = p_callback_with_fixture;
	TestRunnerSpec.callback = p_callback;
	TestRunnerSpec.is_focused = p_is_focused || compiling_suite->is_focused;
	TestRunnerSpec.is_excluded = p_is_excluded || compiling_suite->is_excluded;
	TestRunnerSpec.suite = compiling_suite;

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
