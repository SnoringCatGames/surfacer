#ifndef GEOMETRY_CONSTANTS_H
#define GEOMETRY_CONSTANTS_H

#include <godot_cpp/variant/vector2.hpp>

namespace godot {

// Infinity is used rather than NaN to avoid issues with NaN comparisons.
static const Vector2 vector2_invalid = Vector2(INFINITY, INFINITY);
static const Vector2 vector2_zero = Vector2(0, 0);
static const Vector2 vector2_one = Vector2(1, 1);
static const Vector2 vector2_up = Vector2(0, -1);
static const Vector2 vector2_down = Vector2(0, 1);
static const Vector2 vector2_left = Vector2(-1, 0);
static const Vector2 vector2_right = Vector2(1, 0);

constexpr float float_epsilon = 0.00001f;
constexpr double HALF_PI = Math_PI / 2.0;
constexpr double QUARTER_PI = Math_PI / 4.0;

} //namespace godot

#endif // GEOMETRY_CONSTANTS_H
