extends Node
class_name SquirrelAwayConfig

var debug := OS.is_debug_build()

# TODO: Useful for getting screenshots at specific resolutions.
# Play Store
#var window_size := Vector2(3840, 2160)
# App Store: 6.5'' iPhone
#var window_size := Vector2(2778, 1284)
# App Store: 5.5'' iPhone
#var window_size := Vector2(2208, 1242)
# App Store: 12.9'' iPad (3rd Gen) and (2nd Gen)
#var window_size := Vector2(2732, 2048)
# Google Ads: Landscape
#var window_size := Vector2(1024, 768)
# Google Ads: Portrait
#var window_size := Vector2(768, 1024)
# Default
#var window_size := Vector2(480.0, 480.0)
# Just show as full screen.
var window_size := Vector2.INF

const _LEVEL_RESOURCE_PATH := "res://src/levels/level_6.tscn"

var _APP_MANIFEST := {
    # TODO: Remember to reset these when creating releases.
    debug = debug,
    #debug = false
    playtest = false,
    window_size = window_size,
    
    google_analytics_id = "TODO",
    
    app_name = "TODO",
    app_id = "games.snoringcat.TODO",
    app_version = "0.0.1",
    
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
    
    screen_exclusions = [
        "rate_app_screen.tscn",
    ],
    screen_inclusions = [
    ],
    
    main_menu_music = "on_a_quest",
    
    snoring_cat_games_url = "https://snoringcat.games",
    godot_url = "https://godotengine.org",
    
    godot_splash_screen_duration_sec = 0.8 if !debug else 0.0,
    snoring_cat_splash_screen_duration_sec = 1.0 if !debug else 0.0,
    
    main_font_normal = \
            preload("res://assets/fonts/main_font_normal.tres"),
    main_font_large = \
            preload("res://assets/fonts/main_font_l.tres"),
    main_font_xl = \
            preload("res://assets/fonts/main_font_xl.tres"),
    
    cell_size = Vector2(32.0, 32.0),
    
    aspect_ratio_max = 1.0 / 1.0,
    aspect_ratio_min = 1.0 / 1.3,
}

var _SOUNDS_MANIFEST := [
    {
        name = "fall",
        volume_db = 18.0,
    },
    {
        name = "cadence",
        volume_db = 8.0,
    },
    {
        name = "jump",
        volume_db = -6.0,
    },
    {
        name = "land",
        volume_db = -0.0,
    },
    {
        name = "menu_select",
        volume_db = -2.0,
    },
    {
        name = "menu_select_fancy",
        volume_db = -6.0,
    },
    {
        name = "walk",
        volume_db = 15.0,
    },
    {
        name = "achievement",
        volume_db = 12.0,
    },
    {
        name = "single_cat_snore",
        volume_db = 17.0,
    },
]

var _MUSIC_MANIFEST := [
    {
        name = "on_a_quest",
        volume_db = 0.0,
    },
]

func configure_scaffolding(main: Node) -> void:
    ScaffoldConfig.register_app_config(_APP_MANIFEST)
    ScaffoldConfig.next_level_resource_path = _LEVEL_RESOURCE_PATH
    Audio.register_sounds(_SOUNDS_MANIFEST)
    Audio.register_music(_MUSIC_MANIFEST)
    var scaffold_bootstrap := ScaffoldBootstrap.new()
    scaffold_bootstrap.on_app_ready(main)
