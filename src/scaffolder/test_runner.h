#ifndef TESTRUNNER_H
#define TESTRUNNER_H

#ifdef DEBUG_ENABLED

#include "scaffolder/internal_utils.h"

#include <functional>
#include <string>

#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot {

namespace test_runner {

namespace {

class TestRunner;

// The macro START_SCAFFOLDER_TEST registers a TestModule for the given test file.
// `callback` should contain invocation(s) of `describe` and will be invoked when running the tests.
struct TestModule {
	const std::function<void()> callback;
};

class Describable {
	std::string description;
};

class Callable {
	std::function<void()> callback;
};

class Focusable {
	TestRunner *runner;
	bool is_focused = false;
	bool is_excluded = false;

	bool should_run() const {
		return is_focused || (!runner.are_any_tests_focused && !is_excluded);
	}
};

class Spec : public test_runner::Focusable,
			  public test_runner::Callable,
			  public test_runner::Describable {
	Suite *suite = nullptr;

	void run();

	friend Suite;
	friend TestRunner;
};

class Suite : public test_runner::Focusable,
			   public test_runner::Callable,
			   public test_runner::Describable {
	Suite *parent_suite = nullptr;
	std::vector<Spec> specs;
	std::vector<Suite> suites;
	std::vector<test_runner::Callable> before_eaches;
	std::vector<test_runner::Callable> after_eaches;
	std::vector<test_runner::Callable> before_alls;
	std::vector<test_runner::Callable> after_alls;

	godot::String get_combined_rich_description() const;

	void run();

	friend Spec;
	friend TestRunner;
};

class TestRunner {
private:
	bool are_any_tests_focused = false;
	bool print_passing_units = false;
	bool print_passing_expects = false;

	int compiling_suite_count = 0;
	int running_suite_count = 0;
	int failing_spec_count = 0;
	bool is_spec_running = false;
	bool is_current_suite_passing = true;
	bool is_current_spec_passing = true;

	Suite root_suite;
	Suite *compiling_suite = &root_suite;

	std::vector<TestModule> test_modules;

	friend Spec;
	friend Suite;

public:
	bool is_compiling_a_suite() { return compiling_suite_count > 0; }
	bool is_running_a_suite() { return running_suite_count > 0; }

	void create_suite(
			const std::string &p_description,
			const std::function<void()> &p_callback,
			bool p_is_focused,
			bool p_is_excluded);

	void create_spec(
			const std::string &p_description,
			const std::function<void()> &p_callback,
			bool p_is_focused,
			bool p_is_excluded);

	void run_all_tests();
};

TestRunner runner;

} //namespace

#define _LOCATION_TEMPLATE                                                      \
	"[lb][color=gray]%s:%s[/color][rb] "                                       \
	"[color=yellow]actual:[/color] [code]%s[/code], "                          \
	"[color=yellow]expected:[/color] [code]%s[/code], [lb]Expect(%s, %s)[rb]"
#define _FAIL_TEMPLATE "[color=red]Failed[/color] " _LOCATION_TEMPLATE
#define _PASS_TEMPLATE "[color=green]Passed[/color] " _LOCATION_TEMPLATE

#define _RAINBOW_BAR                                                            \
	"[color=red]=[/color][color=orange]=[/color][color=yellow]=[/color]"       \
	"[color=green]=[/color][color=blue]=[/color][color=purple]=[/color]"
#define _REVERSE_RAINBOW_BAR                                                    \
	"[color=purple]=[/color][color=blue]=[/color][color=green]=[/color]"       \
	"[color=yellow]=[/color][color=orange]=[/color][color=red]=[/color]"
#define _CHECKMARK "[color=green]PASS[/color]"
#define _X_MARK "[color=red]FAIL[/color]"

#define _PRINT_EXPECT_RESULT(                                                   \
		template, actual_value, expected_value, actual_source,                 \
		expected_source)                                                       \
		godot::UtilityFunctions::print_rich(                                       \
			godot::vformat(                                                    \
					template, __FILE__, __LINE__, actual_value,                \
					expected_value, actual_source, expected_source))

