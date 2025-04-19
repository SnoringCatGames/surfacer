#include "surfacer.h"

#include "test_main.h"

using namespace godot;

void Surfacer::_bind_methods() {
	ClassDB::bind_static_method(
			"Surfacer", D_METHOD("run_tests"), &Surfacer::run_tests);
}

void Surfacer::run_tests() { TestMain::run_tests(); }
