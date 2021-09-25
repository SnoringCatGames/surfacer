tool
class_name InspectorPanel, \
"res://addons/scaffolder/assets/images/editor_icons/scaffolder_placeholder.png"
extends VBoxContainer


const PANEL_MARGIN_RIGHT := 20.0
const TOGGLE_DURATION := 0.2
const ANNOTATOR_ROW_HEIGHT := 21.0
const CHECK_BOX_SCALE := 0.5
const SLIDER_WIDTH := 64.0

var is_open := false setget _set_is_open
var tree_font_size := "Xs" setget _set_tree_font_size

var _annotator_control_items := []

var _annotator_control_item_classes := [
    CharacterAnnotatorControlRow,
    PlayerPreselectionTrajectoryAnnotatorControlRow,
    CharacterPositionAnnotatorControlRow,
    PlayerNonSlowMoTrajectoryAnnotatorControlRow,
    LevelAnnotatorControlRow,
    PlayerSlowMoTrajectoryAnnotatorControlRow,
    SurfacesAnnotatorControlRow,
    PlayerPreviousTrajectoryAnnotatorControlRow,
    RulerAnnotatorControlRow,
    PlayerNavigationDestinationAnnotatorControlRow,
    RecentMovementAnnotatorControlRow,
    NpcNonSlowMoTrajectoryAnnotatorControlRow,
    TimeScaleControlRow,
    NpcSlowMoTrajectoryAnnotatorControlRow,
    CameraZoomControlRow,
    NpcPreviousTrajectoryAnnotatorControlRow,
    MetronomeControlRow,
    NpcNavigationDestinationAnnotatorControlRow,
]


func _ready() -> void:
    $ScaffolderPanelContainer/VBoxContainer/Header/XButtonWrapper/XButton \
            .texture_scale = Vector2(2.0, 2.0)
    $Footer/GearButton.texture_scale = Vector2(4.0, 4.0)
    $Footer/PauseButton.texture_scale = Vector2(4.0, 4.0)
    
    _set_tree_font_size(tree_font_size)
    
    Sc.gui.record_gui_original_size_recursively(self)
    
    assert(Su.is_inspector_enabled)
    
    theme = Sc.gui.theme
    
    var x_button := \
            $ScaffolderPanelContainer/VBoxContainer/Header/XButtonWrapper/ \
            XButton
    x_button.set_meta("sc_rect_position", x_button.rect_position)
    
    Sc.gui.add_gui_to_scale(self)
    
    _set_footer_visibility(!is_open)
    
    Su.graph_inspector = \
            $ScaffolderPanelContainer/VBoxContainer/Sections/ \
            InspectorContainer/PlatformGraphInspector
    Su.legend = \
            $ScaffolderPanelContainer/VBoxContainer/Sections/Legend
    Su.selection_description = \
            $ScaffolderPanelContainer/VBoxContainer/Sections/ \
            SelectionDescription
    
    if (Sc.gui.hud_manifest.inspector_panel_starts_open or \
                Su.debug_params.has("limit_parsing")) and \
            !OS.has_touchscreen_ui_hint():
        _set_is_open(true)
    
    if !Engine.editor_hint:
        # Tell the element annotator to populate the legend, now that it's
        # available.
        Sc.annotators.element_annotator.update()
        
        _initialize_annotator_checkboxes()
    
    _on_gui_scale_changed()


func _destroy() -> void:
    Sc.gui.remove_gui_to_scale(self)
    Sc.gui.active_overlays.erase(self)
    if is_instance_valid(Su.graph_inspector):
        Su.graph_inspector._destroy()
    Su.graph_inspector = null
    if is_instance_valid(Su.legend):
        Su.legend._destroy()
    Su.legend = null
    Su.selection_description = null


func _on_gui_scale_changed() -> bool:
    call_deferred("_deferred_on_gui_scale_changed")
    return true


