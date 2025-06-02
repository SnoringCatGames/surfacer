#ifndef SURFACER_MANIFEST_H
#define SURFACER_MANIFEST_H

#include "snore_core/geometry.h"
#include "snore_core/snore_core_manifest.h"
#include "surfacer/movement_manifest.h"
#include "surfacer/surface_parser_manifest.h"

#include <godot_cpp/core/binder_common.hpp>

namespace godot {

class SurfacerManifest : public SnoreCoreManifest {
	GDCLASS(SurfacerManifest, SnoreCoreManifest)

public:
	static Ref<SurfacerManifest> get();

	SurfacerManifest() = default;
	~SurfacerManifest() = default;

	Ref<MovementManifest> get_movement_manifest() const {
		return movement_manifest;
	}
	void set_movement_manifest(Ref<MovementManifest> p_value) {
		movement_manifest = p_value;
	}

	Ref<SurfaceParserManifest> get_surface_parser_manifest() const {
		return surface_parser_manifest;
	}
	void set_surface_parser_manifest(Ref<SurfaceParserManifest> p_value) {
		surface_parser_manifest = p_value;
	}

	bool get_log_surfacer_events() const { return log_surfacer_events; }
	void set_log_surfacer_events(bool p_value) {
		log_surfacer_events = p_value;
	}

	bool get_log_surfacer_events_verbose() const {
		return log_surfacer_events_verbose;
	}
	void set_log_surfacer_events_verbose(bool p_value) {
		log_surfacer_events_verbose = p_value;
	}

	bool get_are_oddly_shaped_surfaces_used() const {
		return are_oddly_shaped_surfaces_used;
	}
	void set_are_oddly_shaped_surfaces_used(bool p_value) {
		are_oddly_shaped_surfaces_used = p_value;
	}

	double get_floor_max_angle() const { return floor_max_angle; }
	void set_floor_max_angle(double p_value) { floor_max_angle = p_value; }

protected:
	static void _bind_methods();

private:
	Ref<MovementManifest> movement_manifest;
	Ref<SurfaceParserManifest> surface_parser_manifest;

	bool log_surfacer_events = false;
	bool log_surfacer_events_verbose = false;

	bool are_oddly_shaped_surfaces_used = true;
	double floor_max_angle = Math_PI / 4.0;
};

} // namespace godot

#endif // SURFACER_MANIFEST_H
