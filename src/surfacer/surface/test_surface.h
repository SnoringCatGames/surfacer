#ifndef TEST_SURFACE_H
#define TEST_SURFACE_H

#ifdef DEBUG_ENABLED

#include "snore_core/geometry_constants.h"
#include "surfacer/surface/surface.h"

#include "snore_core/test_runner.h"

START_SNORE_CORE_TEST(Surface)

it("get_normal_from_side", []() {
	Expect(Surface::get_normal_from_side(Surface::Side::FLOOR), Vector2(0, -1));
	Expect(Surface::get_normal_from_side(Surface::Side::CEILING),
		   Vector2(0, 1));
	Expect(Surface::get_normal_from_side(Surface::Side::LEFT_WALL),
		   Vector2(1, 0));
	Expect(Surface::get_normal_from_side(Surface::Side::RIGHT_WALL),
		   Vector2(-1, 0));
	Expect(Surface::get_normal_from_side(Surface::Side::UNKNOWN_SIDE),
		   vector2_invalid);
});

END_SNORE_CORE_TEST

#endif // DEBUG_ENABLED

#endif // TEST_SURFACE_H
