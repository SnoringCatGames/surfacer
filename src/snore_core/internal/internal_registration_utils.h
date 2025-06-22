#ifndef INTERNAL_REGISTRATION_UTILS_H
#define INTERNAL_REGISTRATION_UTILS_H

#include "snore_core/test_runner/test_runner.h"

#include <godot_cpp/classes/object.hpp>

namespace godot {

constexpr const char PROCESS_MODE_HINT_STRING[] =
		"INHERIT,PAUSABLE,WHEN_PAUSED,ALWAYS,DISABLED";

constexpr uint64_t PROPERTY_USAGE_EXPORTED_ITEM = PROPERTY_USAGE_STORAGE |
		PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_SCRIPT_VARIABLE;

#define EXPORTED_PROPERTY_INFO(type, name)                                     \
	PropertyInfo(                                                              \
			type, name, PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EXPORTED_ITEM)
#define EXPORTED_PROPERTY_INFO_WITH_HINT(type, name, hint_type, hint_string)   \
	PropertyInfo(                                                              \
			type, name, hint_type, hint_string, PROPERTY_USAGE_EXPORTED_ITEM)

#ifdef DEBUG_ENABLED

#define REGISTER_SNORE_CORE_TEST_SUITE(m_test)                                 \
	TestRunnerInternal::runner.test_modules.push_back(m_test)

#define REGISTER_SNORE_CORE_CLASS(m_class)                                     \
	do {                                                                       \
		GDREGISTER_CLASS(m_class);                                             \
		REGISTER_SNORE_CORE_TEST_SUITE(TEST_MODULE_NAME(m_class));             \
	} while (0)

#define REGISTER_SNORE_CORE_ABSTRACT_CLASS(m_class)                            \
	do {                                                                       \
		GDREGISTER_ABSTRACT_CLASS(m_class);                                    \
		REGISTER_SNORE_CORE_TEST_SUITE(TEST_MODULE_NAME(m_class));             \
	} while (0)

#define REGISTER_SNORE_CORE_VIRTUAL_CLASS(m_class)                             \
	do {                                                                       \
		GDREGISTER_VIRTUAL_CLASS(m_class);                                     \
		REGISTER_SNORE_CORE_TEST_SUITE(TEST_MODULE_NAME(m_class));             \
	} while (0)

#else // DEBUG_ENABLED

#define REGISTER_SNORE_CORE_CLASS(m_class) GDREGISTER_CLASS(m_class)
#define REGISTER_SNORE_CORE_ABSTRACT_CLASS(m_class)                            \
	GDREGISTER_ABSTRACT_CLASS(m_class)
#define REGISTER_SNORE_CORE_VIRTUAL_CLASS(m_class)                             \
	GDREGISTER_VIRTUAL_CLASS(m_class)

#endif // DEBUG_ENABLED

} //namespace godot

#endif // INTERNAL_REGISTRATION_UTILS_H
