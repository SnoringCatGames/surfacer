#ifndef SNORE_CORE_MAIN_SETTINGS_H
#define SNORE_CORE_MAIN_SETTINGS_H

#include "snore_core/canvas_layer_config.h"
#include "snore_core/snore_core_settings.h"

#include <godot_cpp/core/binder_common.hpp>

namespace godot {

class SnoreCoreMainSettings : public SnoreCoreSettings {
	GDCLASS(SnoreCoreMainSettings, SnoreCoreSettings)

public:
	static Ref<SnoreCoreMainSettings> get();

	SnoreCoreMainSettings() = default;
	~SnoreCoreMainSettings() = default;

	bool get_dev_mode() const { return dev_mode; }
	void set_dev_mode(bool p_value) { dev_mode = p_value; }

	bool get_log_snore_core_events() const { return log_snore_core_events; }
	void set_log_snore_core_events(bool p_value) {
		log_snore_core_events = p_value;
	}

	bool get_log_snore_core_events_verbose() const {
		return log_snore_core_events_verbose;
	}
	void set_log_snore_core_events_verbose(bool p_value) {
		log_snore_core_events_verbose = p_value;
	}

	TypedArray<CanvasLayerConfig> get_canvas_layers() const;
	void set_canvas_layers(const TypedArray<CanvasLayerConfig> &p_layers);

	double get_debug_time_scale() const { return debug_time_scale; }
	void set_debug_time_scale(double p_scale) { debug_time_scale = p_scale; }

	bool get_render_debug_annotations() const {
		return render_debug_annotations;
	}
	void set_render_debug_annotations(bool p_value) {
		render_debug_annotations = p_value;
	}

	String get_user_settings_path() const { return user_settings_path; }
	void set_user_settings_path(String p_value) {
		user_settings_path = p_value;
	}

protected:
	static void _bind_methods();

private:
	bool dev_mode = true;

	bool log_snore_core_events = false;
	bool log_snore_core_events_verbose = false;

	TypedArray<CanvasLayerConfig> canvas_layers;

	double debug_time_scale = 1.0;
	bool render_debug_annotations = false;

	String user_settings_path = "user://user_settings.tres";
};

} // namespace godot

#endif // SNORE_CORE_MAIN_SETTINGS_H