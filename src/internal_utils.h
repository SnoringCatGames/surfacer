#ifndef INTERNAL_UTILS_H
#define INTERNAL_UTILS_H

#include <godot_cpp/core/error_macros.hpp>
#include <godot_cpp/variant/vector2.hpp>

// TODO: Update this when no longer debugging Surfacer.
#define IS_SURFACER_RELEASE false

// Pauses execution if this isn't a release version of the Surfacer framework.
#if !IS_SURFACER_RELEASE
#ifdef _MSC_VER
#define DEBUG_BREAK() __debugbreak()
#else
#define DEBUG_BREAK() __builtin_debugtrap()
#endif
#else
#define DEBUG_BREAK()
#endif

// Ensures `m_cond` is true.
// - If `m_cond` is true, this prints `m_msg`, pauses execution, and evaluates to true.
// - If `m_cond` is false, this evaluates to false.
#ifdef DEBUG_ENABLED
#define ENSURE(m_cond, m_msg)                                                                                                \
(                                                                                                                            \
	unlikely(!(m_cond)) ?                                                                                                    \
	(                                                                                                                        \
		::godot::_err_print_error(FUNCTION_STR, __FILE__, __LINE__, "ENSURE failed  \"" _STR(m_cond) "\" is false.", m_msg), \
		::godot::_err_flush_stdout(),                                                                                        \
		DEBUG_BREAK(),                                                                                                       \
		false                                                                                                                \
	) :                                                                                                                      \
	true                                                                                                                     \
)
#else
#define ENSURE(m_cond, m_msg) (m_cond)
#endif

#ifdef DEBUG_ENABLED
#define ENSURE_SIMPLE(m_cond)                                                                                         \
(                                                                                                                     \
	unlikely(!(m_cond)) ?                                                                                             \
	(                                                                                                                 \
		::godot::_err_print_error(FUNCTION_STR, __FILE__, __LINE__, "ENSURE failed  \"" _STR(m_cond) "\" is false."), \
		::godot::_err_flush_stdout(),                                                                                 \
		DEBUG_BREAK(),                                                                                                \
		false                                                                                                         \
	) :                                                                                                               \
	true                                                                                                              \
)
#else
#define ENSURE_SIMPLE(m_cond) (m_cond)
#endif

namespace godot {
	static const Vector2 Vector2Up = Vector2(0, -1);
	static const Vector2 Vector2Down = Vector2(0, 1);
	static const Vector2 Vector2Left = Vector2(-1, 0);
	static const Vector2 Vector2Right = Vector2(1, 0);
	static const Vector2 Vector2Zero = Vector2(0, 0);
	static const Vector2 Vector2NaN = Vector2(Math_NAN, Math_NAN);
}

#endif
