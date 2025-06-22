#ifndef TEST_SURFACER_MODULE_H
#define TEST_SURFACER_MODULE_H

#ifdef DEBUG_ENABLED

#include "surfacer/surfacer_module.h"

#include "snore_core/test_runner/test_runner.h"

START_TEST(Surfacer)

it("TODO", []() {
	// TODO
	// expect(Surface::get_normal_from_side(Surface::Side::FLOOR),
	// 	   Vector2(0, -1));
});

END_TEST

#endif // DEBUG_ENABLED

#endif // TEST_SURFACER_MODULE_H
