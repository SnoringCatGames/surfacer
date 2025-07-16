#ifndef TEST_ROTATED_SHAPE_H
#define TEST_ROTATED_SHAPE_H

#ifdef DEBUG_ENABLED

#include "snore_core/rotated_shape.h"

#include <gtest/gtest.h>

#include <godot_cpp/classes/capsule_shape2d.hpp>
#include <godot_cpp/classes/circle_shape2d.hpp>
#include <godot_cpp/classes/rectangle_shape2d.hpp>

// // FIXME

// 	Ref<RotatedShape> rect_0_degrees;
// 	Ref<RotatedShape> rect_90_degrees;
// 	Ref<RotatedShape> rect_270_degrees;
// 	Ref<RotatedShape> rect_180_degrees;
// 	Ref<RotatedShape> capsule_0_degrees;
// 	Ref<RotatedShape> capsule_90_degrees;
// 	Ref<RotatedShape> circle_0_degrees;
// 	Ref<RotatedShape> circle_90_degrees;

// 	virtual void before_each() override {
// 		Ref<RectangleShape2D> rectangle = instantiate_ref<RectangleShape2D>();
// 		rectangle->set_size(Vector2(1, 2));

// 		Ref<CapsuleShape2D> capsule = instantiate_ref<CapsuleShape2D>();
// 		capsule->set_radius(1);
// 		capsule->set_height(1);

// 		Ref<CircleShape2D> circle = instantiate_ref<CircleShape2D>();
// 		circle->set_radius(1);

// 		rect_0_degrees = set_up_ref<RotatedShape>(rectangle, 0);
// 		rect_90_degrees = set_up_ref<RotatedShape>(rectangle, 90);
// 		rect_270_degrees = set_up_ref<RotatedShape>(rectangle, 270);
// 		rect_180_degrees = set_up_ref<RotatedShape>(rectangle, 180);
// 		capsule_0_degrees = set_up_ref<RotatedShape>(capsule, 0);
// 		capsule_90_degrees = set_up_ref<RotatedShape>(capsule, 90);
// 		circle_0_degrees = set_up_ref<RotatedShape>(circle, 0);
// 		circle_90_degrees = set_up_ref<RotatedShape>(circle, 90);
// 	}

// 	virtual void after_each() override {
// 		rect_0_degrees.unref();
// 		rect_90_degrees.unref();
// 		rect_270_degrees.unref();
// 		rect_180_degrees.unref();
// 		capsule_0_degrees.unref();
// 		capsule_90_degrees.unref();
// 		circle_0_degrees.unref();
// 		circle_90_degrees.unref();
// 	}

// it_f(RotatedShape,
// 	 "get_is_rotated_90_degrees",
// 	 [&](TestRunnerFixture_RotatedShape &f) {
// 		 expect(f.rect_0_degrees->get_is_rotated_90_degrees(), false);
// 		 expect(f.rect_90_degrees->get_is_rotated_90_degrees(), true);
// 		 expect(f.rect_270_degrees->get_is_rotated_90_degrees(), true);
// 		 expect(f.rect_180_degrees->get_is_rotated_90_degrees(), false);
// 		 expect(f.capsule_0_degrees->get_is_rotated_90_degrees(), false);
// 		 expect(f.capsule_90_degrees->get_is_rotated_90_degrees(), true);
// 		 expect(f.circle_0_degrees->get_is_rotated_90_degrees(), false);
// 		 expect(f.circle_90_degrees->get_is_rotated_90_degrees(), true);
// 	 });

// it_f(RotatedShape,
// 	 "get_is_axially_aligned",
// 	 [&](TestRunnerFixture_RotatedShape &f) {
// 		 expect(f.rect_0_degrees->get_is_axially_aligned(), true);
// 		 expect(f.rect_90_degrees->get_is_axially_aligned(), true);
// 		 expect(f.rect_270_degrees->get_is_axially_aligned(), true);
// 		 expect(f.rect_180_degrees->get_is_axially_aligned(), true);
// 		 expect(f.capsule_0_degrees->get_is_axially_aligned(), true);
// 		 expect(f.capsule_90_degrees->get_is_axially_aligned(), true);
// 		 expect(f.circle_0_degrees->get_is_axially_aligned(), true);
// 		 expect(f.circle_90_degrees->get_is_axially_aligned(), true);
// 	 });

// it_f(RotatedShape,
// 	 "get_half_width_height",
// 	 [&](TestRunnerFixture_RotatedShape &f) {
// 		 expect(f.rect_0_degrees->get_half_width_height(), Vector2(0.5f, 1));
// 		 expect(f.rect_90_degrees->get_half_width_height(), Vector2(0.5f, 1));
// 		 expect(f.rect_270_degrees->get_half_width_height(), Vector2(0.5f, 1));
// 		 expect(f.rect_180_degrees->get_half_width_height(), Vector2(0.5f, 1));
// 		 expect(f.capsule_0_degrees->get_half_width_height(),
// 				Vector2(1.5f, 0.5f));
// 		 expect(f.capsule_90_degrees->get_half_width_height(),
// 				Vector2(0.5f, 1.5f));
// 		 expect(f.circle_0_degrees->get_half_width_height(), Vector2(1, 1));
// 		 expect(f.circle_90_degrees->get_half_width_height(), Vector2(1, 1));
// 	 });

// FIXME: LEFT OFF HERE: -------------------------------

TEST(HelloTestCase, HelloTest) {
	EXPECT_EQ(2, 1 + 1);
	// EXPECT_EQ(3, 2 + 2);
}

#endif // DEBUG_ENABLED

#endif // TEST_ROTATED_SHAPE_H
