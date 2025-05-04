#ifndef TESTRUNNER_H
#define TESTRUNNER_H

#ifdef DEBUG_ENABLED

#include "internal_utils.h"

#include <functional>
#include <string>

#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

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

void describe_internal(
		const std::string &p_description,
		const std::function<void()> &p_callback);
void fdescribe_internal(
		const std::string &p_description,
		const std::function<void()> &p_callback);
void xdescribe_internal(
		const std::string &p_description,
		const std::function<void()> &p_callback);

} //namespace Internal

#define LOCATION_TEMPLATE                                                      \
	"[lb][color=gray]%s:%s[/color][rb] "                                       \
	"[color=yellow]actual:[/color] [code]%s[/code], "                          \
	"[color=yellow]expected:[/color] [code]%s[/code]"
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

#define PRINT_EXPECT_RESULT(template, actual, expected)                        \
	godot::UtilityFunctions::print_rich(                                       \
			godot::vformat(template, __FILE__, __LINE__, actual, expected))

#define Expect(actual, expected)                                               \
	do {                                                                       \
		ENSURE(TestRunner::Internal::is_spec_running,                          \
			   "Expect() called outside of it().");                            \
		bool passed = (actual) == (expected);                                  \
		if (!passed) {                                                         \
			TestRunner::Internal::is_current_spec_passing = false;             \
			TestRunner::Internal::is_current_suite_passing = false;            \
			TestRunner::Internal::failing_spec_count++;                        \
			PRINT_EXPECT_RESULT(FAIL_TEMPLATE, #actual, #expected);            \
		} else if (TestRunner::Internal::print_passing_expects) {              \
			PRINT_EXPECT_RESULT(PASS_TEMPLATE, #actual, #expected);            \
		}                                                                      \
	} while (0)

#define ExpectTrue(condition) Expect(condition, true)

#define Fail() Expect(true, false)

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

struct DescribeHack {
	DescribeHack(
			const std::string &p_description,
			const std::function<void()> &p_callback) {
		Internal::describe_internal(p_description, p_callback);
	}
};

struct FDescribeHack {
	FDescribeHack(
			const std::string &p_description,
			const std::function<void()> &p_callback) {
		Internal::fdescribe_internal(p_description, p_callback);
	}
};

struct XDescribeHack {
	XDescribeHack(
			const std::string &p_description,
			const std::function<void()> &p_callback) {
		Internal::xdescribe_internal(p_description, p_callback);
	}
};

#define describe(description, callback)                                        \
	namespace {                                                                \
	static DescribeHack hack(description, callback);                           \
	}
#define fdescribe(description, callback)                                       \
	namespace {                                                                \
	static FDescribeHack hack(description, callback);                          \
	}
#define xdescribe(description, callback)                                       \
	namespace {                                                                \
	static XDescribeHack hack(description, callback);                          \
	}

} //namespace TestRunner

#endif // DEBUG_ENABLED
#endif // TESTRUNNER_H