#define HandleExpectResult(actual, expected, check)                            \
	do {                                                                       \
		ENSURE(runner.is_spec_running,                    \
			   "Expect() called outside of it().");                            \
		const bool passed = (check);                                           \
		if (!passed) {                                                         \
			runner.is_current_spec_passing = false;       \
			runner.is_current_suite_passing = false;      \
			runner.failing_spec_count++;                  \
			_PRINT_EXPECT_RESULT(                                               \
					_FAIL_TEMPLATE, Variant(actual).stringify(),                \
					Variant(expected).stringify(), #actual, #expected);        \
		} else if (runner.print_passing_expects) {        \
			_PRINT_EXPECT_RESULT(                                               \
					_PASS_TEMPLATE, Variant(actual).stringify(),                \
					Variant(expected).stringify(), #actual, #expected);        \
		}                                                                      \
	} while (0)

#define Expect(actual, expected)                                               \
	HandleExpectResult(actual, expected, (actual) == (expected));

#define ExpectThisClose(actual, expected, epsilon)                             \
	HandleExpectResult(actual, expected, ABS((actual) - (expected)) < epsilon)

#define ExpectClose(actual, expected)                                          \
	ExpectThisClose(actual, expected, 0.00001f)

#define ExpectTrue(condition) Expect(condition, true)

#define Fail() Expect(true, false)

void describe(
		const std::string &p_description,
		const std::function<void()> &p_callback) {
	runner.create_suite(p_description, p_callback, false, false);
}

void fdescribe(
		const std::string &p_description,
		const std::function<void()> &p_callback) {
	runner.create_suite(p_description, p_callback, true, false);
}

void xdescribe(
		const std::string &p_description,
		const std::function<void()> &p_callback) {
	runner.create_suite(p_description, p_callback, false, true);
}

void it(const std::string &p_description,
		const std::function<void()> &p_callback) {
	runner.create_spec(p_description, p_callback, false, false);
}

void fit(
		const std::string &p_description,
		const std::function<void()> &p_callback) {
	runner.create_spec(p_description, p_callback, true, false);
}

void xit(
		const std::string &p_description,
		const std::function<void()> &p_callback) {
	runner.create_spec(p_description, p_callback, false, true);
}

void before_each(const std::function<void()> &p_callback) {
	ENSURE(runner.is_compiling_a_suite(),
		   "before_each() called outside of describe().");

	test_runner::Callable callable;
	callable.callback = p_callback;

	runner.compiling_suite->before_eaches.push_back(std::move(callable));
}

void after_each(const std::function<void()> &p_callback) {
	ENSURE(runner.is_compiling_a_suite(),
		   "after_each() called outside of describe().");

	test_runner::Callable callable;
	callable.callback = p_callback;

	runner.compiling_suite->after_eaches.push_back(std::move(callable));
}

void before_all(const std::function<void()> &p_callback) {
	ENSURE(runner.is_compiling_a_suite(),
		   "before_all() called outside of describe().");

	test_runner::Callable callable;
	callable.callback = p_callback;

	runner.compiling_suite->before_alls.push_back(std::move(callable));
}

void after_all(const std::function<void()> &p_callback) {
	ENSURE(runner.is_compiling_a_suite(), "after_all() called outside of describe().");

	test_runner::Callable callable;
	callable.callback = p_callback;

	runner.compiling_suite->after_alls.push_back(std::move(callable));
}

void run_tests() {
	print_passing_units = false;
	print_passing_expects = false;
	runner.run_all_tests();
}

void run_tests_verbose() {
	print_passing_units = true;
	print_passing_expects = false;
	runner.run_all_tests();
}

void run_tests_very_verbose() {
	print_passing_units = true;
	print_passing_expects = true;
	runner.run_all_tests();
}

} //namespace test_runner

// clang-format off

#define START_SCAFFOLDER_TEST(m_name)                                          \
	namespace godot {                                                          \
	using namespace test_runner;                                               \
	TestModule ScaffolderTest_##m_name = TestModule {                          \
		[]() {                                                                 \
			describe(#m_name, []() {

#define END_SCAFFOLDER_TEST                                                    \
			});                                                                \
		}                                                                      \
	};                                                                         \
	} //namespace godot

// clang-format on

#define REGISTER_SCAFFOLDER_TEST_SUITE(m_test)                                 \
	runner.test_modules.push_back(m_test)

#define REGISTER_SCAFFOLDER_CLASS(m_class)                                     \
	do {                                                                       \
		GDREGISTER_CLASS(m_class);                                             \
		REGISTER_SCAFFOLDER_TEST_SUITE(ScaffolderTest_##m_class);              \
	} while (0)

} //namespace godot

#else // DEBUG_ENABLED

namespace godot {
#define REGISTER_SCAFFOLDER_CLASS(m_class) GDREGISTER_CLASS(m_class)
} //namespace godot

#endif // DEBUG_ENABLED

#endif // TESTRUNNER_H
