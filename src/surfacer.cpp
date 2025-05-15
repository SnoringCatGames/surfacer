#include "surfacer.h"

#include "scaffolder/test_runner.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void Surfacer::_bind_methods() {
	ClassDB::bind_static_method(
			"Surfacer", D_METHOD("run_tests"), &Surfacer::run_tests);
}

void Surfacer::run_tests() {
	// TODO: Swap these.
	// test_runner::run_tests();
	test_runner::run_tests_verbose();
}
