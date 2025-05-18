#include "scaffolder/test_runner.h"

#ifdef DEBUG_ENABLED

// FIXME: LEFT OFF HERE: Update test_runner to not rely on any static state
//                       (other than the single test_modules variable).

namespace godot {

namespace test_runner {

namespace internal_temp {

bool are_any_tests_focused = false;
bool print_passing_units = false;
bool print_passing_expects = false;

int compiling_suite_count = 0;
int running_suite_count = 0;
int failing_spec_count = 0;
bool is_spec_running = false;
bool is_current_suite_passing = true;
bool is_current_spec_passing = true;

std::vector<TestModule> test_modules = {};

} //namespace internal_temp

using namespace internal_temp;

namespace {
struct Suite;
struct Spec;

struct Describable {
	std::string description;
};

struct Callable {
	std::function<void()> callback;
};

struct Focusable {
	bool is_focused = false;
	bool is_excluded = false;

	bool should_run() const {
		return is_focused || (!are_any_tests_focused && !is_excluded);
	}
};

struct Spec : public test_runner::Focusable,
			  public test_runner::Callable,
			  public test_runner::Describable {
	Suite *suite = nullptr;

	void run();
};

struct Suite : public test_runner::Focusable,
			   public test_runner::Callable,
			   public test_runner::Describable {
	Suite *parent_suite = nullptr;
	std::vector<Spec> specs;
	std::vector<Suite> suites;
	std::vector<test_runner::Callable> before_eaches;
	std::vector<test_runner::Callable> after_eaches;
	std::vector<test_runner::Callable> before_alls;
	std::vector<test_runner::Callable> after_alls;

	godot::String get_combined_rich_description() const {
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

	void run() {
		running_suite_count++;
		const bool was_parent_suite_passing = is_current_suite_passing;
		is_current_suite_passing = true;

		if (print_passing_units) {
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

				is_spec_running = true;

				spec.run();

				is_spec_running = false;

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

		is_current_suite_passing =
				was_parent_suite_passing && is_current_suite_passing;
		running_suite_count--;
	}
};

void Spec::run() {
	is_spec_running = true;
	is_current_spec_passing = true;

	callback();

	if (!is_current_spec_passing) {
		// Print the suite path, if we aren't already printing all results.
		if (!print_passing_units) {
			godot::UtilityFunctions::print_rich(
					godot::vformat(
							"%s [color=white]>[/color]",
							suite->get_combined_rich_description()));
		}
		godot::UtilityFunctions::print_rich(
				godot::vformat(
						"%s: [color=purple]%s[/color]", X_MARK,
						description.c_str()));
	} else if (print_passing_units) {
		godot::UtilityFunctions::print_rich(
				godot::vformat(
						"%s: [color=purple]%s[/color]", CHECKMARK,
						description.c_str()));
	}

	is_spec_running = false;
}

Suite root_suite;
Suite *compiling_suite = &root_suite;

bool is_compiling_a_suite() { return compiling_suite_count > 0; }
bool is_running_a_suite() { return running_suite_count > 0; }

void create_suite(
		const std::string &p_description,
		const std::function<void()> &p_callback,
		bool p_is_focused,
		bool p_is_excluded) {
	compiling_suite_count++;

	if (p_is_focused) {
		are_any_tests_focused = true;
	}

	Suite suite;
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

void create_spec(
		const std::string &p_description,
		const std::function<void()> &p_callback,
		bool p_is_focused,
		bool p_is_excluded) {
	if (p_is_focused) {
		are_any_tests_focused = true;
	}

	Spec spec;
	spec.description = p_description;
	spec.callback = p_callback;
	spec.is_focused = p_is_focused || compiling_suite->is_focused;
	spec.is_excluded = p_is_excluded || compiling_suite->is_excluded;
	spec.suite = compiling_suite;

	compiling_suite->specs.push_back(std::move(spec));
}

void run_all_tests() {
	godot::UtilityFunctions::print_rich(
			"\n" REVERSE_RAINBOW_BAR
			" [color=white]Running tests[/color] " RAINBOW_BAR);

	failing_spec_count = 0;

	// Register the top-level describes.
	for (const godot::test_runner::TestModule &module :
		 godot::test_runner::internal_temp::test_modules) {
		module.callback();
	}

	root_suite.run();

	if (is_current_suite_passing) {
		godot::UtilityFunctions::print_rich(
				"\n" REVERSE_RAINBOW_BAR
				" [color=green]All tests passed![/color] " RAINBOW_BAR "\n");
	} else {
		godot::UtilityFunctions::print_rich(
				godot::vformat(
						"\n" REVERSE_RAINBOW_BAR
						"[color=red]%d specs failed![/color] " RAINBOW_BAR "\n",
						failing_spec_count));
	}
}

} //namespace

void describe(
		const std::string &p_description,
		const std::function<void()> &p_callback) {
	create_suite(p_description, p_callback, false, false);
}

void fdescribe(
		const std::string &p_description,
		const std::function<void()> &p_callback) {
	create_suite(p_description, p_callback, true, false);
}

void xdescribe(
		const std::string &p_description,
		const std::function<void()> &p_callback) {
	create_suite(p_description, p_callback, false, true);
}

void it(const std::string &p_description,
		const std::function<void()> &p_callback) {
	create_spec(p_description, p_callback, false, false);
}

void fit(
		const std::string &p_description,
		const std::function<void()> &p_callback) {
	create_spec(p_description, p_callback, true, false);
}

void xit(
		const std::string &p_description,
		const std::function<void()> &p_callback) {
	create_spec(p_description, p_callback, false, true);
}

void before_each(const std::function<void()> &p_callback) {
	ENSURE(is_compiling_a_suite(),
		   "before_each() called outside of describe().");

	test_runner::Callable callable;
	callable.callback = p_callback;

	compiling_suite->before_eaches.push_back(std::move(callable));
}

void after_each(const std::function<void()> &p_callback) {
	ENSURE(is_compiling_a_suite(),
		   "after_each() called outside of describe().");

	test_runner::Callable callable;
	callable.callback = p_callback;

	compiling_suite->after_eaches.push_back(std::move(callable));
}

void before_all(const std::function<void()> &p_callback) {
	ENSURE(is_compiling_a_suite(),
		   "before_all() called outside of describe().");

	test_runner::Callable callable;
	callable.callback = p_callback;

	compiling_suite->before_alls.push_back(std::move(callable));
}

void after_all(const std::function<void()> &p_callback) {
	ENSURE(is_compiling_a_suite(), "after_all() called outside of describe().");

	test_runner::Callable callable;
	callable.callback = p_callback;

	compiling_suite->after_alls.push_back(std::move(callable));
}

void run_tests() {
	print_passing_units = false;
	print_passing_expects = false;
	run_all_tests();
}

void run_tests_verbose() {
	print_passing_units = true;
	print_passing_expects = false;
	run_all_tests();
}

void run_tests_very_verbose() {
	print_passing_units = true;
	print_passing_expects = true;
	run_all_tests();
}

} //namespace test_runner

} //namespace godot

#endif // DEBUG_ENABLED
