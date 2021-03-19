extends Node

# ---

const AGREED_TO_TERMS_SETTINGS_KEY := "agreed_to_terms"
const IS_GIVING_HAPTIC_FEEDBACK_SETTINGS_KEY := "is_giving_haptic_feedback"
const IS_DEBUG_PANEL_SHOWN_SETTINGS_KEY := "is_debug_panel_shown"
const IS_DEBUG_TIME_SHOWN_SETTINGS_KEY := "is_debug_time_shown"
const IS_MUSIC_ENABLED_SETTINGS_KEY := "is_music_enabled"
const IS_SOUND_EFFECTS_ENABLED_SETTINGS_KEY := "is_sound_effects_enabled"

const DEBUG_PANEL_RESOURCE_PATH := \
        "res://addons/scaffold/src/gui/DebugPanel.tscn"

const MIN_GUI_SCALE := 0.2

# --- Static configuration state ---

var debug: bool
var playtest: bool
var test := false

var debug_window_size: Vector2

var app_name: String
var app_id: String
var app_version: String

var cell_size: Vector2

# This should match what is configured in
# Project Settings > Display > Window > Size > Width/Height.
var default_game_area_size: Vector2

var aspect_ratio_max: float
var aspect_ratio_min: float

var screen_background_color: Color
var button_normal_color: Color
var button_hover_color: Color
var button_pressed_color: Color
var shiny_button_highlight_color: Color
var key_value_even_row_color: Color
var option_button_normal_color: Color
var option_button_hover_color: Color
var option_button_pressed_color: Color

var screen_exclusions: Array
var screen_inclusions: Array

var fonts: Dictionary

var sounds_manifest: Array
var default_sounds_path_prefix: String
var default_sounds_file_suffix: String
var default_sounds_bus_index: String
var music_manifest: Array
var default_music_path_prefix: String
var default_music_file_suffix: String
var default_music_bus_index: String
var main_menu_music: String

var third_party_license_text: String
var special_thanks_text: String

var app_logo: Texture
var developer_name: String
var developer_url: String

var developer_logo: Texture
var developer_splash: Texture

var godot_splash_sound := "achievement"
var developer_splash_sound: String

var godot_splash_screen_duration_sec := 0.8
var developer_splash_screen_duration_sec := 1.0

var main_menu_image_scene_path: String

var fade_in_transition_texture := \
        preload("res://addons/scaffold/assets/images/transition_in.png")
var fade_out_transition_texture := \
        preload("res://addons/scaffold/assets/images/transition_out.png")

var google_analytics_id: String
var terms_and_conditions_url: String
var privacy_policy_url: String
var android_app_store_url: String
var ios_app_store_url: String
var support_url_base: String
var log_gestures_url: String

var default_camera_zoom := 1.0

var input_vibrate_duration_sec := 0.01

var display_resize_throttle_interval_sec := 0.1

var recent_gesture_events_for_debugging_buffer_size := 1000

# --- Derived configuration ---

var is_special_thanks_shown: bool
var is_third_party_licenses_shown: bool
var is_data_tracked: bool
var is_rate_app_shown: bool
var is_support_shown: bool
var is_gesture_logging_supported: bool
var is_developer_logo_shown: bool
var is_developer_splash_shown: bool
var is_main_menu_image_shown: bool
var original_font_sizes: Dictionary

# --- Global state ---

var is_app_configured := false
var is_app_ready := false
var agreed_to_terms: bool
var is_giving_haptic_feedback: bool
var is_debug_panel_shown: bool setget \
        _set_is_debug_panel_shown, _get_is_debug_panel_shown
var is_debug_time_shown: bool

var game_area_region: Rect2
var gui_scale := 1.0
var canvas_layers: CanvasLayers
var camera_controller: CameraController
var debug_panel: DebugPanel
var gesture_record: GestureRecord
var next_level_resource_path: String
var level: ScaffoldLevel

# ---

