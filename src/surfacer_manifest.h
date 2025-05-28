#ifndef SURFACER_MANIFEST_H
#define SURFACER_MANIFEST_H

#include "scaffolder/geometry.h"
#include "scaffolder/scaffolder_manifest.h"

#include <godot_cpp/classes/shape2d.hpp>
#include <godot_cpp/core/binder_common.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

class SurfacerManifest : public ScaffolderManifest {
	GDCLASS(SurfacerManifest, ScaffolderManifest)

public:
	SurfacerManifest() = default;
	~SurfacerManifest() = default;

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

protected:
	static void _bind_methods();

private:
	bool log_surfacer_events = false;
	bool log_surfacer_events_verbose = false;
};

} // namespace godot

#endif
