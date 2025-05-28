#include "surfacer_manifest.h"

#include "scaffolder/internal_utils.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void SurfacerManifest::_bind_methods() {
	ClassDB::bind_method(
			D_METHOD("get_log_surfacer_events"),
			&ScaffolderManifest::get_log_surfacer_events);
	ClassDB::bind_method(
			D_METHOD("set_log_surfacer_events", "p_value"),
			&ScaffolderManifest::set_log_surfacer_events);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "flag_log_surfacer_events"),
			"set_log_surfacer_events", "get_log_surfacer_events");

	ClassDB::bind_method(
			D_METHOD("get_log_surfacer_events_verbose"),
			&ScaffolderManifest::get_log_surfacer_events_verbose);
	ClassDB::bind_method(
			D_METHOD("set_log_surfacer_events_verbose", "p_value"),
			&ScaffolderManifest::set_log_surfacer_events_verbose);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "flag_log_surfacer_events_verbose"),
			"set_log_surfacer_events_verbose",
			"get_log_surfacer_events_verbose");
}
