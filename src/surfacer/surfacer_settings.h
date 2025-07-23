#ifndef SURFACER_SETTINGS_H
#define SURFACER_SETTINGS_H

#include "snore_core/snore_core_settings.h"
#include "surfacer/movement_settings.h"
#include "surfacer/surface_parser_settings.h"

#include <godot_cpp/core/binder_common.hpp>

namespace godot {

class GDE_EXPORT SurfacerSettings : public SnoreCoreSettings {
	GDCLASS(SurfacerSettings, SnoreCoreSettings)

public:
	static Ref<SurfacerSettings> get();

	SurfacerSettings();
	~SurfacerSettings();

	Ref<MovementSettings> get_movement_settings() const;
	void set_movement_settings(Ref<MovementSettings> p_value);

	Ref<SurfaceParserSettings> get_surface_parser_settings() const;
	void set_surface_parser_settings(Ref<SurfaceParserSettings> p_value);

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
	Ref<MovementSettings> movement_settings;
	Ref<SurfaceParserSettings> surface_parser_settings;

	bool log_surfacer_events = false;
	bool log_surfacer_events_verbose = false;

	bool are_oddly_shaped_surfaces_used = true;
	double floor_max_angle = Math_PI / 4.0;
};

} // namespace godot

#endif // SURFACER_SETTINGS_H