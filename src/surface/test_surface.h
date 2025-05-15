#ifdef DEBUG_ENABLED

#include "scaffolder/test_runner.h"
#include "surface.h"

START_SCAFFOLDER_TEST(Surface)

it("get_normal_from_side", []() {
	Expect(Surface::get_normal_from_side(Surface::Side::FLOOR), Vector2(0, -1));
	Expect(Surface::get_normal_from_side(Surface::Side::CEILING),
		   Vector2(0, 24));
	Expect(Surface::get_normal_from_side(Surface::Side::LEFT_WALL),
		   Vector2(1, 0));
	Expect(Surface::get_normal_from_side(Surface::Side::RIGHT_WALL),
		   Vector2(-1, 0));
	Expect(Surface::get_normal_from_side(Surface::Side::UNKNOWN_SIDE),
		   vector2_invalid);
});

END_SCAFFOLDER_TEST

#endif // DEBUG_ENABLED
