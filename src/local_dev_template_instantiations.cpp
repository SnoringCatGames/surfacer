#include "snore_core/snore_core_settings.h"

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/String.hpp>
#include <godot_cpp/variant/typed_array.hpp>

#ifdef DEBUG_ENABLED

using namespace godot;

// Explicit template instantiation to prevent compiler optimization
template class TypedArray<SnoreCoreSettings>;

// Force instantiation of specific methods

// NOTE: COMMENT THESE OUT BEFORE SUBMITTING!

// template std::vector<SnoreCoreSettings *>
// TypedArray<SnoreCoreSettings>::debug() 		const;

#endif // DEBUG_ENABLED
