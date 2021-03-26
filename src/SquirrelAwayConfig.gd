extends Node

var debug := OS.is_debug_build()

# TODO: Useful for getting screenshots at specific resolutions.
# Play Store
#var debug_window_size := Vector2(3840, 2160)
# App Store: 6.5'' iPhone
#var debug_window_size := Vector2(2778, 1284)
# App Store: 5.5'' iPhone
#var debug_window_size := Vector2(2208, 1242)
# App Store: 12.9'' iPad (3rd Gen) and (2nd Gen)
#var debug_window_size := Vector2(2732, 2048)
# Google Ads: Landscape
var debug_window_size := Vector2(1024, 768)
# Google Ads: Portrait
#var debug_window_size := Vector2(768, 1024)
# Default
#var debug_window_size := Vector2(480, 480)
# Just show as full screen.
#var debug_window_size := Vector2.INF

var uses_threads := false and OS.can_use_threads()
var thread_count := \
        4 if \
        uses_threads else \
        1

var third_party_license_text := \
        ScaffoldThirdPartyLicenses.TEXT + \
        SurfacerThirdPartyLicenses.TEXT + \
        SquirrelAwayThirdPartyLicenses.TEXT

var special_thanks_text := """
"""

var theme := preload("res://assets/main_theme.tres")

var test_runner_resource_path := "res://test/TestRunner.tscn"

var fonts := {
    main_xs = preload("res://addons/scaffold/assets/fonts/main_font_xs.tres"),
    main_xs_italic = preload( \
            "res://addons/scaffold/assets/fonts/main_font_xs_italic.tres"),
    main_s = preload("res://addons/scaffold/assets/fonts/main_font_s.tres"),
    main_m = preload("res://addons/scaffold/assets/fonts/main_font_m.tres"),
    main_m_bold = preload( \
            "res://addons/scaffold/assets/fonts/main_font_m_bold.tres"),
    main_m_italic = preload( \
            "res://addons/scaffold/assets/fonts/main_font_m_italic.tres"),
    main_l = preload("res://addons/scaffold/assets/fonts/main_font_l.tres"),
    main_xl = preload("res://addons/scaffold/assets/fonts/main_font_xl.tres"),
}

var sounds_manifest := [
    {
        name = "fall",
        volume_db = 18.0,
        path_prefix = "res://addons/scaffold/assets/sounds/",
    },
    {
        name = "cadence",
        volume_db = 8.0,
        path_prefix = "res://addons/scaffold/assets/sounds/",
    },
    {
        name = "jump",
        volume_db = -6.0,
        path_prefix = "res://addons/scaffold/assets/sounds/",
    },
    {
        name = "land",
        volume_db = -0.0,
        path_prefix = "res://addons/scaffold/assets/sounds/",
    },
    {
        name = "menu_select",
        volume_db = -2.0,
        path_prefix = "res://addons/scaffold/assets/sounds/",
    },
    {
        name = "menu_select_fancy",
        volume_db = -6.0,
        path_prefix = "res://addons/scaffold/assets/sounds/",
    },
    {
        name = "lock_low",
        volume_db = 0.0,
        path_prefix = "res://addons/scaffold/assets/sounds/",
    },
    {
        name = "lock_high",
        volume_db = 0.0,
        path_prefix = "res://addons/scaffold/assets/sounds/",
    },
    {
        name = "walk",
        volume_db = 15.0,
        path_prefix = "res://addons/scaffold/assets/sounds/",
    },
    {
        name = "achievement",
        volume_db = 12.0,
        path_prefix = "res://addons/scaffold/assets/sounds/",
    },
    {
        name = "single_cat_snore",
        volume_db = 17.0,
        path_prefix = "res://addons/scaffold/assets/sounds/",
    },
    {
        name = "cat_jump",
        volume_db = 0.0,
    },
    {
        name = "cat_land",
        volume_db = 0.0,
    },
    {
        name = "contact",
        volume_db = 0.0,
    },
    {
        name = "squirrel_jump",
        volume_db = 0.0,
    },
    {
        name = "squirrel_land",
        volume_db = 0.0,
    },
    {
        name = "squirrel_yell",
        volume_db = 0.0,
    },
]

var music_manifest := [
    {
        name = "on_a_quest",
        volume_db = 0.0,
    },
]

