#ifndef INTERNAL_STRING_UTILS_H
#define INTERNAL_STRING_UTILS_H

#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/typed_array.hpp>

#include <string>
#include <vector>

namespace godot {

extern String join_strings(
		const char **p_strings,
		int p_size,
		const char *p_delimiter);
extern String join_strings(
		const char *const p_strings[],
		int p_size,
		const char *p_delimiter);
extern String join_strings(
		const std::vector<std::string> &p_strings,
		const char *p_delimiter);
extern String join_strings(
		const TypedArray<String> &p_strings,
		const char *p_delimiter);

} //namespace godot

#endif // INTERNAL_STRING_UTILS_H
