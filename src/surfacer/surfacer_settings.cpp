#include "surfacer/surfacer_settings.h"

#include "snore_core/internal/registration_utils.h"
#include "surfacer/movement_settings.h"
#include "surfacer/surface_parser_settings.h"
#include "surfacer/surfacer_module.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

SC_SETTINGS_CLASS_DEFINITION(SurfacerSettings, Surfacer)

SurfacerSettings::SurfacerSettings() {
	movement_settings = instantiate_ref<MovementSettings>();
	surface_parser_settings = instantiate_ref<SurfaceParserSettings>();
}

SurfacerSettings::~SurfacerSettings() {
	movement_settings.unref();
	surface_parser_settings.unref();
}

Ref<MovementSettings> SurfacerSettings::get_movement_settings() const {
	return movement_settings;
}
void SurfacerSettings::set_movement_settings(Ref<MovementSettings> p_value) {
	movement_settings = p_value;
}

Ref<SurfaceParserSettings> SurfacerSettings::get_surface_parser_settings()
		const {
	return surface_parser_settings;
}
void SurfacerSettings::set_surface_parser_settings(
		Ref<SurfaceParserSettings> p_value) {
	surface_parser_settings = p_value;
}

void SurfacerSettings::_bind_methods() {
	ClassDB::bind_method(
			D_METHOD("get_movement_settings"),
			&SurfacerSettings::get_movement_settings);
	ClassDB::bind_method(
			D_METHOD("set_movement_settings", "p_value"),
			&SurfacerSettings::set_movement_settings);
	ADD_PROPERTY(
			PropertyInfo(Variant::OBJECT, "movement_settings"),
			"set_movement_settings", "get_movement_settings");

	ClassDB::bind_method(
			D_METHOD("get_surface_parser_settings"),
			&SurfacerSettings::get_surface_parser_settings);
	ClassDB::bind_method(
			D_METHOD("set_surface_parser_settings", "p_value"),
			&SurfacerSettings::set_surface_parser_settings);
	ADD_PROPERTY(
			PropertyInfo(Variant::OBJECT, "surface_parser_settings"),
			"set_surface_parser_settings", "get_surface_parser_settings");

	ClassDB::bind_method(
			D_METHOD("get_are_oddly_shaped_surfaces_used"),
			&SurfacerSettings::get_are_oddly_shaped_surfaces_used);
	ClassDB::bind_method(
			D_METHOD("set_are_oddly_shaped_surfaces_used", "p_value"),
			&SurfacerSettings::set_are_oddly_shaped_surfaces_used);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "flag_are_oddly_shaped_surfaces_used"),
			"set_are_oddly_shaped_surfaces_used",
			"get_are_oddly_shaped_surfaces_used");

	ClassDB::bind_method(
			D_METHOD("get_floor_max_angle"),
			&SurfacerSettings::get_floor_max_angle);
	ClassDB::bind_method(
			D_METHOD("set_floor_max_angle", "p_value"),
			&SurfacerSettings::set_floor_max_angle);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "flag_floor_max_angle"),
			"set_floor_max_angle", "get_floor_max_angle");

	ADD_GROUP("Flags", "");
	ADD_SUBGROUP("Logging", "log");
	BIND_LOGGING_FLAG(SurfacerSettings, surfacer_events);
	BIND_LOGGING_FLAG(SurfacerSettings, surfacer_events_verbose);
	// END GROUP "Logging"
	// END GROUP "Flags"
}
