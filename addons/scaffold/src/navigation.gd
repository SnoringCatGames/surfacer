extends Node

const _DEFAULT_SCREEN_PATH_PREFIX := "res://addons/scaffold/src/gui/screens/"
const _DEFAULT_SCREEN_FILENAMES := [
    "GodotSplashScreen.tscn",
    "DeveloperSplashScreen.tscn",
    "MainMenuScreen.tscn",
    "SettingsScreen.tscn",
    "PauseScreen.tscn",
    "GameScreen.tscn",
    "ThirdPartyLicensesScreen.tscn",
    "CreditsScreen.tscn",
    "DataAgreementScreen.tscn",
    "RateAppScreen.tscn",
    "ConfirmDataDeletionScreen.tscn",
    "NotificationScreen.tscn",
]
const FADE_TRANSITION_PATH := \
        _DEFAULT_SCREEN_PATH_PREFIX + "FadeTransition.tscn"

const SCREEN_SLIDE_DURATION_SEC := 0.3
const SCREEN_FADE_DURATION_SEC := 1.2
const SESSION_END_TIMEOUT_SEC := 2.0

# Dictionary<String, Screen>
var screens := {}
# Array<Screen>
var active_screen_stack := []

var fade_transition: FadeTransition

func _init() -> void:
    ScaffoldUtils.print("Navigation._init")

func _ready() -> void:
    fade_transition.connect( \
            "fade_complete", \
            self, \
            "_on_fade_complete")
    get_tree().set_auto_accept_quit(false)
    Analytics.connect( \
            "session_end", \
            self, \
            "_on_session_end")
    Analytics.start_session()

func _notification(notification: int) -> void:
    if notification == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
        # Handle the Android back button to navigate within the app instead of
        # quitting the app.
        if get_active_screen_name() == "main_menu":
            Analytics.end_session()
            Time.set_timeout( \
                    funcref(self, "_on_session_end"), \
                    SESSION_END_TIMEOUT_SEC)
        else:
            call_deferred("close_current_screen")
    elif notification == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
        Analytics.end_session()
        Time.set_timeout( \
                funcref(self, "_on_session_end"), \
                SESSION_END_TIMEOUT_SEC)

func _on_session_end() -> void:
    get_tree().quit()

func _create_screen(path: String) -> void:
    var screen: Screen = ScaffoldUtils.add_scene( \
            null, \
            path, \
            false, \
            false)
    ScaffoldConfig.canvas_layers.layers[screen.layer_name].add_child(screen)
    screen.pause_mode = Node.PAUSE_MODE_STOP
    screens[screen.screen_name] = screen

func create_screens( \
        exclusions: Array, \
        inclusions: Array) -> void:
    var exclusions_set := {}
    for exclusion in exclusions:
        exclusions_set[exclusion] = true
    
    for filename in _DEFAULT_SCREEN_FILENAMES:
        if exclusions_set.has(filename):
            continue
        _create_screen(_DEFAULT_SCREEN_PATH_PREFIX + filename)
    
    for path in inclusions:
        _create_screen(path)
    
    fade_transition = ScaffoldUtils.add_scene( \
            ScaffoldConfig.canvas_layers.layers.top, \
            FADE_TRANSITION_PATH, \
            true, \
            false)
    fade_transition.duration = SCREEN_FADE_DURATION_SEC

func open( \
        screen_name: String, \
        includes_fade := false, \
        params = null) -> void:
    var previous_name := \
            get_active_screen_name() if \
            !active_screen_stack.empty() else \
            "-"
    ScaffoldUtils.print("Nav.open: %s=>%s" % [
        previous_name,
        screen_name,
    ])
    
    _set_screen_is_open( \
            screen_name, \
            true, \
            includes_fade, \
            params)

func close_current_screen(includes_fade := false) -> void:
    assert(!active_screen_stack.empty())
    
    var previous_name := get_active_screen_name()
    var previous_index := active_screen_stack.find(screens[previous_name])
    assert(previous_index >= 0)
    var next_name = \
            active_screen_stack[previous_index - 1].screen_name if \
            previous_index > 0 else \
            "-"
    ScaffoldUtils.print("Nav.close_current_screen: %s=>%s" % [
        previous_name,
        next_name,
    ])
    
    _set_screen_is_open( \
            previous_name, \
            false, \
            includes_fade, \
            null)

func get_active_screen() -> Screen:
    return active_screen_stack.back()

func get_active_screen_name() -> String:
    return get_active_screen().screen_name

