#ifndef INTERNAL_UTILS_H
#define INTERNAL_UTILS_H

#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/core/error_macros.hpp>
#include <godot_cpp/variant/variant.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

// TODO: Update this when no longer debugging Surfacer.
#define IS_SURFACER_RELEASE false

#define IS_VALID_REF(m_ref) (m_ref.is_valid() && IS_VALID_OBJECT(m_ref.ptr()))
#define IS_VALID_OBJECT(m_object_ptr) (m_object_ptr != nullptr)

constexpr char *PROCESS_MODE_HINT_STRING =
		"INHERIT,PAUSABLE,WHEN_PAUSED,ALWAYS,DISABLED";

constexpr uint64_t PROPERTY_USAGE_EXPORTED_ITEM = PROPERTY_USAGE_STORAGE |
		PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_SCRIPT_VARIABLE;

#define EXPORTED_PROPERTY_INFO(type, name)                                     \
	PropertyInfo(                                                              \
			type, name, PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EXPORTED_ITEM)
#define EXPORTED_PROPERTY_INFO_WITH_HINT(type, name, hint_type, hint_string)   \
	PropertyInfo(                                                              \
			type, name, hint_type, hint_string, PROPERTY_USAGE_EXPORTED_ITEM)

template <typename T> Ref<T> instantiate_ref() {
	Ref<T> ref;
	ref.instantiate();
	return ref;
}

// FIXME: Go through and update classes to use set_up.

// A common pattern in Scaffolder is to use a SetUp method to initialize an
// object with arguments, since GDExtension doesn't currently support
// constructor arguments.
//
// This function will both instantiate a Ref containing the object and call
// set_up with the given arguments.
template <typename T, typename... Args> Ref<T> set_up_ref(Args... args) {
	Ref<T> ref;
	ref.instantiate();
	ref->set_up(args...);
	return ref;
}

static String join_strings(
		const char *const arr[],
		size_t size,
		const char *delimiter) {
	String result;
	for (size_t i = 0; i < size; ++i) {
		result += arr[i];
		if (i < size - 1) {
			result += delimiter;
		}
	}
	return result;
}

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
// - If `m_cond` is true, this prints `m_msg`, pauses execution, and evaluates
// to true.
// - If `m_cond` is false, this evaluates to false.
// - Use `CHECK` instead if the error is unrecoverable.
#ifdef DEBUG_ENABLED
#define ENSURE(m_cond, m_msg)                                                  \
	(unlikely(!(m_cond))                                                       \
			 ? (::godot::_err_print_error(                                     \
						FUNCTION_STR, __FILE__, __LINE__,                      \
						"ENSURE failed  \"" _STR(m_cond) "\" is false.",       \
						m_msg),                                                \
				::godot::_err_flush_stdout(), DEBUG_BREAK(), false)            \
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
				::godot::_err_flush_stdout(), DEBUG_BREAK(), false)            \
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
#define LOG_PRINT(m_msg)                                                       \
	godot::UtilityFunctions::print_rich(                                       \
			godot::vformat("[color=white]%s[/color]", m_msg))
#else
#define LOG_PRINT(m_msg) (m_cond)
#endif

#ifdef DEBUG_ENABLED
#define LOG_WARNING(m_msg)                                                     \
	godot::UtilityFunctions::print_rich(                                       \
			godot::vformat("[color=yellow]WARNING: %s[/color]", m_msg))
#else
#define LOG_WARNING(m_msg) (m_cond)
#endif

#ifdef DEBUG_ENABLED
#define LOG_ERROR(m_msg)                                                       \
	godot::UtilityFunctions::print_rich(                                       \
			godot::vformat("[color=red]ERROR: %s[/color]", m_msg))
#else
#define LOG_ERROR(m_msg) (m_cond)
#endif

} //namespace godot

#endif
