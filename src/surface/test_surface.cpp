#ifdef DEBUG_ENABLED

#include "surface.h"
#include "test_runner.h"

test_space([]() {
	describe("Surface", []() {
		it("get_normal_from_side", []() {
			Expect(Surface::get_normal_from_side(Surface::Side::FLOOR),
				   Vector2(0, -1));
			Expect(Surface::get_normal_from_side(Surface::Side::CEILING),
				   Vector2(0, 1));
			Expect(Surface::get_normal_from_side(Surface::Side::LEFT_WALL),
				   Vector2(1, 0));
			Expect(Surface::get_normal_from_side(Surface::Side::RIGHT_WALL),
				   Vector2(-1, 0));
			Expect(Surface::get_normal_from_side(Surface::Side::UNKNOWN_SIDE),
				   vector2_invalid);
		});
	});
});

#endif // DEBUG_ENABLED
