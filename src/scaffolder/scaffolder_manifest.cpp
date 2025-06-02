#include "scaffolder/scaffolder_manifest.h"

#include "scaffolder/scaffolder_module.h"
#include "snore_core/internal_utils.h"
#include "snore_core/snore_core_main_manifest.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

// TODO: Update the demo manifest to use the default values from the old
// manifest.gd.

void ScaffolderManifest::_bind_methods() {
	ADD_GROUP("Flags", "flag_");

	ClassDB::bind_method(
			D_METHOD("get_god_mode"), &ScaffolderManifest::get_god_mode);
	ClassDB::bind_method(
			D_METHOD("set_god_mode", "p_value"),
			&ScaffolderManifest::set_god_mode);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO(Variant::BOOL, "flag_god_mode"),
			"set_god_mode", "get_god_mode");

	ClassDB::bind_method(
			D_METHOD("get_skip_main_menu_in_dev_mode"),
			&ScaffolderManifest::get_skip_main_menu_in_dev_mode);
	ClassDB::bind_method(
			D_METHOD("set_skip_main_menu_in_dev_mode", "p_value"),
			&ScaffolderManifest::set_skip_main_menu_in_dev_mode);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO(
					Variant::BOOL, "flag_skip_main_menu_in_dev_mode"),
			"set_skip_main_menu_in_dev_mode", "get_skip_main_menu_in_dev_mode");

	ClassDB::bind_method(
			D_METHOD("get_full_screen"), &ScaffolderManifest::get_full_screen);
	ClassDB::bind_method(
			D_METHOD("set_full_screen", "p_value"),
			&ScaffolderManifest::set_full_screen);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO(Variant::BOOL, "flag_full_screen"),
			"set_full_screen", "get_full_screen");

	ClassDB::bind_method(
			D_METHOD("get_mute_music"), &ScaffolderManifest::get_mute_music);
	ClassDB::bind_method(
			D_METHOD("set_mute_music", "p_value"),
			&ScaffolderManifest::set_mute_music);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO(Variant::BOOL, "flag_mute_music"),
			"set_mute_music", "get_mute_music");

	ClassDB::bind_method(
			D_METHOD("get_pauses_on_focus_out"),
			&ScaffolderManifest::get_pauses_on_focus_out);
	ClassDB::bind_method(
			D_METHOD("set_pauses_on_focus_out", "p_value"),
			&ScaffolderManifest::set_pauses_on_focus_out);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO(Variant::BOOL, "flag_pauses_on_focus_out"),
			"set_pauses_on_focus_out", "get_pauses_on_focus_out");

	ClassDB::bind_method(
			D_METHOD("get_is_screenshot_hotkey_enabled"),
			&ScaffolderManifest::get_is_screenshot_hotkey_enabled);
	ClassDB::bind_method(
			D_METHOD("set_is_screenshot_hotkey_enabled", "p_value"),
			&ScaffolderManifest::set_is_screenshot_hotkey_enabled);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO(
					Variant::BOOL, "flag_is_screenshot_hotkey_enabled"),
			"set_is_screenshot_hotkey_enabled",
			"get_is_screenshot_hotkey_enabled");

	ClassDB::bind_method(
			D_METHOD("get_show_hud"), &ScaffolderManifest::get_show_hud);
	ClassDB::bind_method(
			D_METHOD("set_show_hud", "p_value"),
			&ScaffolderManifest::set_show_hud);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO(Variant::BOOL, "flag_show_hud"),
			"set_show_hud", "get_show_hud");

	// End subgroup Logging.
	// End group Flags.

	ClassDB::bind_method(
			D_METHOD("get_main_theme"), &ScaffolderManifest::get_main_theme);
	ClassDB::bind_method(
			D_METHOD("set_main_theme", "p_theme"),
			&ScaffolderManifest::set_main_theme);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO_WITH_HINT(
					Variant::OBJECT, "main_theme", PROPERTY_HINT_RESOURCE_TYPE,
					"Theme"),
			"set_main_theme", "get_main_theme");

	ClassDB::bind_method(
			D_METHOD("get_dev_mode_level"),
			&ScaffolderManifest::get_dev_mode_level);
	ClassDB::bind_method(
			D_METHOD("set_dev_mode_level", "p_scene"),
			&ScaffolderManifest::set_dev_mode_level);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO_WITH_HINT(
					Variant::OBJECT, "dev_mode_level",
					PROPERTY_HINT_RESOURCE_TYPE, "PackedScene"),
			"set_dev_mode_level", "get_dev_mode_level");

	ClassDB::bind_method(
			D_METHOD("get_main_level"), &ScaffolderManifest::get_main_level);
	ClassDB::bind_method(
			D_METHOD("set_main_level", "p_scene"),
			&ScaffolderManifest::set_main_level);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO_WITH_HINT(
					Variant::OBJECT, "main_level", PROPERTY_HINT_RESOURCE_TYPE,
					"PackedScene"),
			"set_main_level", "get_main_level");

	ClassDB::bind_method(
			D_METHOD("get_hud_scene"), &ScaffolderManifest::get_hud_scene);
	ClassDB::bind_method(
			D_METHOD("set_hud_scene", "p_scene"),
			&ScaffolderManifest::set_hud_scene);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO_WITH_HINT(
					Variant::OBJECT, "hud_scene", PROPERTY_HINT_RESOURCE_TYPE,
					"PackedScene"),
			"set_hud_scene", "get_hud_scene");

	ClassDB::bind_method(
			D_METHOD("get_screens"), &ScaffolderManifest::get_screens);
	ClassDB::bind_method(
			D_METHOD("set_screens", "p_screens"),
			&ScaffolderManifest::set_screens);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO(Variant::DICTIONARY, "screens"),
			"set_screens", "get_screens");

	ClassDB::bind_method(D_METHOD("get_sfxs"), &ScaffolderManifest::get_sfxs);
	ClassDB::bind_method(
			D_METHOD("set_sfxs", "p_sfxs"), &ScaffolderManifest::set_sfxs);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO(Variant::DICTIONARY, "sfxs"), "set_sfxs",
			"get_sfxs");

	ClassDB::bind_method(
			D_METHOD("get_debug_time_scale"),
			&ScaffolderManifest::get_debug_time_scale);
	ClassDB::bind_method(
			D_METHOD("set_debug_time_scale", "p_scale"),
			&ScaffolderManifest::set_debug_time_scale);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO_WITH_HINT(
					Variant::FLOAT, "debug_time_scale", PROPERTY_HINT_RANGE,
					"0.5,5.0,0.1"),
			"set_debug_time_scale", "get_debug_time_scale");

	ClassDB::bind_method(
			D_METHOD("get_render_debug_annotations"),
			&ScaffolderManifest::get_render_debug_annotations);
	ClassDB::bind_method(
			D_METHOD("set_render_debug_annotations", "p_value"),
			&ScaffolderManifest::set_render_debug_annotations);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO(Variant::BOOL, "render_debug_annotations"),
			"set_render_debug_annotations", "get_render_debug_annotations");

	ADD_GROUP("Advanced", "adv_");

	ClassDB::bind_method(
			D_METHOD("get_super_hud_scene"),
			&ScaffolderManifest::get_super_hud_scene);
	ClassDB::bind_method(
			D_METHOD("set_super_hud_scene", "p_scene"),
			&ScaffolderManifest::set_super_hud_scene);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO_WITH_HINT(
					Variant::OBJECT, "adv_super_hud_scene",
					PROPERTY_HINT_RESOURCE_TYPE, "PackedScene"),
			"set_super_hud_scene", "get_super_hud_scene");

	ClassDB::bind_method(
			D_METHOD("get_shell_scene"), &ScaffolderManifest::get_shell_scene);
	ClassDB::bind_method(
			D_METHOD("set_shell_scene", "p_scene"),
			&ScaffolderManifest::set_shell_scene);
	ADD_PROPERTY(
			EXPORTED_PROPERTY_INFO_WITH_HINT(
					Variant::OBJECT, "adv_shell_scene",
					PROPERTY_HINT_RESOURCE_TYPE, "PackedScene"),
			"set_shell_scene", "get_shell_scene");

	ClassDB::bind_method(
			D_METHOD("get_initial_screen"),
			&ScaffolderManifest::get_initial_screen);
	ClassDB::bind_method(
			D_METHOD("get_screen_scene", "p_name"),
			&ScaffolderManifest::get_screen_scene);
	ClassDB::bind_method(
			D_METHOD("has_screen_scene", "p_name"),
			&ScaffolderManifest::has_screen_scene);
}

Ref<ScaffolderManifest> ScaffolderManifest::get() {
	Scaffolder *scaffolder = Scaffolder::get();
	CHECK(scaffolder, "Scaffolder is not initialized.");
	return scaffolder->get_manifest();
}

String ScaffolderManifest::get_initial_screen() const {
	if (SnoreCoreMainManifest::get()->get_dev_mode() &&
		skip_main_menu_in_dev_mode) {
		return "game";
	} else {
		return "main_menu";
	}
}

Ref<PackedScene> ScaffolderManifest::get_screen_scene(
		const String &p_name) const {
	if (screens.has(p_name)) {
		return screens[p_name];
	}
	return Ref<PackedScene>();
}

bool ScaffolderManifest::has_screen_scene(const String &p_name) const {
	return screens.has(p_name);
}
