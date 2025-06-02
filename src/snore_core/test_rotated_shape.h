#ifdef DEBUG_ENABLED

#include "snore_core/rotated_shape.h"

#include "snore_core/test_runner.h"

#include <godot_cpp/classes/capsule_shape2d.hpp>
#include <godot_cpp/classes/circle_shape2d.hpp>
#include <godot_cpp/classes/rectangle_shape2d.hpp>

START_SCAFFOLDER_TEST(RotatedShape)

Ref<RotatedShape> rect_0_degrees;
Ref<RotatedShape> rect_90_degrees;
Ref<RotatedShape> rect_270_degrees;
Ref<RotatedShape> rect_180_degrees;
Ref<RotatedShape> capsule_0_degrees;
Ref<RotatedShape> capsule_90_degrees;
Ref<RotatedShape> circle_0_degrees;
Ref<RotatedShape> circle_90_degrees;

before_each([&]() {
	Ref<RectangleShape2D> rectangle = instantiate_ref<RectangleShape2D>();
	rectangle->set_size(Vector2(1, 2));

	Ref<CapsuleShape2D> capsule = instantiate_ref<CapsuleShape2D>();
	capsule->set_radius(1);
	capsule->set_height(1);

	Ref<CircleShape2D> circle = instantiate_ref<CircleShape2D>();
	circle->set_radius(1);

	rect_0_degrees = set_up_ref<RotatedShape>(rectangle, 0);
	rect_90_degrees = set_up_ref<RotatedShape>(rectangle, 90);
	rect_270_degrees = set_up_ref<RotatedShape>(rectangle, 270);
	rect_180_degrees = set_up_ref<RotatedShape>(rectangle, 180);
	capsule_0_degrees = set_up_ref<RotatedShape>(rectangle, 0);
	capsule_90_degrees = set_up_ref<RotatedShape>(rectangle, 90);
	circle_0_degrees = set_up_ref<RotatedShape>(rectangle, 0);
	circle_90_degrees = set_up_ref<RotatedShape>(rectangle, 90);
});

after_each([&]() {
	rect_0_degrees.unref();
	rect_90_degrees.unref();
	rect_270_degrees.unref();
	rect_180_degrees.unref();
	capsule_0_degrees.unref();
	capsule_90_degrees.unref();
	circle_0_degrees.unref();
	circle_90_degrees.unref();
});

it("get_is_rotated_90_degrees", [&]() {
	Expect(rect_0_degrees->get_is_rotated_90_degrees(), false);
	Expect(rect_90_degrees->get_is_rotated_90_degrees(), true);
	Expect(rect_270_degrees->get_is_rotated_90_degrees(), true);
	Expect(rect_180_degrees->get_is_rotated_90_degrees(), false);
	Expect(capsule_0_degrees->get_is_rotated_90_degrees(), false);
	Expect(capsule_90_degrees->get_is_rotated_90_degrees(), true);
	Expect(circle_0_degrees->get_is_rotated_90_degrees(), false);
	Expect(circle_90_degrees->get_is_rotated_90_degrees(), true);
});

it("get_is_axially_aligned", [&]() {
	Expect(rect_0_degrees->get_is_axially_aligned(), true);
	Expect(rect_90_degrees->get_is_axially_aligned(), true);
	Expect(rect_270_degrees->get_is_axially_aligned(), true);
	Expect(rect_180_degrees->get_is_axially_aligned(), true);
	Expect(capsule_0_degrees->get_is_axially_aligned(), true);
	Expect(capsule_90_degrees->get_is_axially_aligned(), true);
	Expect(circle_0_degrees->get_is_axially_aligned(), true);
	Expect(circle_90_degrees->get_is_axially_aligned(), true);
});

it("get_half_width_height", [&]() {
	Expect(rect_0_degrees->get_half_width_height(), Vector2(0.5f, 1));
	Expect(rect_90_degrees->get_half_width_height(), Vector2(0.5f, 1));
	Expect(rect_270_degrees->get_half_width_height(), Vector2(0.5f, 1));
	Expect(rect_180_degrees->get_half_width_height(), Vector2(0.5f, 1));
	Expect(capsule_0_degrees->get_half_width_height(), Vector2(1.5f, 0.5f));
	Expect(capsule_90_degrees->get_half_width_height(), Vector2(0.5f, 1.5f));
	Expect(circle_0_degrees->get_half_width_height(), Vector2(1, 1));
	Expect(circle_90_degrees->get_half_width_height(), Vector2(1, 1));
});

END_SCAFFOLDER_TEST

#endif // DEBUG_ENABLED
