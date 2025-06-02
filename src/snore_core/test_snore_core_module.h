#ifndef TEST_SNORE_CORE_MODULE_H
#define TEST_SNORE_CORE_MODULE_H

#ifdef DEBUG_ENABLED

#include "snore_core/snore_core_module.h"

#include "snore_core/test_runner.h"

START_SNORE_CORE_TEST(SnoreCoreModule)

it("TODO", []() {
	// TODO
	// Expect(Surface::get_normal_from_side(Surface::Side::FLOOR),
	// 	   Vector2(0, -1));
});

END_SNORE_CORE_TEST

#endif // DEBUG_ENABLED

#endif // TEST_SNORE_CORE_MODULE_H
