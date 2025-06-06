#include "snore_core/snore_core_main_settings.h"

#include "snore_core/internal_utils.h"
#include "snore_core/snore_core_main_module.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

// TODO: Update the demo settings to use the default values from the old
// manifest.gd.

void SnoreCoreMainSettings::_bind_methods() {
	ADD_GROUP("Flags", "flag_");

	ClassDB::bind_method(
			D_METHOD("get_dev_mode"), &SnoreCoreMainSettings::get_dev_mode);
	ClassDB::bind_method(
			D_METHOD("set_dev_mode", "p_value"),
			&SnoreCoreMainSettings::set_dev_mode);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO(Variant::BOOL, "flag_dev_mode"),
			"set_dev_mode", "get_dev_mode");

	ADD_SUBGROUP("Logging", "flag_");

	ClassDB::bind_method(
			D_METHOD("get_log_snore_core_events"),
			&SnoreCoreMainSettings::get_log_snore_core_events);
	ClassDB::bind_method(
			D_METHOD("set_log_snore_core_events", "p_value"),
			&SnoreCoreMainSettings::set_log_snore_core_events);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO(Variant::BOOL, "flag_log_snore_core_events"),
			"set_log_snore_core_events", "get_log_snore_core_events");

	ClassDB::bind_method(
			D_METHOD("get_log_snore_core_events_verbose"),
			&SnoreCoreMainSettings::get_log_snore_core_events_verbose);
	ClassDB::bind_method(
			D_METHOD("set_log_snore_core_events_verbose", "p_value"),
			&SnoreCoreMainSettings::set_log_snore_core_events_verbose);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO(
					Variant::BOOL, "flag_log_snore_core_events_verbose"),
			"set_log_snore_core_events_verbose",
			"get_log_snore_core_events_verbose");

	// End subgroup Logging.
	// End group Flags.

	ClassDB::bind_method(
			D_METHOD("get_canvas_layers"),
			&SnoreCoreMainSettings::get_canvas_layers);
	ClassDB::bind_method(
			D_METHOD("set_canvas_layers", "p_layers"),
			&SnoreCoreMainSettings::set_canvas_layers);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO_WITH_HINT(
					Variant::ARRAY, "canvas_layers", PROPERTY_HINT_ARRAY_TYPE,
					"SnoreCoreCanvasLayerConfig"),
			"set_canvas_layers", "get_canvas_layers");

	ClassDB::bind_method(
			D_METHOD("get_debug_time_scale"),
			&SnoreCoreMainSettings::get_debug_time_scale);
	ClassDB::bind_method(
			D_METHOD("set_debug_time_scale", "p_scale"),
			&SnoreCoreMainSettings::set_debug_time_scale);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO_WITH_HINT(
					Variant::FLOAT, "debug_time_scale", PROPERTY_HINT_RANGE,
					"0.5,5.0,0.1"),
			"set_debug_time_scale", "get_debug_time_scale");

	ClassDB::bind_method(
			D_METHOD("get_render_debug_annotations"),
			&SnoreCoreMainSettings::get_render_debug_annotations);
	ClassDB::bind_method(
			D_METHOD("set_render_debug_annotations", "p_value"),
			&SnoreCoreMainSettings::set_render_debug_annotations);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO(Variant::BOOL, "render_debug_annotations"),
			"set_render_debug_annotations", "get_render_debug_annotations");

	ADD_GROUP("Advanced", "advanced_");

	ClassDB::bind_method(
			D_METHOD("get_user_settings_path"),
			&SnoreCoreMainSettings::get_user_settings_path);
	ClassDB::bind_method(
			D_METHOD("set_user_settings_path", "p_value"),
			&SnoreCoreMainSettings::set_user_settings_path);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO(
					Variant::STRING_NAME, "advanced_user_settings_path"),
			"set_user_settings_path", "get_user_settings_path");
}

Ref<SnoreCoreMainSettings> SnoreCoreMainSettings::get() {
	SnoreCore *snore_core_main = SnoreCore::get();
	CHECK(snore_core_main, "SnoreCore is not initialized.");
	return snore_core_main->get_settings();
}

TypedArray<CanvasLayerConfig> SnoreCoreMainSettings::get_canvas_layers() const {
	return canvas_layers;
}

void SnoreCoreMainSettings::set_canvas_layers(
		const TypedArray<CanvasLayerConfig> &p_layers) {
	canvas_layers = p_layers;
}
