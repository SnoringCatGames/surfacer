#include "snore_core/internal/string_utils.h"

using namespace godot;

String godot::join_strings(
		const char **p_strings,
		int p_size,
		const char *p_delimiter) {
	String result;
	for (int i = 0; i < p_size; ++i) {
		result += p_strings[i];
		if (i < p_size - 1) {
			result += p_delimiter;
		}
	}
	return result;
}

String godot::join_strings(
		const char *const p_strings[],
		int p_size,
		const char *p_delimiter) {
	String result;
	for (int i = 0; i < p_size; ++i) {
		result += p_strings[i];
		if (i < p_size - 1) {
			result += p_delimiter;
		}
	}
	return result;
}

String godot::join_strings(
		const std::vector<std::string> &p_strings,
		const char *p_delimiter) {
	String result;
	for (size_t i = 0; i < p_strings.size(); ++i) {
		result += p_strings[i].c_str();
		if (i < p_strings.size() - 1) {
			result += p_delimiter;
		}
	}
	return result;
}

String godot::join_strings(
		const TypedArray<String> &p_strings,
		const char *p_delimiter) {
	String result;
	for (int i = 0; i < p_strings.size(); ++i) {
		result += String(p_strings[i]);
		if (i < p_strings.size() - 1) {
			result += p_delimiter;
		}
	}
	return result;
}
