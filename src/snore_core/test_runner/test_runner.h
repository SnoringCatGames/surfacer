#ifndef TEST_RUNNER_H
#define TEST_RUNNER_H

#ifdef DEBUG_ENABLED

#include "snore_core/internal/internal_debug_utils.h"
#include "snore_core/test_runner/test_runner_internal.h"

#include <godot_cpp/variant/utility_functions.hpp>

namespace godot {

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

#define _LOCATION_TEMPLATE                                                     \
	"[lb][color=gray]%s:%s[/color][rb] "                                       \
	"[color=yellow]actual:[/color] [code]%s[/code], "                          \
	"[color=yellow]expected:[/color] [code]%s[/code], [lb]expect(%s, %s)[rb]"
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

#define _HANDLE_EXPECT_RESULT(actual, expected, check)                         \
	do {                                                                       \
		ENSURE(TestRunnerInternal::runner.is_spec_running,                     \
			   "expect() called outside of it().");                            \
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

#define expect(actual, expected)                                               \
	_HANDLE_EXPECT_RESULT(actual, expected, (actual) == (expected));

#define expect_this_close(actual, expected, epsilon)                           \
	_HANDLE_EXPECT_RESULT(                                                     \
			actual, expected, ABS((actual) - (expected)) < epsilon)

#define expect_close(actual, expected)                                         \
	expect_this_close(actual, expected, 0.00001f)

#define expect_true(condition) expect(condition, true)

#define fail() expect(true, false)

#define TEST_MODULE_NAME(m_name) (TestRunnerModule_##m_name)
#define TEST_FIXTURE_NAME(m_name) (TestRunnerFixture_##m_name)

#define describe(m_description, m_callback)                                    \
	TestRunnerInternal::_describe(m_description, m_callback)

#define describe_f(m_fixture_name, m_description, m_callback)                  \
	TestRunnerInternal::_describe_f(                                           \
			std::make_shared<TEST_FIXTURE_NAME(m_fixture_name)>(),             \
			m_description, m_callback);

#define fdescribe(m_description, m_callback)                                   \
	TestRunnerInternal::_fdescribe(m_description, m_callback);

#define fdescribe_f(m_fixture_name, m_description, m_callback)                 \
	TestRunnerInternal::_fdescribe_f(                                          \
			std::make_shared<TEST_FIXTURE_NAME(m_fixture_name)>(),             \
			m_description, m_callback);

#define xdescribe(m_description, m_callback)                                   \
	TestRunnerInternal::_xdescribe(m_description, m_callback);

#define xdescribe_f(m_fixture_name, m_description, m_callback)                 \
	TestRunnerInternal::_xdescribe_f(                                          \
			std::make_shared<TEST_FIXTURE_NAME(m_fixture_name)>(),             \
			m_description, m_callback);

#define it(m_description, m_callback)                                          \
	TestRunnerInternal::_it(m_description, m_callback);

#define it_f(m_fixture_name, m_description, m_callback)                        \
	TestRunnerInternal::_it_f(                                                 \
			m_description, [](std::shared_ptr<TestRunnerFixture> p_fixture) {  \
				m_callback(                                                    \
						static_cast<TEST_FIXTURE_NAME(m_fixture_name) &>(      \
								*p_fixture));                                  \
			});

#define fit(m_description, m_callback)                                         \
	TestRunnerInternal::_fit(m_description, m_callback);

#define fit_f(m_fixture_name, m_description, m_callback)                       \
	TestRunnerInternal::_fit_f(                                                \
			m_description, [](std::shared_ptr<TestRunnerFixture> p_fixture) {  \
				m_callback(                                                    \
						static_cast<TEST_FIXTURE_NAME(m_fixture_name) &>(      \
								*p_fixture));                                  \
			});

#define xit(m_description, m_callback)                                         \
	TestRunnerInternal::_xit(m_description, m_callback);

#define xit_f(m_fixture_name, m_description, m_callback)                       \
	TestRunnerInternal::_xit_f(                                                \
			m_description, [](std::shared_ptr<TestRunnerFixture> p_fixture) {  \
				m_callback(                                                    \
						static_cast<TEST_FIXTURE_NAME(m_fixture_name) &>(      \
								*p_fixture));                                  \
			});

// clang-format off

#define START_TEST_F(m_fixture_name, m_module_name)                            \
	namespace godot {                                                          \
	TestRunnerModule TEST_MODULE_NAME(m_module_name) = TestRunnerModule {      \
		[]() {                                                                 \
			TestRunnerInternal::_describe_f(                                   \
				std::make_shared<TEST_FIXTURE_NAME(m_fixture_name)>(),         \
				#m_module_name, []() {

#define START_TEST(m_module_name)                                              \
	namespace godot {                                                          \
	TestRunnerModule TEST_MODULE_NAME(m_module_name) = TestRunnerModule {      \
		[]() {                                                                 \
			TestRunnerInternal::_describe(#m_module_name, []() {

#define FSTART_TEST_F(m_fixture_name, m_module_name)                           \
	namespace godot {                                                          \
	TestRunnerModule TEST_MODULE_NAME(m_module_name) = TestRunnerModule {      \
		[]() {                                                                 \
			TestRunnerInternal::_fdescribe_f(                                  \
				std::make_shared<TEST_FIXTURE_NAME(m_fixture_name)>(),         \
				#m_module_name, []() {

#define FSTART_TEST(m_module_name)                                             \
	namespace godot {                                                          \
	TestRunnerModule TEST_MODULE_NAME(m_module_name) = TestRunnerModule {      \
		[]() {                                                                 \
			TestRunnerInternal::_fdescribe(#m_module_name, []() {

#define XSTART_TEST_F(m_fixture_name, m_module_name)                           \
	namespace godot {                                                          \
	TestRunnerModule TEST_MODULE_NAME(m_module_name) = TestRunnerModule {      \
		[]() {                                                                 \
			TestRunnerInternal::_xdescribe_f(                                  \
				std::make_shared<TEST_FIXTURE_NAME(m_fixture_name)>(),         \
				#m_module_name, []() {

#define XSTART_TEST(m_module_name)                                             \
	namespace godot {                                                          \
	TestRunnerModule TEST_MODULE_NAME(m_module_name) = TestRunnerModule {      \
		[]() {                                                                 \
			TestRunnerInternal::_xdescribe(#m_module_name, []() {

#define END_TEST                                                               \
			});                                                                \
		}                                                                      \
	};                                                                         \
	} //namespace godot

// clang-format on

// clang-format off

#define START_TEST_FIXTURE(m_fixture_name)                                     \
	namespace godot {                                                          \
	struct TEST_FIXTURE_NAME(m_fixture_name) : public TestRunnerFixture {      \
	public:

#define END_TEST_FIXTURE                                                       \
	};                                                                         \
	} //namespace godot

// clang-format on

struct TestRunnerFixture_RotatedShape2 : public TestRunnerFixture {};

} //namespace godot

#endif // DEBUG_ENABLED

#endif // TEST_RUNNER_H

// FIXME: LEFT OFF HERE: -----------------------
// - Use smart pointers for TestRunnerFixture field on Suite.
// - Use smart pointers for Suite and Spec instances too.
// - Ensure that all Suites, Specs, and Fixtures are deallocated after running
//   tests.

// FIXME: LEFT OFF HERE: -----------------------
// - Added before/after each/all calls.
// - Next, add passing the fixture to it calls.
// - Then, make sure that actually configuring describes and it callbacks with
//   fixtures works.
