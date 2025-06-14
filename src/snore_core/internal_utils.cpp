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
// clang-format off
#include <windows.h>
#include <dbghelp.h>
// clang-format on
#pragma comment(lib, "dbghelp.lib")
String godot::get_stack_trace() {
	void *stack[80];
	USHORT frames = CaptureStackBackTrace(0, 80, stack, NULL);

	SymInitialize(GetCurrentProcess(), NULL, TRUE);

	String result;

	// Skip i=0, since that's this function.
	for (USHORT i = 1; i < frames; ++i) {
		DWORD64 address = (DWORD64)stack[i];

		DWORD64 displacement = 0;
		char buffer[sizeof(SYMBOL_INFO) + MAX_SYM_NAME * sizeof(TCHAR)];
		PSYMBOL_INFO symbol = (PSYMBOL_INFO)buffer;
		symbol->SizeOfStruct = sizeof(SYMBOL_INFO);
		symbol->MaxNameLen = MAX_SYM_NAME;

		result += vformat("    [%d] ", i);

		if (SymFromAddr(GetCurrentProcess(), address, &displacement, symbol)) {
			result += symbol->Name;
			// if (displacement > 0) {
			// 	result += vformat(" + 0x%x", (uint32_t)displacement);
			// }

			// Get line information
			IMAGEHLP_LINE64 lineInfo;
			lineInfo.SizeOfStruct = sizeof(IMAGEHLP_LINE64);
			DWORD displacementLine = 0;
			if (SymGetLineFromAddr64(
						GetCurrentProcess(), address, &displacementLine,
						&lineInfo)) {
				result +=
						vformat(" (%s:%d)", lineInfo.FileName,
								(int)lineInfo.LineNumber);
			}
		} else {
			result += vformat("0x%x", (uintptr_t)stack[i]);
		}
		result += "\n";
	}
	SymCleanup(GetCurrentProcess());

	return result;
}
#else
#include <execinfo.h>
String godot::get_stack_trace() {
	const int max_trace_size = 80;
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