func _init() -> void:
    print("ScaffoldConfig._init")

func register_app_manifest(manifest: Dictionary) -> void:
    self.debug = manifest.debug
    self.playtest = manifest.playtest
    self.debug_window_size = manifest.debug_window_size
    self.app_name = manifest.app_name
    self.app_id = manifest.app_id
    self.app_version = manifest.app_version
    self.cell_size = manifest.cell_size
    self.default_game_area_size = manifest.default_game_area_size
    self.aspect_ratio_max = manifest.aspect_ratio_max
    self.aspect_ratio_min = manifest.aspect_ratio_min
    self.screen_background_color = manifest.screen_background_color
    self.button_normal_color = manifest.button_normal_color
    self.button_hover_color = manifest.button_hover_color
    self.button_pressed_color = manifest.button_pressed_color
    self.shiny_button_highlight_color = manifest.shiny_button_highlight_color
    self.key_value_even_row_color = manifest.key_value_even_row_color
    self.option_button_normal_color = manifest.option_button_normal_color
    self.option_button_hover_color = manifest.option_button_hover_color
    self.option_button_pressed_color = manifest.option_button_pressed_color
    self.screen_exclusions = manifest.screen_exclusions
    self.screen_inclusions = manifest.screen_inclusions
    self.fonts = manifest.fonts
    self.sounds_manifest = manifest.sounds_manifest
    self.default_sounds_path_prefix = manifest.default_sounds_path_prefix
    self.default_sounds_file_suffix = manifest.default_sounds_file_suffix
    self.default_sounds_bus_index = manifest.default_sounds_bus_index
    self.music_manifest = manifest.music_manifest
    self.default_music_path_prefix = manifest.default_music_path_prefix
    self.default_music_file_suffix = manifest.default_music_file_suffix
    self.default_music_bus_index = manifest.default_music_bus_index
    self.main_menu_music = manifest.main_menu_music
    self.third_party_license_text = \
            manifest.third_party_license_text.strip_edges()
    self.special_thanks_text = manifest.special_thanks_text.strip_edges()
    self.app_logo = manifest.app_logo
    self.developer_name = manifest.developer_name
    self.developer_url = manifest.developer_url
    
    if manifest.has("developer_logo"):
        self.developer_logo = manifest.developer_logo
    if manifest.has("developer_splash"):
        self.developer_splash = manifest.developer_splash
    if manifest.has("godot_splash_sound"):
        self.godot_splash_sound = manifest.godot_splash_sound
    if manifest.has("developer_splash_sound"):
        self.developer_splash_sound = manifest.developer_splash_sound
    if manifest.has("godot_splash_screen_duration_sec"):
        self.godot_splash_screen_duration_sec = \
                manifest.godot_splash_screen_duration_sec
    if manifest.has("developer_splash_screen_duration_sec"):
        self.developer_splash_screen_duration_sec = \
                manifest.developer_splash_screen_duration_sec
    if manifest.has("main_menu_image_scene_path"):
        self.main_menu_image_scene_path = manifest.main_menu_image_scene_path
    if manifest.has("fade_in_transition_texture"):
        self.fade_in_transition_texture = manifest.fade_in_transition_texture
    if manifest.has("fade_out_transition_texture"):
        self.fade_out_transition_texture = manifest.fade_out_transition_texture
    if manifest.has("google_analytics_id"):
        self.google_analytics_id = manifest.google_analytics_id
    if manifest.has("terms_and_conditions_url"):
        self.terms_and_conditions_url = manifest.terms_and_conditions_url
    if manifest.has("privacy_policy_url"):
        self.privacy_policy_url = manifest.privacy_policy_url
    if manifest.has("android_app_store_url"):
        self.android_app_store_url = manifest.android_app_store_url
    if manifest.has("ios_app_store_url"):
        self.ios_app_store_url = manifest.ios_app_store_url
    if manifest.has("support_url_base"):
        self.support_url_base = manifest.support_url_base
    if manifest.has("log_gestures_url"):
        self.log_gestures_url = manifest.log_gestures_url
    if manifest.has("input_vibrate_duration_sec"):
        self.input_vibrate_duration_sec = \
                manifest.input_vibrate_duration_sec
    if manifest.has("display_resize_throttle_interval_sec"):
        self.display_resize_throttle_interval_sec = \
                manifest.display_resize_throttle_interval_sec
    if manifest.has("recent_gesture_events_for_debugging_buffer_size"):
        self.recent_gesture_events_for_debugging_buffer_size = \
                manifest.recent_gesture_events_for_debugging_buffer_size
    
    Audio.register_sounds( \
            manifest.sounds_manifest, \
            manifest.default_sounds_path_prefix, \
            manifest.default_sounds_file_suffix, \
            manifest.default_sounds_bus_index)
    Audio.register_music( \
            manifest.music_manifest, \
            manifest.default_music_path_prefix, \
            manifest.default_music_file_suffix, \
            manifest.default_music_bus_index)
    
    assert(self.google_analytics_id.empty() == \
            self.privacy_policy_url.empty() and \
            self.privacy_policy_url.empty() == \
            self.terms_and_conditions_url.empty())
    assert((self.developer_splash == null) == \
            self.developer_splash_sound.empty())
    
    self.is_special_thanks_shown = !self.special_thanks_text.empty()
    self.is_third_party_licenses_shown = !self.third_party_license_text.empty()
    self.is_data_tracked = \
            !self.privacy_policy_url.empty() and \
            !self.terms_and_conditions_url.empty() and \
            !self.google_analytics_id.empty()
    self.is_rate_app_shown = \
            !self.android_app_store_url.empty() and \
            !self.ios_app_store_url.empty()
    self.is_support_shown = !self.support_url_base.empty()
    self.is_gesture_logging_supported = !self.log_gestures_url.empty()
    self.is_developer_logo_shown = manifest.has("developer_logo")
    self.is_developer_splash_shown = \
            manifest.has("developer_splash") and \
            manifest.has("developer_splash_sound")
    self.is_main_menu_image_shown = manifest.has("main_menu_image_scene_path")
    
    self.is_app_configured = true
    
    _record_original_font_sizes()
    ScaffoldUtils._update_game_area_region_and_gui_scale()

