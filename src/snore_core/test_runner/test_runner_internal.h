#ifndef TEST_RUNNER_INTERNAL_H
#define TEST_RUNNER_INTERNAL_H

#ifdef DEBUG_ENABLED

#include "snore_core/internal/internal_debug_utils.h"

#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <functional>
#include <memory>
#include <optional>
#include <string>

namespace godot {

class TestRunnerSuite;
class TestRunner;

struct TestRunnerFixture {
	// FIXME: Limit access?
public:
	virtual void before_all() {}
	virtual void after_all() {}

	virtual void before_each() {}
	virtual void after_each() {}
};

using CallbackWithoutFixture = std::function<void()>;
using CallbackWithFixture =
		std::function<void(std::shared_ptr<TestRunnerFixture>)>;

// The macro START_TEST registers a TestRunnerModule for the given
// test file. `callback` should contain invocation(s) of `describe` and will be
// invoked when running the tests.
struct TestRunnerModule {
	const CallbackWithoutFixture callback;
};

class TestRunnerDescribable {
public:
	std::string description;
};

class TestRunnerFocusable {
public:
	TestRunner *runner;
	bool is_focused = false;
	bool is_excluded = false;

	bool should_run() const;
};

class TestRunnerSpec : public TestRunnerDescribable,
					   public TestRunnerFocusable {
public:
	TestRunnerSuite *suite = nullptr;

	std::optional<CallbackWithoutFixture> callback;
	std::optional<CallbackWithFixture> callback_with_fixture;

	void run();
};

class TestRunnerSuite : public TestRunnerDescribable,
						public TestRunnerFocusable {
public:
	TestRunnerSuite *parent_suite = nullptr;
	std::shared_ptr<TestRunnerFixture> fixture;
	std::vector<TestRunnerSpec> specs;
	std::vector<TestRunnerSuite> suites;

	CallbackWithoutFixture callback;

	godot::String get_combined_rich_description() const;

	void run();

	void before_spec();
	void after_spec();
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
			std::shared_ptr<TestRunnerFixture> p_fixture,
			std::string &&p_description,
			CallbackWithoutFixture &&p_callback,
			bool p_is_focused,
			bool p_is_excluded);
	void create_suite(
			std::string &&p_description,
			CallbackWithoutFixture &&p_callback,
			bool p_is_focused,
			bool p_is_excluded) {
		create_suite(
				nullptr, std::move(p_description), std::move(p_callback),
				p_is_focused, p_is_excluded);
	}

	void create_spec(
			std::string &&p_description,
			std::optional<CallbackWithFixture> p_callback_with_fixture,
			std::optional<CallbackWithoutFixture> p_callback,
			bool p_is_focused,
			bool p_is_excluded);
	void create_spec(
			std::string &&p_description,
			CallbackWithFixture &&p_callback,
			bool p_is_focused,
			bool p_is_excluded) {
		create_spec(
				std::move(p_description), std::move(p_callback), std::nullopt,
				p_is_focused, p_is_excluded);
	}
	void create_spec(
			std::string &&p_description,
			CallbackWithoutFixture &&p_callback,
			bool p_is_focused,
			bool p_is_excluded) {
		create_spec(
				std::move(p_description), std::nullopt, std::move(p_callback),
				p_is_focused, p_is_excluded);
	}

	void run_all_tests();
};

namespace TestRunnerInternal {

extern TestRunner runner;

_FORCE_INLINE_ void _describe(
		std::string &&p_description,
		CallbackWithoutFixture &&p_callback) {
	TestRunnerInternal::runner.create_suite(
			std::move(p_description), std::move(p_callback), false, false);
}

_FORCE_INLINE_ void _describe_f(
		std::shared_ptr<TestRunnerFixture> p_fixture,
		std::string &&p_description,
		CallbackWithoutFixture &&p_callback) {
	TestRunnerInternal::runner.create_suite(
			std::move(p_fixture), std::move(p_description),
			std::move(p_callback), false, false);
}

_FORCE_INLINE_ void _fdescribe(
		std::string &&p_description,
		CallbackWithoutFixture &&p_callback) {
	TestRunnerInternal::runner.create_suite(
			std::move(p_description), std::move(p_callback), true, false);
}

_FORCE_INLINE_ void _fdescribe_f(
		std::shared_ptr<TestRunnerFixture> p_fixture,
		std::string &&p_description,
		CallbackWithoutFixture &&p_callback) {
	TestRunnerInternal::runner.create_suite(
			std::move(p_fixture), std::move(p_description),
			std::move(p_callback), true, false);
}

_FORCE_INLINE_ void _xdescribe(
		std::string &&p_description,
		CallbackWithoutFixture &&p_callback) {
	TestRunnerInternal::runner.create_suite(
			std::move(p_description), std::move(p_callback), false, true);
}

_FORCE_INLINE_ void _xdescribe_f(
		std::shared_ptr<TestRunnerFixture> p_fixture,
		std::string &&p_description,
		CallbackWithoutFixture &&p_callback) {
	TestRunnerInternal::runner.create_suite(
			std::move(p_fixture), std::move(p_description),
			std::move(p_callback), false, true);
}

_FORCE_INLINE_ void _it(
		std::string &&p_description,
		CallbackWithoutFixture &&p_callback) {
	TestRunnerInternal::runner.create_spec(
			std::move(p_description), std::move(p_callback), false, false);
}

_FORCE_INLINE_ void _it_f(
		std::string &&p_description,
		CallbackWithFixture &&p_callback) {
	TestRunnerInternal::runner.create_spec(
			std::move(p_description), std::move(p_callback), false, false);
}

_FORCE_INLINE_ void _fit(
		std::string &&p_description,
		CallbackWithoutFixture &&p_callback) {
	TestRunnerInternal::runner.create_spec(
			std::move(p_description), std::move(p_callback), true, false);
}

_FORCE_INLINE_ void _fit_f(
		std::string &&p_description,
		CallbackWithFixture &&p_callback) {
	TestRunnerInternal::runner.create_spec(
			std::move(p_description), std::move(p_callback), true, false);
}

_FORCE_INLINE_ void _xit(
		std::string &&p_description,
		CallbackWithoutFixture &&p_callback) {
	TestRunnerInternal::runner.create_spec(
			std::move(p_description), std::move(p_callback), false, true);
}

_FORCE_INLINE_ void _xit_f(
		std::string &&p_description,
		CallbackWithFixture &&p_callback) {
	TestRunnerInternal::runner.create_spec(
			std::move(p_description), std::move(p_callback), false, true);
}

} //namespace TestRunnerInternal

} //namespace godot

#endif // DEBUG_ENABLED

#endif // TEST_RUNNER_INTERNAL_H
