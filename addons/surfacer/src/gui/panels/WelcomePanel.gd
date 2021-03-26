class_name WelcomePanel
extends VBoxContainer

var controls_items := [
    StaticTextLabeledControlItem.new("*Auto nav*", "click"),
    StaticTextLabeledControlItem.new("Inspect graph", "ctrl + click (x2)"),
    StaticTextLabeledControlItem.new("Walk/Climb", "arrow key / wasd"),
    StaticTextLabeledControlItem.new("Jump", "space / x"),
    StaticTextLabeledControlItem.new("Dash", "z"),
    StaticTextLabeledControlItem.new("Zoom in/out", "ctrl + =/-"),
    StaticTextLabeledControlItem.new("Pan", "ctrl + arrow key"),
]

const DEFAULT_GUI_SCALE := 1.0

func _ready() -> void:
    Gs.add_gui_to_scale(self, DEFAULT_GUI_SCALE)
    
    var faded_color: Color = Gs.key_value_even_row_color
    faded_color.a *= 0.3
    
    $PanelContainer/LabeledControlList.even_row_color = faded_color
    $PanelContainer/LabeledControlList.items = controls_items
    
    Gs.utils.connect( \
            "display_resized", \
            self, \
            "_on_resized")
    call_deferred("_on_resized")

func _on_resized() -> void:
    var viewport_size := get_viewport().size
    rect_position = (viewport_size - rect_size) / 2.0

func destroy() -> void:
    Gs.guis_to_scale.erase(self)
