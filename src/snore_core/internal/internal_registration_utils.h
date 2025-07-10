#ifndef INTERNAL_REGISTRATION_UTILS_H
#define INTERNAL_REGISTRATION_UTILS_H

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

} //namespace godot

#endif // INTERNAL_REGISTRATION_UTILS_H
