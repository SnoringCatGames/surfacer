#include "surfacer/surfacer_manifest.h"

#include "snore_core/internal_utils.h"
#include "surfacer/surfacer_module.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

Ref<SurfacerManifest> SurfacerManifest::get() {
	Surfacer *surfacer = Surfacer::get();
	CHECK(surfacer, "Surfacer is not initialized.");
	return surfacer->get_manifest();
}

void SurfacerManifest::_bind_methods() {
	ClassDB::bind_method(
			D_METHOD("get_movement_manifest"),
			&SurfacerManifest::get_movement_manifest);
	ClassDB::bind_method(
			D_METHOD("set_movement_manifest", "p_value"),
			&SurfacerManifest::set_movement_manifest);
	ADD_PROPERTY(
			PropertyInfo(Variant::OBJECT, "movement_manifest"),
			"set_movement_manifest", "get_movement_manifest");

	ClassDB::bind_method(
			D_METHOD("get_log_surfacer_events"),
			&SurfacerManifest::get_log_surfacer_events);
	ClassDB::bind_method(
			D_METHOD("set_log_surfacer_events", "p_value"),
			&SurfacerManifest::set_log_surfacer_events);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "flag_log_surfacer_events"),
			"set_log_surfacer_events", "get_log_surfacer_events");

	ClassDB::bind_method(
			D_METHOD("get_log_surfacer_events_verbose"),
			&SurfacerManifest::get_log_surfacer_events_verbose);
	ClassDB::bind_method(
			D_METHOD("set_log_surfacer_events_verbose", "p_value"),
			&SurfacerManifest::set_log_surfacer_events_verbose);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "flag_log_surfacer_events_verbose"),
			"set_log_surfacer_events_verbose",
			"get_log_surfacer_events_verbose");

	ClassDB::bind_method(
			D_METHOD("get_are_oddly_shaped_surfaces_used"),
			&SurfacerManifest::get_are_oddly_shaped_surfaces_used);
	ClassDB::bind_method(
			D_METHOD("set_are_oddly_shaped_surfaces_used", "p_value"),
			&SurfacerManifest::set_are_oddly_shaped_surfaces_used);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "flag_are_oddly_shaped_surfaces_used"),
			"set_are_oddly_shaped_surfaces_used",
			"get_are_oddly_shaped_surfaces_used");

	ClassDB::bind_method(
			D_METHOD("get_floor_max_angle"),
			&SurfacerManifest::get_floor_max_angle);
	ClassDB::bind_method(
			D_METHOD("set_floor_max_angle", "p_value"),
			&SurfacerManifest::set_floor_max_angle);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "flag_floor_max_angle"),
			"set_floor_max_angle", "get_floor_max_angle");
}
