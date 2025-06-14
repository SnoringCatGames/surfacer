#ifndef TEST_RUNNER_H
#define TEST_RUNNER_H

#ifdef DEBUG_ENABLED

#include "snore_core/internal/internal_debug_utils.h"

#include <functional>
#include <string>

#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot {

class TestRunnerSuite;
class TestRunner;

// The macro START_SNORE_CORE_TEST registers a TestRunnerModule for the given
// test file. `callback` should contain invocation(s) of `describe` and will be
// invoked when running the tests.
struct TestRunnerModule {
	const std::function<void()> callback;
};

class TestRunnerDescribable {
public:
	std::string description;
};

class TestRunnerCallable {
public:
	std::function<void()> callback;
};

class TestRunnerFocusable {
public:
	TestRunner *runner;
	bool is_focused = false;
	bool is_excluded = false;

	bool should_run() const;
};

class TestRunnerSpec : public TestRunnerFocusable,
					   public TestRunnerCallable,
					   public TestRunnerDescribable {
public:
	TestRunnerSuite *TestRunnerSuite = nullptr;

	void run();
};

class TestRunnerSuite : public TestRunnerFocusable,
						public TestRunnerCallable,
						public TestRunnerDescribable {
public:
	TestRunnerSuite *parent_suite = nullptr;
	std::vector<TestRunnerSpec> specs;
	std::vector<TestRunnerSuite> suites;
	std::vector<TestRunnerCallable> before_eaches;
	std::vector<TestRunnerCallable> after_eaches;
	std::vector<TestRunnerCallable> before_alls;
	std::vector<TestRunnerCallable> after_alls;

	godot::String get_combined_rich_description() const;

	void run();
};

class TestRunner {
public:
	bool are_any_tests_focused = false;
	bool print_passing_units = false;
	bool print_passing_expects = false;

	int compiling_suite_count = 0;
	int running_suite_count = 0;
	int failing_spec_count = 0;
	bool is_spec_running = false;
	bool is_current_suite_passing = true;
	bool is_current_spec_passing = true;

	TestRunnerSuite root_suite;
	TestRunnerSuite *compiling_suite = &root_suite;

	std::vector<TestRunnerModule> test_modules;

	TestRunner() { root_suite.runner = this; }
	~TestRunner() { root_suite.runner = nullptr; }

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

namespace TestRunnerInternal {

extern TestRunner runner;

} //namespace TestRunnerInternal

#define _LOCATION_TEMPLATE                                                     \
	"[lb][color=gray]%s:%s[/color][rb] "                                       \
	"[color=yellow]actual:[/color] [code]%s[/code], "                          \
	"[color=yellow]expected:[/color] [code]%s[/code], [lb]Expect(%s, %s)[rb]"
#define _FAIL_TEMPLATE "[color=red]Failed[/color] " _LOCATION_TEMPLATE
#define _PASS_TEMPLATE "[color=green]Passed[/color] " _LOCATION_TEMPLATE

#define _RAINBOW_BAR                                                           \
	"[color=red]=[/color][color=orange]=[/color][color=yellow]=[/color]"       \
	"[color=green]=[/color][color=blue]=[/color][color=purple]=[/color]"
#define _REVERSE_RAINBOW_BAR                                                   \
	"[color=purple]=[/color][color=blue]=[/color][color=green]=[/color]"       \
	"[color=yellow]=[/color][color=orange]=[/color][color=red]=[/color]"
#define _CHECKMARK "[color=green]PASS[/color]"
#define _X_MARK "[color=red]FAIL[/color]"

#define _PRINT_EXPECT_RESULT(                                                  \
		template, actual_value, expected_value, actual_source,                 \
		expected_source)                                                       \
	godot::UtilityFunctions::print_rich(                                       \
			godot::vformat(                                                    \
					template, __FILE__, __LINE__, actual_value,                \
					expected_value, actual_source, expected_source))

