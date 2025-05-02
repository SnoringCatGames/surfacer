#ifndef TESTER_H
#define TESTER_H

#include "SFT.hpp"

#include <functional>
#include <godot_cpp/variant/string.hpp>

// FIXME: LEFT OFF HERE: -------------------------------
// - AFTER TESTING describe() and it() with a simple test in test_surface.h.
//   - Only print failing tests. Don't print passing tests.
// - Ensure test logic isn't included except in dev builds.
// - Setup CI and presubmits!

namespace Tester {

namespace {

bool are_any_tests_focused = false;
bool print_all_results = false;

struct TesterDescribable {
	const char *description;
};

struct TesterCallable {
	std::function<void()> callback;
};

struct TesterFocusable {
	bool is_focused = false;
	bool is_excluded = false;

	bool should_run() const {
		return is_focused || (!are_any_tests_focused && !is_excluded);
	}
};

struct Unit : public TesterFocusable,
			  public TesterCallable,
			  public TesterDescribable {};

struct Suite : public TesterFocusable,
			   public TesterCallable,
			   public TesterDescribable {
	std::vector<Unit> units;
	std::vector<Suite> suites;
	std::vector<TesterCallable> before_eaches;
	std::vector<TesterCallable> after_eaches;
	std::vector<TesterCallable> before_alls;
	std::vector<TesterCallable> after_alls;
};

Suite root_suite;
Suite *parsing_suite = &root_suite;

void create_suite(
		const char *p_description,
		const std::function<void()> &p_callback,
		bool p_is_focused,
		bool p_is_excluded) {
	if (p_is_focused) {
		are_any_tests_focused = true;
	}

	Suite suite;
	suite.description = p_description;
	suite.callback = p_callback;
	suite.is_focused = p_is_focused || parsing_suite->is_focused;
	suite.is_excluded = p_is_excluded || parsing_suite->is_excluded;

	Suite *parent_suite = parsing_suite;
	parsing_suite = &suite;

	suite.callback();

	parsing_suite = parent_suite;
	parent_suite->suites.push_back(std::move(suite));
}

void create_unit(
		const char *p_description,
		const std::function<void()> &p_callback,
		bool p_is_focused,
		bool p_is_excluded) {
	if (p_is_focused) {
		are_any_tests_focused = true;
	}

	Unit unit;
	unit.description = p_description;
	unit.callback = p_callback;
	unit.is_focused = p_is_focused || parsing_suite->is_focused;
	unit.is_excluded = p_is_excluded || parsing_suite->is_excluded;

	parsing_suite->units.push_back(std::move(unit));
}

void run_suite(const Suite &p_suite) {
	// Execute any before_all.
	for (const TesterCallable &callable : p_suite.before_alls) {
		callable.callback();
	}

	// Execute units for this suite.
	for (const Unit &unit : p_suite.units) {
		if (unit.should_run()) {
			// Execute any before_each.
			for (const TesterCallable &callable : p_suite.before_eaches) {
				callable.callback();
			}

			unit.callback();

			// Execute any after_each.
			for (const TesterCallable &callable : p_suite.after_eaches) {
				callable.callback();
			}
		}
	}

	// Recurse.
	for (const Suite &suite : p_suite.suites) {
		if (suite.should_run()) {
			run_suite(suite);
		}
	}

	// Execute any after_all.
	for (const TesterCallable &callable : p_suite.after_alls) {
		callable.callback();
	}
}

} //namespace

void describe(
		const char *p_description,
		const std::function<void()> &p_callback) {
	create_suite(p_description, p_callback, false, false);
}

void it(const char *p_description, const std::function<void()> &p_callback) {
	create_unit(p_description, p_callback, false, false);
}

void fdescribe(
		const char *p_description,
		const std::function<void()> &p_callback) {
	create_suite(p_description, p_callback, true, false);
}

void fit(const char *p_description, const std::function<void()> &p_callback) {
	create_unit(p_description, p_callback, true, false);
}

void xdescribe(
		const char *p_description,
		const std::function<void()> &p_callback) {
	create_suite(p_description, p_callback, false, true);
}

void xit(const char *p_description, const std::function<void()> &p_callback) {
	create_unit(p_description, p_callback, false, true);
}

void before_each(const std::function<void()> &p_callback) {
	TesterCallable callable;
	callable.callback = p_callback;

	parsing_suite->before_eaches.push_back(std::move(callable));
}

void after_each(const std::function<void()> &p_callback) {
	TesterCallable callable;
	callable.callback = p_callback;

	parsing_suite->after_eaches.push_back(std::move(callable));
}

void before_all(const std::function<void()> &p_callback) {
	TesterCallable callable;
	callable.callback = p_callback;

	parsing_suite->before_alls.push_back(std::move(callable));
}

void after_all(const std::function<void()> &p_callback) {
	TesterCallable callable;
	callable.callback = p_callback;

	parsing_suite->after_alls.push_back(std::move(callable));
}

void run_tests() {
	print_all_results = false;
	run_suite(root_suite);
}

void run_tests_and_print_all() {
	print_all_results = true;
	run_suite(root_suite);
}

} //namespace Tester

#endif
