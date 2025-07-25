#ifndef NAVIGATION_INTERRUPTION_RESOLUTION_H
#define NAVIGATION_INTERRUPTION_RESOLUTION_H

#include "snore_core/internal/string_utils.h"

#include <godot_cpp/core/binder_common.hpp>

namespace godot {

enum NavigationInterruptionResolution {
	UNKNOWN_RESOLUTION,
	CANCEL_NAV,
	RETRY_NAV,
	SKIP_NAV,
	FORCE_EXPECTED_STATE,
	_NavigationInterruptionResolution_COUNT,
};

static constexpr const char
		*resolution_strings[NavigationInterruptionResolution::
									_NavigationInterruptionResolution_COUNT] = {
			"UNKNOWN", "FLOOR", "CEILING", "LEFT_WALL", "RIGHT_WALL",
		};

static String navigation_interruption_resolution_to_string(
		NavigationInterruptionResolution p_resolution) {
	return resolution_strings[p_resolution];
}

static String get_navigation_interruption_resolution_hint_string() {
	return join_strings(
			resolution_strings,
			NavigationInterruptionResolution::
					_NavigationInterruptionResolution_COUNT,
			",");
}

} //namespace godot

VARIANT_ENUM_CAST(NavigationInterruptionResolution);

#endif
