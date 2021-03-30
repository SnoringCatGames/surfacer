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
    
    var faded_color: Color = Gs.colors.zebra_stripe_even_row_color
    faded_color.a *= 0.3
    
    $PanelContainer/LabeledControlList.even_row_color = faded_color
    $PanelContainer/LabeledControlList.items = controls_items
    
    update_gui_scale(1.0)

func update_gui_scale(gui_scale: float) -> bool:
    for child in get_children():
        Gs.utils._scale_gui_recursively(child, gui_scale)
        
    rect_min_size *= gui_scale
    rect_size.x = rect_min_size.x
    rect_position = (get_viewport().size - rect_size) / 2.0
    
    return true

func _exit_tree() -> void:
    Gs.remove_gui_to_scale(self)