func _deferred_on_gui_scale_changed() -> void:
    var x_button := \
            $ScaffolderPanelContainer/VBoxContainer/Header/XButtonWrapper/ \
            XButton
    x_button.rect_position = \
            x_button.get_meta("sc_rect_position") * Sc.gui.scale
    
    for child in Sc.utils.get_children_by_type(self, Control):
        Sc.gui.scale_gui_recursively(child)
    
    rect_size.x = $ScaffolderPanelContainer.rect_size.x
    
    _set_footer_visibility(!is_open)
    
    rect_position.x = \
            Sc.device.get_viewport_size().x - \
            rect_size.x - \
            PANEL_MARGIN_RIGHT * Sc.gui.scale
    rect_position.y = \
            0.0 if \
            is_open else \
            _get_closed_position_y()
    
    var panel_stylebox: StyleBox = \
            $ScaffolderPanelContainer.get_stylebox("panel")
    if panel_stylebox is StyleBoxFlatScalable:
        panel_stylebox.border_width_top = 0.0


func _initialize_annotator_checkboxes() -> void:
    var empty_style := StyleBoxEmpty.new()
    var annotators := \
            $ScaffolderPanelContainer/VBoxContainer/Sections/MarginContainer/ \
            Annotators
    for child in annotators.get_children():
        child.queue_free()
    var item_width: float = \
            (annotators.rect_size.x - \
                annotators.get_constant("hseparation")) / \
            4.0
    for item_class in _annotator_control_item_classes:
        var item: ControlRow = item_class.new()
        item.font_size = tree_font_size
        item.is_control_on_right_side = false
        item.update_item()
        _annotator_control_items.push_back(item)
        
        var row := item.create_row(
                empty_style,
                ANNOTATOR_ROW_HEIGHT,
                4.0,
                4.0,
                false)
        row.rect_min_size.x = item_width
        
        for label in Sc.utils.get_children_by_type(row, Label, true):
            label.add_font_override("font", Sc.gui.fonts.main_xxs)
        
        if item.type == ControlRow.CHECKBOX:
            item.set_check_box_scale(CHECK_BOX_SCALE)
        
        if item.type == ControlRow.SLIDER:
            item.set_original_size(
                    Vector2(SLIDER_WIDTH, item.control.rect_size.y))
        
        annotators.add_child(row)
    
    for child in annotators.get_children():
        Sc.gui.scale_gui_recursively(child)


func _get_closed_position_y() -> float:
    return -$ScaffolderPanelContainer.rect_size.y - 1.0


func _set_is_open(value: bool) -> void:
    if is_open != value:
        _toggle_open()


func _set_tree_font_size(value: String) -> void:
    tree_font_size = value
    var font: Font = Sc.gui.get_font(tree_font_size)
    $ScaffolderPanelContainer/VBoxContainer/Header/PauseButton \
            .add_font_override("font", font)
    $ScaffolderPanelContainer/VBoxContainer/Sections/InspectorContainer/ \
            PlatformGraphInspector \
            .add_font_override("font", font)
    for item in _annotator_control_items:
        item.font_size = tree_font_size


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
        position_y_end = _get_closed_position_y()
        duration = TOGGLE_DURATION
    
    # Start the sliding animation.
    Sc.time.tween_property(
            self,
            "rect_position:y",
            position_y_start,
            position_y_end,
            duration,
            "ease_out")
    
    _set_footer_visibility(!is_open)
    
    if is_open:
        Su.graph_inspector.select_first_item()
    else:
        Su.graph_inspector.collapse()
    
    Sc.gui.active_overlays.erase(self)
    if is_open:
        Sc.gui.active_overlays.push_back(self)
    
    Sc.utils.release_focus()


func _set_footer_visibility(is_visible: bool) -> void:
    $Spacer.visible = is_visible
    $Footer.visible = is_visible
    rect_size.y = \
            $ScaffolderPanelContainer.rect_size.y + \
                    $Spacer.rect_size.y + \
                    $Footer.rect_size.y if \
            is_visible else \
            $ScaffolderPanelContainer.rect_size.y


func _on_GearButton_pressed() -> void:
    _toggle_open()


func _on_FooterPauseButton_pressed() -> void:
    Sc.level.pause()


func _on_HeaderXButton_pressed() -> void:
    Sc.utils.give_button_press_feedback()
    _toggle_open()


func _on_HeaderPauseButton_pressed() -> void:
    Sc.utils.give_button_press_feedback()
    Sc.level.pause()
