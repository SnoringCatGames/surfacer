class_name InspectorPanel, "res://addons/scaffolder/assets/images/editor_icons/scaffolder_placeholder.png"
extends VBoxContainer


const PANEL_MARGIN_RIGHT := 20.0
const TOGGLE_DURATION := 0.2
const ANNOTATOR_ROW_HEIGHT := 21.0
const CHECK_BOX_SCALE := 0.5
const SLIDER_WIDTH := 72.0

var is_open := false setget _set_is_open,_get_is_open

var _annotator_control_items := []

var _annotator_control_item_classes := [
    PlayerAnnotatorSettingsLabeledControlItem,
    LevelAnnotatorSettingsLabeledControlItem,
    PlayerPositionAnnotatorSettingsLabeledControlItem,
    SurfacesAnnotatorSettingsLabeledControlItem,
    RecentMovementAnnotatorSettingsLabeledControlItem,
    RulerAnnotatorSettingsLabeledControlItem,
    PreselectionTrajectoryAnnotatorSettingsLabeledControlItem,
    PreviousTrajectoryAnnotatorSettingsLabeledControlItem,
    ActiveTrajectoryAnnotatorSettingsLabeledControlItem,
    NavigationDestinationAnnotatorSettingsLabeledControlItem,
    TimeScaleSettingsLabeledControlItem,
    CameraZoomSettingsLabeledControlItem,
    MetronomeSettingsLabeledControlItem,
    LogSurfacerEventsSettingsLabeledControlItem,
]


func _ready() -> void:
    if Engine.editor_hint:
        return
    
    Gs.utils.record_gui_original_size_recursively(self)
    
    assert(Surfacer.is_inspector_enabled)
    
    theme = Gs.gui.theme
    
    var x_button := $PanelContainer/VBoxContainer/Header/XButtonWrapper/XButton
    x_button.set_meta("gs_rect_position", x_button.rect_position)
    
    Gs.gui.add_gui_to_scale(self)
    
    _set_footer_visibility(!is_open)
    
    Surfacer.graph_inspector = \
            $PanelContainer/VBoxContainer/Sections/InspectorContainer/ \
            PlatformGraphInspector
    Surfacer.legend = \
            $PanelContainer/VBoxContainer/Sections/Legend
    Surfacer.selection_description = \
            $PanelContainer/VBoxContainer/Sections/SelectionDescription
    
    if (Gs.gui.hud_manifest.inspector_panel_starts_open or \
                Surfacer.debug_params.has("limit_parsing")) and \
            !OS.has_touchscreen_ui_hint():
        _set_is_open(true)
    
    # Tell the element annotator to populate the legend, now that it's
    # available.
    Surfacer.annotators.element_annotator.update()
    
    _initialize_annotator_checkboxes()
    
    update_gui_scale()


func _exit_tree() -> void:
    if Engine.editor_hint:
        return
    
    Gs.gui.remove_gui_to_scale(self)
    Gs.gui.active_overlays.erase(self)
    Surfacer.graph_inspector = null
    Surfacer.legend = null
    Surfacer.selection_description = null


func update_gui_scale() -> bool:
    call_deferred("_deferred_update_gui_scale")
    return true


func _deferred_update_gui_scale() -> void:
    var x_button := $PanelContainer/VBoxContainer/Header/XButtonWrapper/XButton
    x_button.rect_position = \
            x_button.get_meta("gs_rect_position") * Gs.gui.scale
    for child in get_children():
        if child is Control:
            Gs.utils.scale_gui_recursively(child)
    rect_size.x = $PanelContainer.rect_size.x
    _set_footer_visibility(!is_open)
    rect_position.x = \
            get_viewport().size.x - \
            rect_size.x - \
            PANEL_MARGIN_RIGHT * Gs.gui.scale
    rect_position.y = \
            0.0 if \
            is_open else \
            _get_closed_position_y()


func _initialize_annotator_checkboxes() -> void:
    var empty_style := StyleBoxEmpty.new()
    var annotators := \
            $PanelContainer/VBoxContainer/Sections/MarginContainer/Annotators
    for child in annotators.get_children():
        annotators.remove_child(child)
        child.queue_free()
    var item_width: float = \
            (annotators.rect_size.x - \
                annotators.get_constant("hseparation")) / \
            4.0
    for item_class in _annotator_control_item_classes:
        var item: LabeledControlItem = item_class.new()
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
        
        for label in Gs.utils.get_children_by_type(row, Label, true):
            label.add_font_override("font", Gs.gui.fonts.main_xs)
        
        if item.type == LabeledControlItem.CHECKBOX:
            item.set_check_box_scale(CHECK_BOX_SCALE)
        
        if item.type == LabeledControlItem.SLIDER:
            item.set_original_size(
                    Vector2(SLIDER_WIDTH, item.control.rect_size.y))
        
        annotators.add_child(row)
    
    for child in annotators.get_children():
        Gs.utils.scale_gui_recursively(child)


func _get_closed_position_y() -> float:
    return -$PanelContainer.rect_size.y - 1.0


func _set_is_open(value: bool) -> void:
    if is_open != value:
        _toggle_open()


func _get_is_open() -> bool:
    return is_open


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
    Gs.time.tween_property(
            self,
            "rect_position:y",
            position_y_start,
            position_y_end,
            duration,
            "ease_in")
    
    _set_footer_visibility(!is_open)
    
    if is_open:
        Surfacer.graph_inspector.select_first_item()
    else:
        Surfacer.graph_inspector.collapse()
    
    Gs.gui.active_overlays.erase(self)
    if is_open:
        Gs.gui.active_overlays.push_back(self)
    
    Gs.utils.release_focus()


func _set_footer_visibility(is_visible: bool) -> void:
    $Spacer.visible = is_visible
    $Footer.visible = is_visible
    rect_size.y = \
            $PanelContainer.rect_size.y + \
                    $Spacer.rect_size.y + \
                    $Footer.rect_size.y if \
            is_visible else \
            $PanelContainer.rect_size.y


func _on_GearButton_pressed() -> void:
    _toggle_open()


func _on_FooterPauseButton_pressed() -> void:
    Gs.level.pause()


func _on_HeaderXButton_pressed() -> void:
    Gs.utils.give_button_press_feedback()
    _toggle_open()


func _on_HeaderPauseButton_pressed() -> void:
    Gs.utils.give_button_press_feedback()
    Gs.level.pause()
