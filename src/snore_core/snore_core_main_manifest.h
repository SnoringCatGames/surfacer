#ifndef SNORE_CORE_MAIN_MANIFEST_H
#define SNORE_CORE_MAIN_MANIFEST_H

#include "scaffolder/canvas_layer_config.h"
#include "snore_core/snore_core_manifest.h"

#include <godot_cpp/core/binder_common.hpp>

namespace godot {

class SnoreCoreMainManifest : public SnoreCoreManifest {
	GDCLASS(SnoreCoreMainManifest, SnoreCoreManifest)

public:
	static Ref<SnoreCoreMainManifest> get();

	SnoreCoreMainManifest() = default;
	~SnoreCoreMainManifest() = default;

	bool get_dev_mode() const { return dev_mode; }
	void set_dev_mode(bool p_value) { dev_mode = p_value; }

	bool get_log_scaffolder_events() const { return log_scaffolder_events; }
	void set_log_scaffolder_events(bool p_value) {
		log_scaffolder_events = p_value;
	}

	bool get_log_scaffolder_events_verbose() const {
		return log_scaffolder_events_verbose;
	}
	void set_log_scaffolder_events_verbose(bool p_value) {
		log_scaffolder_events_verbose = p_value;
	}

	TypedArray<CanvasLayerConfig> get_canvas_layers() const {
		return canvas_layers;
	}
	void set_canvas_layers(const TypedArray<CanvasLayerConfig> &p_layers) {
		canvas_layers = p_layers;
	}

	double get_debug_time_scale() const { return debug_time_scale; }
	void set_debug_time_scale(double p_scale) { debug_time_scale = p_scale; }

	bool get_render_debug_annotations() const {
		return render_debug_annotations;
	}
	void set_render_debug_annotations(bool p_value) {
		render_debug_annotations = p_value;
	}

protected:
	static void _bind_methods();

private:
	bool dev_mode = true;

	bool log_scaffolder_events = false;
	bool log_scaffolder_events_verbose = false;

	TypedArray<CanvasLayerConfig> canvas_layers;

	double debug_time_scale = 1.0;
	bool render_debug_annotations = false;
};

} // namespace godot

#endif // SNORE_CORE_MAIN_MANIFEST_H
