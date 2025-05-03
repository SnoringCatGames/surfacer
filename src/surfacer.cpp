#include "surfacer.h"

#include "test_runner.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void Surfacer::_bind_methods() {
	ClassDB::bind_static_method(
			"Surfacer", D_METHOD("run_tests"), &Surfacer::run_tests);
}

void Surfacer::run_tests() {
	// TODO: Swap these.
	// TestRunner::run_tests();
	TestRunner::run_tests_and_print_all();
}
