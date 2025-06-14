#include "snore_core/internal_utils.h"

#include "snore_core/snore_core_main_module.h"

using namespace godot;

#if !IS_SNORE_CORE_RELEASE

// NOTE: This fails because C++23 isn't available.
//
// #include <stacktrace>
// String godot::get_stack_trace() {
// 	std::stacktrace trace = std::stacktrace::current();
// 	String result;
// 	for (const auto &frame : trace) {
// 		result += vformat("    [%d] %s\n", frame.index(), frame.name());
// 	}
// 	return result;
// }

#ifdef _MSC_VER

#include <windows.h>

#include <dbghelp.h>

String godot::get_stack_trace() {
	const int max_trace_size = 30;
	void *trace[max_trace_size] = { 0 };
	TypedArray<String> strings;
	strings.resize(max_trace_size);

	const int trace_size =
			CaptureStackBackTrace(0, max_trace_size, trace, nullptr);

	// Convert addresses to strings manually since we can't easily get symbols.
	for (int i = 0; i < trace_size; ++i) {
		strings[i] = vformat(
				"    [%d] 0x%016llx", i, reinterpret_cast<uintptr_t>(trace[i]));
	}

	return join_strings(strings, "\n    ");
}
#else
#include <execinfo.h>
String godot::get_stack_trace() {
	const int max_trace_size = 30;
	void *trace[max_trace_size] = { 0 };

	const int trace_size = backtrace(trace, max_trace_size);
	char **strings = backtrace_symbols(trace, trace_size);

	if (!strings) {
		return String("Stack trace unavailable");
	}

	String result = join_strings(strings, trace_size, "\n    ");

	free(strings);

	return result;
}
#endif
#else
String godot::get_stack_trace() { return String(); }
#endif

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
		result += p_strings[i];
		if (i < p_strings.size() - 1) {
			result += p_delimiter;
		}
	}
	return result;
}
