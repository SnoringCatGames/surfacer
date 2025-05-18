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

struct TestModule;

namespace internal_temp {

extern bool are_any_tests_focused;
extern bool print_passing_units;
extern bool print_passing_expects;

extern int compiling_suite_count;
extern int running_suite_count;
extern int failing_spec_count;
extern bool is_spec_running;
extern bool is_current_suite_passing;
extern bool is_current_spec_passing;

extern std::vector<TestModule> test_modules;

} //namespace internal_temp

#define LOCATION_TEMPLATE                                                      \
	"[lb][color=gray]%s:%s[/color][rb] "                                       \
	"[color=yellow]actual:[/color] [code]%s[/code], "                          \
	"[color=yellow]expected:[/color] [code]%s[/code], [lb]Expect(%s, %s)[rb]"
#define FAIL_TEMPLATE "[color=red]Failed[/color] " LOCATION_TEMPLATE
#define PASS_TEMPLATE "[color=green]Passed[/color] " LOCATION_TEMPLATE

#define RAINBOW_BAR                                                            \
	"[color=red]=[/color][color=orange]=[/color][color=yellow]=[/color]"       \
	"[color=green]=[/color][color=blue]=[/color][color=purple]=[/color]"
#define REVERSE_RAINBOW_BAR                                                    \
	"[color=purple]=[/color][color=blue]=[/color][color=green]=[/color]"       \
	"[color=yellow]=[/color][color=orange]=[/color][color=red]=[/color]"
#define CHECKMARK "[color=green]PASS[/color]"
#define X_MARK "[color=red]FAIL[/color]"

#define PRINT_EXPECT_RESULT(                                                   \
		template, actual_value, expected_value, actual_source,                 \
		expected_source)                                                       \
	godot::UtilityFunctions::print_rich(                                       \
			godot::vformat(                                                    \
					template, __FILE__, __LINE__, actual_value,                \
					expected_value, actual_source, expected_source))

#define HandleExpectResult(actual, expected, check)                            \
	do {                                                                       \
		ENSURE(test_runner::internal_temp::is_spec_running,                    \
			   "Expect() called outside of it().");                            \
		const bool passed = (check);                                           \
		if (!passed) {                                                         \
			test_runner::internal_temp::is_current_spec_passing = false;       \
			test_runner::internal_temp::is_current_suite_passing = false;      \
			test_runner::internal_temp::failing_spec_count++;                  \
			PRINT_EXPECT_RESULT(                                               \
					FAIL_TEMPLATE, Variant(actual).stringify(),                \
					Variant(expected).stringify(), #actual, #expected);        \
		} else if (test_runner::internal_temp::print_passing_expects) {        \
			PRINT_EXPECT_RESULT(                                               \
					PASS_TEMPLATE, Variant(actual).stringify(),                \
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
		const std::function<void()> &p_callback);
void fdescribe(
		const std::string &p_description,
		const std::function<void()> &p_callback);
void xdescribe(
		const std::string &p_description,
		const std::function<void()> &p_callback);

void it(const std::string &p_description,
		const std::function<void()> &p_callback);
void fit(
		const std::string &p_description,
		const std::function<void()> &p_callback);
void xit(
		const std::string &p_description,
		const std::function<void()> &p_callback);

void before_each(const std::function<void()> &p_callback);
void after_each(const std::function<void()> &p_callback);
void before_all(const std::function<void()> &p_callback);
void after_all(const std::function<void()> &p_callback);

void run_tests();
void run_tests_verbose();
void run_tests_very_verbose();

struct TestModule {
	const std::function<void()> callback;
};

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
	test_runner::internal_temp::test_modules.push_back(m_test)

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
