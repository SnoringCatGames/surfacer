#ifndef TEST_ANNOTATION_H
#define TEST_ANNOTATION_H

#ifdef DEBUG_ENABLED

#include "snore_core/annotation.h"

#include "snore_core/test_runner/test_runner.h"

START_TEST(Annotation)

it("TODO", []() {
	// TODO
	// expect(Surface::get_normal_from_side(Surface::Side::FLOOR),
	// 	   Vector2(0, -1));
});

END_TEST

#endif // DEBUG_ENABLED

#endif // TEST_ANNOTATION_H