#define HandleExpectResult(actual, expected, check)                            \
	do {                                                                       \
		ENSURE(TestRunnerInternal::runner.is_spec_running,                     \
			   "Expect() called outside of it().");                            \
		const bool passed = (check);                                           \
		if (!passed) {                                                         \
			TestRunnerInternal::runner.is_current_spec_passing = false;        \
			TestRunnerInternal::runner.is_current_suite_passing = false;       \
			TestRunnerInternal::runner.failing_spec_count++;                   \
			_PRINT_EXPECT_RESULT(                                              \
					_FAIL_TEMPLATE, Variant(actual).stringify(),               \
					Variant(expected).stringify(), #actual, #expected);        \
			DEBUG_BREAK();                                                     \
		} else if (TestRunnerInternal::runner.print_passing_expects) {         \
			_PRINT_EXPECT_RESULT(                                              \
					_PASS_TEMPLATE, Variant(actual).stringify(),               \
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

_FORCE_INLINE_ void describe(
		const std::string &p_description,
		const std::function<void()> &p_callback) {
	TestRunnerInternal::runner.create_suite(
			p_description, p_callback, false, false);
}

_FORCE_INLINE_ void fdescribe(
		const std::string &p_description,
		const std::function<void()> &p_callback) {
	TestRunnerInternal::runner.create_suite(
			p_description, p_callback, true, false);
}

_FORCE_INLINE_ void xdescribe(
		const std::string &p_description,
		const std::function<void()> &p_callback) {
	TestRunnerInternal::runner.create_suite(
			p_description, p_callback, false, true);
}

_FORCE_INLINE_ void it(
		const std::string &p_description,
		const std::function<void()> &p_callback) {
	TestRunnerInternal::runner.create_spec(
			p_description, p_callback, false, false);
}

_FORCE_INLINE_ void fit(
		const std::string &p_description,
		const std::function<void()> &p_callback) {
	TestRunnerInternal::runner.create_spec(
			p_description, p_callback, true, false);
}

_FORCE_INLINE_ void xit(
		const std::string &p_description,
		const std::function<void()> &p_callback) {
	TestRunnerInternal::runner.create_spec(
			p_description, p_callback, false, true);
}

_FORCE_INLINE_ void before_each(const std::function<void()> &p_callback) {
	ENSURE(TestRunnerInternal::runner.is_compiling_a_suite(),
		   "before_each() called outside of describe().");

	TestRunnerCallable TestRunnerCallable;
	TestRunnerCallable.callback = p_callback;

	TestRunnerInternal::runner.compiling_suite->before_eaches.push_back(
			std::move(TestRunnerCallable));
}

_FORCE_INLINE_ void after_each(const std::function<void()> &p_callback) {
	ENSURE(TestRunnerInternal::runner.is_compiling_a_suite(),
		   "after_each() called outside of describe().");

	TestRunnerCallable TestRunnerCallable;
	TestRunnerCallable.callback = p_callback;

	TestRunnerInternal::runner.compiling_suite->after_eaches.push_back(
			std::move(TestRunnerCallable));
}

_FORCE_INLINE_ void before_all(const std::function<void()> &p_callback) {
	ENSURE(TestRunnerInternal::runner.is_compiling_a_suite(),
		   "before_all() called outside of describe().");

	TestRunnerCallable TestRunnerCallable;
	TestRunnerCallable.callback = p_callback;

	TestRunnerInternal::runner.compiling_suite->before_alls.push_back(
			std::move(TestRunnerCallable));
}

_FORCE_INLINE_ void after_all(const std::function<void()> &p_callback) {
	ENSURE(TestRunnerInternal::runner.is_compiling_a_suite(),
		   "after_all() called outside of describe().");

	TestRunnerCallable TestRunnerCallable;
	TestRunnerCallable.callback = p_callback;

	TestRunnerInternal::runner.compiling_suite->after_alls.push_back(
			std::move(TestRunnerCallable));
}

_FORCE_INLINE_ void run_tests() {
	TestRunnerInternal::runner.print_passing_units = false;
	TestRunnerInternal::runner.print_passing_expects = false;
	TestRunnerInternal::runner.run_all_tests();
}

_FORCE_INLINE_ void run_tests_verbose() {
	TestRunnerInternal::runner.print_passing_units = true;
	TestRunnerInternal::runner.print_passing_expects = false;
	TestRunnerInternal::runner.run_all_tests();
}

_FORCE_INLINE_ void run_tests_very_verbose() {
	TestRunnerInternal::runner.print_passing_units = true;
	TestRunnerInternal::runner.print_passing_expects = true;
	TestRunnerInternal::runner.run_all_tests();
}

// clang-format off

#define START_SNORE_CORE_TEST(m_name)                                          \
	namespace godot {                                                          \
	TestRunnerModule SnoreCoreTest_##m_name = TestRunnerModule {                          \
		[]() {                                                                 \
			describe(#m_name, []() {

#define END_SNORE_CORE_TEST                                                    \
			});                                                                \
		}                                                                      \
	};                                                                         \
	} //namespace godot

// clang-format on

} //namespace godot

#endif // DEBUG_ENABLED

#endif // TEST_RUNNER_H
