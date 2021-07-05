class_name SurfacerLoadingScreen
extends Screen


var level_id := ""
var graph_load_start_time := INF


func _ready() -> void:
    if Engine.editor_hint:
        return
    
    var loading_image_wrapper := $VBoxContainer/LoadingImageWrapper
    loading_image_wrapper.visible = Gs.gui.is_loading_image_shown
    if Gs.gui.is_loading_image_shown:
        var loading_image: ScaffolderConfiguredImage = Gs.utils.add_scene(
                loading_image_wrapper,
                Gs.gui.loading_image_scene,
                true,
                true, \
                0)
        loading_image.original_scale = Gs.gui.loading_image_scale
    
    $VBoxContainer.rect_min_size.x = Gs.gui.screen_body_width
    
    _on_resized()


func set_params(params) -> void:
    .set_params(params)
    
    assert(params != null)
    assert(params.has("level_id"))
    level_id = params.level_id


func get_is_nav_bar_shown() -> bool:
    return true


func _on_activated(previous_screen: Screen) -> void:
    ._on_activated(previous_screen)
    if Gs.device.get_is_browser_app():
        Gs.audio.stop_music()
    Gs.time.set_timeout(funcref(self, "_load_level"), 0.05)


func _load_level() -> void:
    Gs.level_session.reset(level_id)
    Gs.save_state.set_last_level_played(level_id)
    
    $VBoxContainer/ProgressBar.value = 0.0
    $VBoxContainer/Label1.text = ""
    $VBoxContainer/Label2.text = ""
    
    var level: SurfacerLevel = Gs.utils.add_scene(
            null,
            Gs.level_config.get_level_config(level_id).scene_path,
            false,
            true)
    if Surfacer.debug_params.has("limit_parsing"):
        level.script = DebugLevel
    Gs.nav.screens["game"].add_level(level)
    level.graph_parser.connect(
            "calculation_started",
            self,
            "_on_calculation_started")
    level.graph_parser.connect(
            "load_started",
            self,
            "_on_load_started")
    level.graph_parser.connect(
            "calculation_progressed",
            self,
            "_on_graph_parse_progress")
    level.graph_parser.connect(
            "parse_finished",
            self,
            "_on_graph_parse_finished")
    graph_load_start_time = Gs.time.get_clock_time()
    level._load()


func _on_calculation_started() -> void:
    container.nav_bar.text = "Calculating platform graphs"
    $VBoxContainer/Duration.text = Gs.utils.get_time_string_from_seconds( \
            0.0, \
            false, \
            false, \
            true)
    $VBoxContainer/Label1.text = "Parsing surfaces"
    $VBoxContainer/Label2.text = ""


func _on_load_started() -> void:
    container.nav_bar.text = "Loading platform graphs"


func _on_graph_parse_progress(
        player_index: int,
        player_count: int,
        origin_surface_index: int,
        surface_count: int) -> void:
    var current_graph_calculation_progress_ratio := \
            origin_surface_index / float(surface_count)
    var progress := \
            (player_index + current_graph_calculation_progress_ratio) / \
            float(player_count) * \
            100.0
    
    var player_name: String = \
            Gs.level_config.get_level_config(Gs.level_session.id) \
            .platform_graph_player_names[player_index]
    var label_1 := "Player %s (%s of %s)" % [
        player_name,
        player_index + 1,
        player_count,
    ]
    var label_2 := "Out-bound surface %s of %s" % [
        origin_surface_index + 1,
        surface_count,
    ]
    
    $VBoxContainer/ProgressBar.value = progress
    $VBoxContainer/Duration.text = Gs.utils.get_time_string_from_seconds( \
            Gs.time.get_clock_time() - graph_load_start_time, \
            false, \
            false, \
            true)
    $VBoxContainer/Label1.text = label_1
    $VBoxContainer/Label2.text = label_2


# This is called when the graphs are ready, regardless of whether they were
# calculated-on-demand or loaded from a file.
func _on_graph_parse_finished() -> void:
    Gs.level.graph_parser.disconnect(
            "calculation_started",
            self,
            "_on_calculation_started")
    Gs.level.graph_parser.disconnect(
            "load_started",
            self,
            "_on_load_started")
    Gs.level.graph_parser.disconnect(
            "calculation_progressed",
            self,
            "_on_graph_parse_progress")
    Gs.level.graph_parser.disconnect(
            "parse_finished",
            self,
            "_on_graph_parse_finished")
    
    if !Gs.level.graph_parser.is_loaded_from_file:
        Gs.utils.give_button_press_feedback()
    
    Gs.analytics.event(
            "graphs",
            "loaded",
            Gs.level_config.get_level_version_string(Gs.level_session.id),
            Gs.time.get_clock_time() - graph_load_start_time)
    
    Gs.nav.open("game", true)
    
    Gs.time.set_timeout( \
            funcref(Gs.level, "_start"), \
            Gs.nav.fade_transition.duration / 2.0)