var app_manifest := {
    # TODO: Remember to reset these when creating releases.
    debug = debug,
    #debug = false
    playtest = false,
    is_profiler_enabled = debug,
    is_inspector_enabled = debug,
    is_surfacer_logging = false,
    utility_panel_starts_open = false,
    debug_window_size = debug_window_size,
    uses_threads = uses_threads,
    thread_count = thread_count,
    is_mobile_supported = true,
    
    app_name = "Squirrel Away",
    app_id = "games.snoringcat.squirrel_away",
    app_version = "0.0.1",
    score_version = "0.0.1",
    
    theme = theme,
    
    # Must match Project Settings > Application > Boot Splash > Bg Color
    # Must match Project Settings > Rendering > Environment > Default Clear Color
    #273149
    screen_background_color = Color.from_hsv(0.617, 0.47, 0.29, 1.0),
    #576d99
    button_normal_color = Color.from_hsv(0.6111, 0.43, 0.6, 1.0),
    #89b4f0
    button_hover_color = Color.from_hsv(0.597, 0.43, 0.94, 1.0),
    #3a446e
    button_pressed_color = Color.from_hsv(0.633, 0.47, 0.43, 1.0),
    #bcc4c3
    shiny_button_highlight_color = Color.from_hsv(0.472, 0.40, 0.77, 1.0),
    #313b52
    key_value_even_row_color = Color.from_hsv(0.617, 0.4, 0.32, 1.0),
    #273149
    option_button_normal_color = Color.from_hsv(0.617, 0.47, 0.29, 1.0),
    #3e4c6f
    option_button_hover_color = Color.from_hsv(0.619, 0.44, 0.44, 1.0),
    #1b2235
    option_button_pressed_color = Color.from_hsv(0.622, 0.49, 0.21, 1.0),
    
    screen_filename_exclusions = [
        "RateAppScreen.tscn",
        "DataAgreementScreen.tscn",
        "ConfirmDataDeletionScreen.tscn",
    ],
    screen_path_inclusions = [],
    settings_main_item_class_exclusions = [],
    settings_main_item_class_inclusions = [],
    settings_details_item_class_exclusions = [],
    settings_details_item_class_inclusions = [],
    pause_item_class_exclusions = [],
    pause_item_class_inclusions = [],
    game_over_item_class_exclusions = [],
    game_over_item_class_inclusions = [],
    level_select_item_class_exclusions = [],
    level_select_item_class_inclusions = [],
    
    draw_utils = SurfacerDrawUtils.new(),
    level_config_class = SquirrelAwayLevelConfig,
    
    fonts = fonts,
    
    sounds_manifest = sounds_manifest,
    default_sounds_path_prefix = "res://assets/sounds/",
    default_sounds_file_suffix = ".wav",
    default_sounds_bus_index = 1,
    music_manifest = music_manifest,
    default_music_path_prefix = "res://addons/scaffold/assets/music/",
    default_music_file_suffix = ".ogg",
    default_music_bus_index = 2,
    
    main_menu_music = "on_a_quest",
    game_over_music = "on_a_quest",
    godot_splash_sound = "achievement",
    developer_splash_sound = "single_cat_snore",
    level_end_sound = "cadence",
    
    third_party_license_text = third_party_license_text,
    special_thanks_text = special_thanks_text,
    
    app_logo = preload("res://assets/images/gui/logo.png"),
    app_logo_scale = 2.0,
    developer_name = "Snoring Cat LLC",
    developer_url = "https://snoringcat.games",
    
    developer_logo = preload( \
            "res://addons/scaffold/assets/images/gui/snoring_cat_logo_about.png"),
    developer_splash = preload( \
            "res://addons/scaffold/assets/images/gui/snoring_cat_logo_splash.png"),
    
    # FIXME: -----------------
    godot_splash_screen_duration_sec = 0.8,
    developer_splash_screen_duration_sec = 1.0,
#    godot_splash_screen_duration_sec = 0.8 if !debug else 0.0,
#    developer_splash_screen_duration_sec = 1.0 if !debug else 0.0,
    
    main_menu_image_scene_path = "res://src/MainMenuImage.tscn",
    
    fade_in_transition_texture = \
            preload("res://addons/scaffold/assets/images/transition_in.png"),
    fade_out_transition_texture = \
            preload("res://addons/scaffold/assets/images/transition_out.png"),
    
    google_analytics_id = "",
    privacy_policy_url = "",
    terms_and_conditions_url = "",
    android_app_store_url = "",
    ios_app_store_url = "",
    support_url_base = "",
    log_gestures_url = "",
    
    cell_size = Vector2(32.0, 32.0),
    
    default_game_area_size = Vector2(1024, 768),
    aspect_ratio_max = 2.0 / 1.0,
    aspect_ratio_min = 1.0 / 2.0,
    uses_level_scores = true,
    
    default_camera_zoom = 1.0,
}

func _init() -> void:
    print("SquirrelAway._init")
