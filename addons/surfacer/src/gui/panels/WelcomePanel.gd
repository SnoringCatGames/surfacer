extends PanelContainer
class_name WelcomePanel

const CONTROLS_LEGEND = [
  ["*Auto nav*", "click"], \
  ["Inspect graph", "ctrl + click (x2)"], \
  ["Walk/Climb", "arrow key / wasd"], \
  ["Jump", "space / x"], \
  ["Dash", "z"], \
  ["Zoom in/out", "ctrl + =/-"], \
  ["Pan", "ctrl + arrow key"], \
]

const DEFAULT_GUI_SCALE := 1.0

func _ready() -> void:
    Gs.add_gui_to_scale(self, DEFAULT_GUI_SCALE)
    
    for mapping in CONTROLS_LEGEND:
        if !Surfacer.is_inspector_enabled and \
                mapping[0] == "Inspect graph":
            continue
        
        $VBoxContainer/MarginContainer/Controls.add_item( \
                mapping[0] + "   ", \
                null, \
                false)
        $VBoxContainer/MarginContainer/Controls.add_item( \
                mapping[1], \
                null, \
                false)
