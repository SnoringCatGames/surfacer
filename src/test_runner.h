#ifndef TESTRUNNER_H
#define TESTRUNNER_H

#ifdef DEBUG_ENABLED

#include "internal_utils.h"

#include <functional>
#include <string>

#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot {

namespace TestRunner {

namespace Internal {

extern bool are_any_tests_focused;
extern bool print_passing_units;
extern bool print_passing_expects;

extern int compiling_suite_count;
extern int running_suite_count;
extern int failing_spec_count;
extern bool is_spec_running;
extern bool is_current_suite_passing;
extern bool is_current_spec_passing;

} //namespace Internal

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

#define Expect(actual, expected)                                               \
	do {                                                                       \
		ENSURE(TestRunner::Internal::is_spec_running,                          \
			   "Expect() called outside of it().");                            \
		bool passed = (actual) == (expected);                                  \
		if (!passed) {                                                         \
			TestRunner::Internal::is_current_spec_passing = false;             \
			TestRunner::Internal::is_current_suite_passing = false;            \
			TestRunner::Internal::failing_spec_count++;                        \
			PRINT_EXPECT_RESULT(                                               \
					FAIL_TEMPLATE, Variant(actual).stringify(),                \
					Variant(expected).stringify(), #actual, #expected);        \
		} else if (TestRunner::Internal::print_passing_expects) {              \
			PRINT_EXPECT_RESULT(                                               \
					PASS_TEMPLATE, Variant(actual).stringify(),                \
					Variant(expected).stringify(), #actual, #expected);        \
		}                                                                      \
	} while (0)

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

struct TestSpaceHack {
	TestSpaceHack(const std::function<void()> &p_callback) { p_callback(); }
};

#define test_space(callback)                                                   \
	using namespace godot;                                                     \
	using namespace godot::TestRunner;                                         \
	namespace {                                                                \
	static TestSpaceHack hack(callback);                                       \
	} //namespace TestRunner

} //namespace TestRunner

} //namespace godot

#endif // DEBUG_ENABLED
#endif // TESTRUNNER_H