func load_state() -> void:
    agreed_to_terms = SaveState.get_setting( \
            AGREED_TO_TERMS_SETTINGS_KEY, \
            false)
    is_giving_haptic_feedback = SaveState.get_setting( \
            IS_GIVING_HAPTIC_FEEDBACK_SETTINGS_KEY, \
            ScaffoldUtils.get_is_android_device())
    is_debug_panel_shown = SaveState.get_setting( \
            IS_DEBUG_PANEL_SHOWN_SETTINGS_KEY, \
            false)
    is_debug_time_shown = SaveState.get_setting( \
            IS_DEBUG_TIME_SHOWN_SETTINGS_KEY, \
            false)
    Audio.is_music_enabled = SaveState.get_setting( \
            IS_MUSIC_ENABLED_SETTINGS_KEY, \
            true)
    Audio.is_sound_effects_enabled = SaveState.get_setting( \
            IS_SOUND_EFFECTS_ENABLED_SETTINGS_KEY, \
            true)

func set_agreed_to_terms() -> void:
    agreed_to_terms = true
    SaveState.set_setting( \
            ScaffoldConfig.AGREED_TO_TERMS_SETTINGS_KEY, \
            true)

func _set_is_debug_panel_shown(is_visible: bool) -> void:
    is_debug_panel_shown = is_visible
    if debug_panel != null:
        debug_panel.visible = is_visible

func _get_is_debug_panel_shown() -> bool:
    return is_debug_panel_shown

func _record_original_font_sizes() -> void:
    for key in fonts:
        original_font_sizes[key] = fonts[key].size
