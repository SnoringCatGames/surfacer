extends PanelContainer
class_name UtilityPanel

const PANEL_MARGIN_RIGHT := 20.0
const TOGGLE_DURATION := 0.2
const DEFAULT_GUI_SCALE := 1.0

var is_open := false

var _toggle_open_tween: Tween

func _ready() -> void:
    Gs.add_gui_to_scale(self, DEFAULT_GUI_SCALE)
    
    $VBoxContainer/GearContainer/GearWrapper/GearButton.visible = !is_open
    
    _toggle_open_tween = Tween.new()
    add_child(_toggle_open_tween)
    
    SurfacerConfig.platform_graph_inspector = \
            $VBoxContainer/Sections/InspectorContainer/PlatformGraphInspector
    SurfacerConfig.legend = \
            $VBoxContainer/Sections/Legend
    SurfacerConfig.selection_description = \
            $VBoxContainer/Sections/SelectionDescription
    
    if (SurfacerConfig.utility_panel_starts_open or \
                    SurfacerConfig.debug_params.has("limit_parsing")) and \
            SurfacerConfig.debug_params.is_inspector_enabled and \
            !OS.has_touchscreen_ui_hint():
        set_is_open(true)
    
    if !SurfacerConfig.debug_params.is_inspector_enabled:
        $VBoxContainer/Sections.remove_child( \
                $VBoxContainer/Sections/SelectionDescription)
        $VBoxContainer/Sections.remove_child( \
                $VBoxContainer/Sections/LegendHeader)
        $VBoxContainer/Sections.remove_child( \
                $VBoxContainer/Sections/Legend)
        $VBoxContainer/Sections.remove_child( \
                $VBoxContainer/Sections/InspectorContainer)
    
    $VBoxContainer/Sections/Annotators/RulerGridCheckbox.pressed = \
            SurfacerConfig.annotators.is_annotator_enabled(AnnotatorType.RULER)
    $VBoxContainer/Sections/Annotators/LevelCheckbox.pressed = \
            SurfacerConfig.annotators.is_annotator_enabled(AnnotatorType.LEVEL)
    $VBoxContainer/Sections/Annotators/PlayerPositionCheckbox.pressed = \
            SurfacerConfig.annotators.is_annotator_enabled( \
                    AnnotatorType.PLAYER_POSITION)
    $VBoxContainer/Sections/Annotators/PlayerTrajectoryCheckbox.pressed = \
            SurfacerConfig.annotators.is_annotator_enabled( \
                    AnnotatorType.PLAYER_TRAJECTORY)
    $VBoxContainer/Sections/Annotators/LogEventsCheckbox.pressed = \
            SurfacerConfig.is_logging_events
    
    # Tell the element annotator to populate the legend, now that it's
    # available.
    SurfacerConfig.annotators.element_annotator.update()
    
    Gs.utils.connect( \
            "display_resized", \
            self, \
            "_on_resized")
    _on_resized()

func destroy() -> void:
    Gs.guis_to_scale.erase(self)

func _on_resized() -> void:
    self.rect_position.x = \
            get_viewport().size.x - self.rect_size.x - PANEL_MARGIN_RIGHT
    self.rect_position.y = \
            0.0 if \
            self.is_open else \
            -self.rect_size.y - 1.0

func _on_credits_button_pressed():
    Gs.utils.give_button_press_feedback()
    $CreditsPanel.popup()

func set_is_open(is_open: bool) -> void:
    if self.is_open != is_open:
        _toggle_open()

func _toggle_open() -> void:
    is_open = !is_open
    
    var position_y_start: float = self.rect_position.y
    var position_y_end: float
    var duration: float
    var text: String
    
    if is_open:
        position_y_end = 0.0
        duration = TOGGLE_DURATION
    else:
        position_y_end = -self.rect_size.y - 1.0
        duration = TOGGLE_DURATION
    
    # Start the sliding animation.
    _toggle_open_tween.reset_all()
    _toggle_open_tween.interpolate_property( \
            self, \
            "rect_position:y", \
            position_y_start, \
            position_y_end, \
            duration, \
            Tween.TRANS_LINEAR, \
            Tween.EASE_IN)
    _toggle_open_tween.start()
    
    $VBoxContainer/GearContainer/GearWrapper/GearButton.visible = !is_open
    
    if is_open:
        SurfacerConfig.platform_graph_inspector.select_first_item()
    else:
        SurfacerConfig.platform_graph_inspector.collapse()

func _on_ruler_grid_checkbox_toggled(pressed: bool) -> void:
    Gs.utils.give_button_press_feedback()
    SurfacerConfig.annotators.set_annotator_enabled( \
            AnnotatorType.RULER, \
            pressed)

func _on_level_checkbox_toggled(pressed: bool) -> void:
    Gs.utils.give_button_press_feedback()
    SurfacerConfig.annotators.set_annotator_enabled( \
            AnnotatorType.LEVEL, \
            pressed)

func _on_player_position_checkbox_toggled(pressed: bool) -> void:
    Gs.utils.give_button_press_feedback()
    SurfacerConfig.annotators.set_annotator_enabled( \
            AnnotatorType.PLAYER_POSITION, \
            pressed)

func _on_player_trajectory_checkbox_toggled(pressed: bool) -> void:
    Gs.utils.give_button_press_feedback()
    SurfacerConfig.annotators.set_annotator_enabled( \
            AnnotatorType.PLAYER_TRAJECTORY, \
            pressed)

func _on_log_events_checkbox_toggled(pressed: bool) -> void:
    Gs.utils.give_button_press_feedback()
    SurfacerConfig.is_logging_events = pressed

func _on_PauseButton_pressed():
    Gs.utils.give_button_press_feedback()
    Gs.nav.open("pause")
