extends Panel
class_name WelcomePanel

const CONTROLS_LEGEND = [
  ["Walk/Climb", "arrow key"], \
  ["Jump", "space / x"], \
  ["Dash", "z"], \
  ["Zoom in", "ctrl + ="], \
  ["Zoom out", "ctrl + -"], \
  ["Pan", "ctrl + arrow key"], \
  ["Auto nav", "click"], \
  ["Debug graph", "ctrl + click (x2)"], \
]

func _ready() -> void:
    for mapping in CONTROLS_LEGEND:
        $Controls.add_item(mapping[0] + "   ", null, false)
        $Controls.add_item(mapping[1], null, false)
