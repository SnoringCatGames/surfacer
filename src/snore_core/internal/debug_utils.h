#ifndef DEBUG_UTILS_H
#define DEBUG_UTILS_H

#include <godot_cpp/core/error_macros.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

// FIXME: Use this for various significant framework events.
#define _RAINBOW_BAR                                                           \
	"[color=red]=[/color][color=orange]=[/color][color=yellow]=[/color]"       \
	"[color=green]=[/color][color=blue]=[/color][color=purple]=[/color]"
#define _REVERSE_RAINBOW_BAR                                                   \
	"[color=purple]=[/color][color=blue]=[/color][color=green]=[/color]"       \
	"[color=yellow]=[/color][color=orange]=[/color][color=red]=[/color]"

String get_stack_trace();

#define PRINT_STACK_TRACE()                                                    \
	godot::UtilityFunctions::print_rich(                                       \
			"[color=gray]" + get_stack_trace() + "[/color]")

// Pauses execution if this isn't a release version of the Surfacer framework.
#if DEBUG_ENABLED
#ifdef _MSC_VER
#define DEBUG_BREAK() __debugbreak()
#else
#define DEBUG_BREAK() __builtin_debugtrap()
#endif
#else
#define DEBUG_BREAK()
#endif

// Ensures `m_cond` is true.
// - If `m_cond` is false, this prints `m_msg`, pauses execution, and returns
//   false.
// - If `m_cond` is true, this returns true.
// - Use `CHECK` instead if the error is unrecoverable.
#ifdef DEBUG_ENABLED
#define ENSURE(m_cond, m_msg)                                                  \
	(unlikely(!(m_cond))                                                       \
			 ? (::godot::_err_print_error(                                     \
						FUNCTION_STR, __FILE__, __LINE__,                      \
						"ENSURE failed  \"" _STR(m_cond) "\" is false.",       \
						m_msg),                                                \
				::godot::_err_flush_stdout(), PRINT_STACK_TRACE(),             \
				DEBUG_BREAK(), false)                                          \
			 : true)
#else
#define ENSURE(m_cond, m_msg) (m_cond)
#endif

#ifdef DEBUG_ENABLED
#define ENSURE_SIMPLE(m_cond)                                                  \
	(unlikely(!(m_cond))                                                       \
			 ? (::godot::_err_print_error(                                     \
						FUNCTION_STR, __FILE__, __LINE__,                      \
						"ENSURE failed  \"" _STR(m_cond) "\" is false."),      \
				::godot::_err_flush_stdout(), PRINT_STACK_TRACE(),             \
				DEBUG_BREAK(), false)                                          \
			 : true)
#else
#define ENSURE_SIMPLE(m_cond) (m_cond)
#endif

// This checks whether the condition is true. If not, the program will crash.
// Use `ENSURE` instead, if the error is recoverable.
#ifdef DEBUG_ENABLED
#define CHECK(m_cond, m_msg) CRASH_COND_MSG(!m_cond, m_msg)
#else
#define CHECK(m_cond, m_msg)
#endif

#ifdef DEBUG_ENABLED
#define CHECK_SIMPLE(m_cond) CRASH_COND(!m_cond)
#else
#define CHECK_SIMPLE(m_cond)
#endif

#ifdef DEBUG_ENABLED
#define LOG_DEBUG(m_msg)                                                       \
	godot::UtilityFunctions::print_rich(                                       \
			godot::vformat("[color=white][SC] %s[/color]", m_msg))
#else
#define LOG_DEBUG(m_msg)
#endif

#define LOG_PRINT(m_msg)                                                       \
	godot::UtilityFunctions::print_rich(                                       \
			godot::vformat("[color=white][SC] %s[/color]", m_msg))

#define LOG_WARNING(m_msg)                                                     \
	godot::UtilityFunctions::print_rich(                                       \
			godot::vformat("[color=yellow]WARNING [SC]: %s[/color]", m_msg))

#define LOG_ERROR(m_msg)                                                       \
	godot::UtilityFunctions::print_rich(                                       \
			godot::vformat("[color=red]ERROR [SC]: %s[/color]", m_msg))

} //namespace godot

#endif // DEBUG_UTILS_H
