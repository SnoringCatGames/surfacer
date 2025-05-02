#include "surfacer.h"

#include "tester.h"

using namespace godot;

void Surfacer::_bind_methods() {
	ClassDB::bind_static_method(
			"Surfacer", D_METHOD("run_tests"), &Surfacer::run_tests);
}

void Surfacer::run_tests() {
	// FIXME: Swap these.
	// Tester::run_tests();
	Tester::run_tests_and_print_all();
}
