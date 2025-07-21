#ifndef TEST_ROTATED_SHAPE_H
#define TEST_ROTATED_SHAPE_H

#ifdef SC_TESTS_ENABLED

#include "snore_core/geometry_constants.h"
#include "snore_core/internal/ref_utils.h"
#include "snore_core/internal/test_utils.h"
#include "snore_core/rotated_shape.h"

#include "snore_core/internal/test_utils.h"
#include <godot_cpp/classes/capsule_shape2d.hpp>
#include <godot_cpp/classes/circle_shape2d.hpp>
#include <godot_cpp/classes/rectangle_shape2d.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

class RotatedShapeTest : public ::testing::Test {
protected:
	void SetUp() override {
		// Create shape objects.
		Ref<RectangleShape2D> rectangle = instantiate_ref<RectangleShape2D>();
		rectangle->set_size(Vector2(1, 2));

		Ref<CapsuleShape2D> capsule = instantiate_ref<CapsuleShape2D>();
		capsule->set_radius(1);
		capsule->set_height(4);

		Ref<CircleShape2D> circle = instantiate_ref<CircleShape2D>();
		circle->set_radius(1);

		// Create RotatedShape objects with different rotations.
		rect_0_degrees = set_up_ref<RotatedShape>(rectangle, 0.0);
		rect_90_degrees = set_up_ref<RotatedShape>(rectangle, HALF_PI);
		rect_180_degrees = set_up_ref<RotatedShape>(rectangle, Math_PI);
		rect_270_degrees = set_up_ref<RotatedShape>(rectangle, -HALF_PI);
		capsule_0_degrees = set_up_ref<RotatedShape>(capsule, 0.0);
		capsule_90_degrees = set_up_ref<RotatedShape>(capsule, HALF_PI);
		circle_0_degrees = set_up_ref<RotatedShape>(circle, 0.0);
		circle_90_degrees = set_up_ref<RotatedShape>(circle, HALF_PI);
	}

	void TearDown() override {
		// Clean up references.
		rect_0_degrees.unref();
		rect_90_degrees.unref();
		rect_180_degrees.unref();
		rect_270_degrees.unref();
		capsule_0_degrees.unref();
		capsule_90_degrees.unref();
		circle_0_degrees.unref();
		circle_90_degrees.unref();
	}

	Ref<RotatedShape> rect_0_degrees;
	Ref<RotatedShape> rect_90_degrees;
	Ref<RotatedShape> rect_180_degrees;
	Ref<RotatedShape> rect_270_degrees;
	Ref<RotatedShape> capsule_0_degrees;
	Ref<RotatedShape> capsule_90_degrees;
	Ref<RotatedShape> circle_0_degrees;
	Ref<RotatedShape> circle_90_degrees;
};

TEST_F(RotatedShapeTest, GetIsRotated90Degrees) {
	EXPECT_FALSE(rect_0_degrees->get_is_rotated_90_degrees());
	EXPECT_TRUE(rect_90_degrees->get_is_rotated_90_degrees());
	EXPECT_FALSE(rect_180_degrees->get_is_rotated_90_degrees());
	EXPECT_TRUE(rect_270_degrees->get_is_rotated_90_degrees());
	EXPECT_FALSE(capsule_0_degrees->get_is_rotated_90_degrees());
	EXPECT_TRUE(capsule_90_degrees->get_is_rotated_90_degrees());
	EXPECT_FALSE(circle_0_degrees->get_is_rotated_90_degrees());
	EXPECT_TRUE(circle_90_degrees->get_is_rotated_90_degrees());
}

TEST_F(RotatedShapeTest, GetIsAxiallyAligned) {
	EXPECT_TRUE(rect_0_degrees->get_is_axially_aligned());
	EXPECT_TRUE(rect_90_degrees->get_is_axially_aligned());
	EXPECT_TRUE(rect_270_degrees->get_is_axially_aligned());
	EXPECT_TRUE(rect_180_degrees->get_is_axially_aligned());
	EXPECT_TRUE(capsule_0_degrees->get_is_axially_aligned());
	EXPECT_TRUE(capsule_90_degrees->get_is_axially_aligned());
	EXPECT_TRUE(circle_0_degrees->get_is_axially_aligned());
	EXPECT_TRUE(circle_90_degrees->get_is_axially_aligned());
}

TEST_F(RotatedShapeTest, GetHalfWidthHeight) {
	EXPECT_VECTOR2_EQ(
			Vector2(0.5f, 1), rect_0_degrees->get_half_width_height());
	EXPECT_VECTOR2_EQ(
			Vector2(1, 0.5f), rect_90_degrees->get_half_width_height());
	EXPECT_VECTOR2_EQ(
			Vector2(0.5f, 1), rect_180_degrees->get_half_width_height());
	EXPECT_VECTOR2_EQ(
			Vector2(1, 0.5f), rect_270_degrees->get_half_width_height());
	EXPECT_VECTOR2_EQ(
			Vector2(1, 2), capsule_0_degrees->get_half_width_height());
	EXPECT_VECTOR2_EQ(
			Vector2(2, 1), capsule_90_degrees->get_half_width_height());
	EXPECT_VECTOR2_EQ(Vector2(1, 1), circle_0_degrees->get_half_width_height());
	EXPECT_VECTOR2_EQ(
			Vector2(1, 1), circle_90_degrees->get_half_width_height());
}

} // namespace godot

#endif // SC_TESTS_ENABLED

#endif // TEST_ROTATED_SHAPE_H
