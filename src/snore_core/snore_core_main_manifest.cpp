#include "snore_core/snore_core_main_manifest.h"

#include "snore_core/internal_utils.h"
#include "snore_core/snore_core_main_module.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

// TODO: Update the demo manifest to use the default values from the old
// manifest.gd.

Ref<SnoreCoreMainManifest> SnoreCoreMainManifest::get() {
	SnoreCore *snore_core_main = SnoreCore::get();
	CHECK(snore_core_main, "SnoreCore is not initialized.");
	return snore_core_main->get_manifest();
}

void SnoreCoreMainManifest::_bind_methods() {
	ADD_GROUP("Flags", "flag_");

	ClassDB::bind_method(
			D_METHOD("get_dev_mode"), &SnoreCoreMainManifest::get_dev_mode);
	ClassDB::bind_method(
			D_METHOD("set_dev_mode", "p_value"),
			&SnoreCoreMainManifest::set_dev_mode);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO(Variant::BOOL, "flag_dev_mode"),
			"set_dev_mode", "get_dev_mode");

	ADD_SUBGROUP("Logging", "flag_log_");

	ClassDB::bind_method(
			D_METHOD("get_log_snore_core_events"),
			&SnoreCoreMainManifest::get_log_snore_core_events);
	ClassDB::bind_method(
			D_METHOD("set_log_snore_core_events", "p_value"),
			&SnoreCoreMainManifest::set_log_snore_core_events);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO(Variant::BOOL, "flag_log_snore_core_events"),
			"set_log_snore_core_events", "get_log_snore_core_events");

	ClassDB::bind_method(
			D_METHOD("get_log_snore_core_events_verbose"),
			&SnoreCoreMainManifest::get_log_snore_core_events_verbose);
	ClassDB::bind_method(
			D_METHOD("set_log_snore_core_events_verbose", "p_value"),
			&SnoreCoreMainManifest::set_log_snore_core_events_verbose);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO(
					Variant::BOOL, "flag_log_snore_core_events_verbose"),
			"set_log_snore_core_events_verbose",
			"get_log_snore_core_events_verbose");

	// End subgroup Logging.
	// End group Flags.

	ClassDB::bind_method(
			D_METHOD("get_canvas_layers"),
			&SnoreCoreMainManifest::get_canvas_layers);
	ClassDB::bind_method(
			D_METHOD("set_canvas_layers", "p_layers"),
			&SnoreCoreMainManifest::set_canvas_layers);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO_WITH_HINT(
					Variant::ARRAY, "canvas_layers", PROPERTY_HINT_ARRAY_TYPE,
					"SnoreCoreCanvasLayerConfig"),
			"set_canvas_layers", "get_canvas_layers");

	ClassDB::bind_method(
			D_METHOD("get_debug_time_scale"),
			&SnoreCoreMainManifest::get_debug_time_scale);
	ClassDB::bind_method(
			D_METHOD("set_debug_time_scale", "p_scale"),
			&SnoreCoreMainManifest::set_debug_time_scale);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO_WITH_HINT(
					Variant::FLOAT, "debug_time_scale", PROPERTY_HINT_RANGE,
					"0.5,5.0,0.1"),
			"set_debug_time_scale", "get_debug_time_scale");

	ClassDB::bind_method(
			D_METHOD("get_render_debug_annotations"),
			&SnoreCoreMainManifest::get_render_debug_annotations);
	ClassDB::bind_method(
			D_METHOD("set_render_debug_annotations", "p_value"),
			&SnoreCoreMainManifest::set_render_debug_annotations);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO(Variant::BOOL, "render_debug_annotations"),
			"set_render_debug_annotations", "get_render_debug_annotations");
}
