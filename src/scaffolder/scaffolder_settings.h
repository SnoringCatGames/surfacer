#ifndef SCAFFOLDER_SETTINGS_H
#define SCAFFOLDER_SETTINGS_H

#include "snore_core/snore_core_settings.h"

#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/classes/theme.hpp>
#include <godot_cpp/core/binder_common.hpp>

namespace godot {

class ScaffolderSettings : public SnoreCoreSettings {
	GDCLASS(ScaffolderSettings, SnoreCoreSettings)

public:
	static Ref<ScaffolderSettings> get();

	ScaffolderSettings() = default;
	~ScaffolderSettings() = default;

	bool get_god_mode() const { return god_mode; }
	void set_god_mode(bool p_value) { god_mode = p_value; }

	bool get_skip_main_menu_in_dev_mode() const {
		return skip_main_menu_in_dev_mode;
	}
	void set_skip_main_menu_in_dev_mode(bool p_value) {
		skip_main_menu_in_dev_mode = p_value;
	}

	bool get_full_screen() const { return full_screen; }
	void set_full_screen(bool p_value) { full_screen = p_value; }

	bool get_mute_music() const { return mute_music; }
	void set_mute_music(bool p_value) { mute_music = p_value; }

	bool get_pauses_on_focus_out() const { return pauses_on_focus_out; }
	void set_pauses_on_focus_out(bool p_value) {
		pauses_on_focus_out = p_value;
	}

	bool get_is_screenshot_hotkey_enabled() const {
		return is_screenshot_hotkey_enabled;
	}
	void set_is_screenshot_hotkey_enabled(bool p_value) {
		is_screenshot_hotkey_enabled = p_value;
	}

	bool get_show_hud() const { return show_hud; }
	void set_show_hud(bool p_value) { show_hud = p_value; }

	Ref<Theme> get_main_theme() const { return main_theme; }
	void set_main_theme(const Ref<Theme> &p_theme) { main_theme = p_theme; }

	Ref<PackedScene> get_dev_mode_level() const { return dev_mode_level; }
	void set_dev_mode_level(const Ref<PackedScene> &p_scene) {
		dev_mode_level = p_scene;
	}

	Ref<PackedScene> get_main_level() const { return main_level; }
	void set_main_level(const Ref<PackedScene> &p_scene) {
		main_level = p_scene;
	}

	Ref<PackedScene> get_hud_scene() const { return hud_scene; }
	void set_hud_scene(const Ref<PackedScene> &p_scene) { hud_scene = p_scene; }

	Dictionary get_screens() const { return screens; }
	void set_screens(const Dictionary &p_screens) { screens = p_screens; }

	Dictionary get_sfxs() const { return sfxs; }
	void set_sfxs(const Dictionary &p_sfxs) { sfxs = p_sfxs; }

	double get_debug_time_scale() const { return debug_time_scale; }
	void set_debug_time_scale(double p_scale) { debug_time_scale = p_scale; }

	bool get_render_debug_annotations() const {
		return render_debug_annotations;
	}
	void set_render_debug_annotations(bool p_value) {
		render_debug_annotations = p_value;
	}

	Ref<PackedScene> get_super_hud_scene() const { return super_hud_scene; }
	void set_super_hud_scene(const Ref<PackedScene> &p_scene) {
		super_hud_scene = p_scene;
	}

	Ref<PackedScene> get_shell_scene() const { return shell_scene; }
	void set_shell_scene(const Ref<PackedScene> &p_scene) {
		shell_scene = p_scene;
	}

	String get_initial_screen() const;
	Ref<PackedScene> get_screen_scene(const String &p_name) const;
	bool has_screen_scene(const String &p_name) const;

protected:
	static void _bind_methods();

private:
	bool god_mode = false;
	bool skip_main_menu_in_dev_mode = false;
	bool full_screen = false;
	bool mute_music = false;
	bool pauses_on_focus_out = true;
	bool is_screenshot_hotkey_enabled = true;
	bool show_hud = true;

	Ref<Theme> main_theme;
	Ref<PackedScene> dev_mode_level;
	Ref<PackedScene> main_level;
	Ref<PackedScene> hud_scene;

	Dictionary screens;
	Dictionary sfxs;

	double debug_time_scale = 1.0;
	bool render_debug_annotations = false;

	Ref<PackedScene> super_hud_scene;
	Ref<PackedScene> shell_scene;
};

} // namespace godot

#endif // SCAFFOLDER_SETTINGS_H
