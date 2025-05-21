#include "scaffolder/test_runner.h"

#ifdef DEBUG_ENABLED

namespace godot {

namespace test_runner {

void Spec::run() {
	runner.is_spec_running = true;
	runner.is_current_spec_passing = true;

	callback();

	if (!runner.is_current_spec_passing) {
		// Print the suite path, if we aren't already printing all results.
		if (!runner.print_passing_units) {
			godot::UtilityFunctions::print_rich(
					godot::vformat(
							"%s [color=white]>[/color]",
							suite->get_combined_rich_description()));
		}
		godot::UtilityFunctions::print_rich(
				godot::vformat(
						"%s: [color=purple]%s[/color]", _X_MARK,
						description.c_str()));
	} else if (runner.print_passing_units) {
		godot::UtilityFunctions::print_rich(
				godot::vformat(
						"%s: [color=purple]%s[/color]", _CHECKMARK,
						description.c_str()));
	}

	runner.is_spec_running = false;
}

godot::String Suite::get_combined_rich_description() const {
	godot::String combined_description =
			godot::vformat("[color=cyan]%s[/color]", description.c_str());
	const Suite *current_suite = parent_suite;
	while (current_suite) {
		// Skip the empty root description.
		if (!current_suite->description.empty()) {
			combined_description = godot::vformat(
					"[color=dark_slate_gray]%s[/color] "
					"[color=white]>[/color] "
					"%s",
					current_suite->description.c_str(),
					combined_description);
		}
		current_suite = current_suite->parent_suite;
	}
	return combined_description;
}

void Suite::run() {
	runner.running_suite_count++;
	const bool was_parent_suite_passing = runner.is_current_suite_passing;
	runner.is_current_suite_passing = true;

	if (runner.print_passing_units) {
		godot::UtilityFunctions::print_rich(
				get_combined_rich_description());
	}

	// Execute any before_all.
	for (const test_runner::Callable &callable : before_alls) {
		callable.callback();
	}

	// Execute specs for this suite.
	for (Spec &spec : specs) {
		if (spec.should_run()) {
			// Execute any before_each.
			for (const test_runner::Callable &callable : before_eaches) {
				callable.callback();
			}

			runner.is_spec_running = true;

			spec.run();

			runner.is_spec_running = false;

			// Execute any after_each.
			for (const test_runner::Callable &callable : after_eaches) {
				callable.callback();
			}
		}
	}

	// Recurse.
	for (Suite &suite : suites) {
		if (suite.should_run()) {
			suite.run();
		}
	}

	// Execute any after_all.
	for (const test_runner::Callable &callable : after_alls) {
		callable.callback();
	}

	runner.is_current_suite_passing =
			was_parent_suite_passing && runner.is_current_suite_passing;
	runner.running_suite_count--;
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

	Suite suite;
	suite.runner = this;
	suite.description = p_description;
	suite.callback = p_callback;
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
		const std::string &p_description,
		const std::function<void()> &p_callback,
		bool p_is_focused,
		bool p_is_excluded) {
	if (p_is_focused) {
		are_any_tests_focused = true;
	}

	Spec spec;
	suite.runner = this;
	spec.description = p_description;
	spec.callback = p_callback;
	spec.is_focused = p_is_focused || compiling_suite->is_focused;
	spec.is_excluded = p_is_excluded || compiling_suite->is_excluded;
	spec.suite = compiling_suite;

	compiling_suite->specs.push_back(std::move(spec));
}

void TestRunner::run_all_tests() {
	godot::UtilityFunctions::print_rich(
			"\n" _REVERSE_RAINBOW_BAR
			" [color=white]Running tests[/color] " _RAINBOW_BAR);

	failing_spec_count = 0;

	// Register the top-level describes.
	for (const TestModule &module : test_modules) {
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
						"[color=red]%d specs failed![/color] " _RAINBOW_BAR "\n",
						failing_spec_count));
	}
}

} //namespace test_runner

} //namespace godot

#endif // DEBUG_ENABLED
