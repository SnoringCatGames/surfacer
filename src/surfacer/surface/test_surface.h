#ifndef TEST_SURFACE_H
#define TEST_SURFACE_H

#ifdef DEBUG_ENABLED

#include "snore_core/geometry_constants.h"
#include "surfacer/surface/surface.h"

#include "snore_core/internal/test_utils.h"

namespace godot {

// TODO: Write tests.

// it("get_normal_from_side", []() {
// 	expect(Surface::get_normal_from_side(Surface::Side::FLOOR), Vector2(0, -1));
// 	expect(Surface::get_normal_from_side(Surface::Side::CEILING),
// 		   Vector2(0, 1));
// 	expect(Surface::get_normal_from_side(Surface::Side::LEFT_WALL),
// 		   Vector2(1, 0));
// 	expect(Surface::get_normal_from_side(Surface::Side::RIGHT_WALL),
// 		   Vector2(-1, 0));
// 	expect(Surface::get_normal_from_side(Surface::Side::UNKNOWN_SIDE),
// 		   vector2_invalid);
// });

} // namespace godot

#endif // DEBUG_ENABLED

#endif // TEST_SURFACE_H