func _set_screen_is_open( \
        screen_name: String, \
        is_open: bool, \
        includes_fade := false, \
        params = null) -> void:
    var next_screen: Screen
    var previous_screen: Screen
    if is_open:
        next_screen = screens[screen_name]
        previous_screen = \
                active_screen_stack.back() if \
                !active_screen_stack.empty() else \
                null
    else:
        previous_screen = screens[screen_name]
        var index := active_screen_stack.find(previous_screen)
        assert(index >= 0)
        next_screen = \
                active_screen_stack[index - 1] if \
                index > 0 else \
                null
    
    var is_paused: bool = \
            next_screen != null and \
            next_screen.screen_name != "game"
    var is_first_screen := is_open and active_screen_stack.empty()
    
    var next_screen_was_already_shown := false
    if is_open:
        if !active_screen_stack.has(next_screen):
            active_screen_stack.push_back(next_screen)
        else:
            next_screen_was_already_shown = true
    
    # Remove all (potential) following screens from the stack.
    var index := active_screen_stack.find(next_screen)
    while index + 1 < active_screen_stack.size():
        var removed_screen: Screen = active_screen_stack.back()
        active_screen_stack.pop_back()
        removed_screen.visible = false
    
    get_tree().paused = is_paused
    
    if previous_screen != null:
        previous_screen.visible = true
        previous_screen.z_index = \
                -100 + active_screen_stack.find(previous_screen) if \
                active_screen_stack.has(previous_screen) else \
                -100 + active_screen_stack.size()
    if next_screen != null:
        next_screen.visible = true
        next_screen.z_index = -100 + active_screen_stack.find(next_screen)
    
    if !is_first_screen:
        var start_position: Vector2
        var end_position: Vector2
        var tween_screen: Screen
        if screen_name == "game":
            start_position = Vector2.ZERO
            end_position = Vector2( \
                    -get_viewport().size.x, \
                    0.0)
            tween_screen = previous_screen
        elif next_screen_was_already_shown:
            start_position = Vector2( \
                    get_viewport().size.x, \
                    0.0)
            end_position = Vector2.ZERO
            tween_screen = next_screen
            var swap_z_index := next_screen.z_index
            next_screen.z_index = previous_screen.z_index
            previous_screen.z_index = swap_z_index
        elif is_open:
            start_position = Vector2( \
                    get_viewport().size.x, \
                    0.0)
            end_position = Vector2.ZERO
            tween_screen = next_screen
        else:
            start_position = Vector2.ZERO
            end_position = Vector2( \
                    get_viewport().size.x, \
                    0.0)
            tween_screen = previous_screen
        
        var slide_duration := SCREEN_SLIDE_DURATION_SEC
        var slide_delay := 0.0
        if includes_fade:
            fade_transition.visible = true
            fade_transition.fade()
            slide_duration = SCREEN_SLIDE_DURATION_SEC / 2.0
            slide_delay = (SCREEN_FADE_DURATION_SEC - slide_duration) / 2.0
        
        var screen_slide_tween := Tween.new()
        add_child(screen_slide_tween)
        tween_screen.position = start_position
        screen_slide_tween.interpolate_property( \
                tween_screen, \
                "position", \
                start_position, \
                end_position, \
                SCREEN_SLIDE_DURATION_SEC, \
                Tween.TRANS_QUAD, \
                Tween.EASE_IN_OUT, \
                slide_delay)
        screen_slide_tween.start()
        screen_slide_tween.connect( \
                "tween_completed", \
                self, \
                "_on_screen_slide_completed", \
                [ \
                        previous_screen, \
                        next_screen, \
                        screen_slide_tween, \
                ])
    
    if previous_screen != null:
        previous_screen._on_deactivated()
        previous_screen.pause_mode = Node.PAUSE_MODE_STOP
    
    if next_screen != null:
        next_screen.set_params(params)
        
        # If opening a new screen, auto-scroll to the top. Otherwise, if
        # navigating back to a previous screen, maintain the scroll position,
        # so the user can remember where they were.
        if is_open:
            next_screen._scroll_to_top()
        
        Analytics.screen(next_screen.screen_name)

func _on_screen_slide_completed( \
        _object: Object, \
        _key: NodePath, \
        previous_screen: Screen, \
        next_screen: Screen, \
        tween: Tween) -> void:
    tween.queue_free()
    
    if previous_screen != null:
        previous_screen.visible = false
        previous_screen.position = Vector2.ZERO
    if next_screen != null:
        next_screen.visible = true
        next_screen.position = Vector2.ZERO
        next_screen.pause_mode = Node.PAUSE_MODE_PROCESS
        next_screen._on_activated()

func _on_fade_complete() -> void:
    if !fade_transition.is_transitioning:
        fade_transition.visible = false

func splash() -> void:
    open("godot_splash")
    Audio.play_sound(ScaffoldConfig.godot_splash_sound)
    yield(get_tree() \
            .create_timer(ScaffoldConfig.godot_splash_screen_duration_sec), \
            "timeout")
    
    if ScaffoldConfig.is_developer_splash_shown:
        open("developer_splash")
        Audio.play_sound(ScaffoldConfig.developer_splash_sound)
        yield(get_tree() \
                .create_timer(ScaffoldConfig \
                        .developer_splash_screen_duration_sec), \
                "timeout")
    
    var next_screen_name := \
        "main_menu" if \
        ScaffoldConfig.agreed_to_terms or \
        !ScaffoldConfig.is_data_tracked else \
        "data_agreement"
    open(next_screen_name)
    # Start playing the default music for the menu screen.
    Audio.play_music(ScaffoldConfig.main_menu_music, true)
