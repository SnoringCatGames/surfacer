extends Panel
class_name DebugPanel

const PANEL_WIDTH := 240.0
const PANEL_HEIGHT := 320.0
const OPEN_CLOSE_BUTTON_HEIGHT := 20.0
const SECTIONS_HEIGHT := PANEL_HEIGHT - OPEN_CLOSE_BUTTON_HEIGHT

const POSITION_Y_OPEN := 0.0
const POSITION_Y_CLOSED := -SECTIONS_HEIGHT
const TOGGLE_DURATION := 0.2
const TEXT_OPEN_PANEL := "Open debug menu"
const TEXT_CLOSE_PANEL := "Close debug menu"

var is_open := true

var _toggle_open_tween: Tween

var _position_y: float setget _set_position_y, _get_position_y

func _ready() -> void:
    _toggle_open_tween = Tween.new()
    add_child(_toggle_open_tween)

func add_section(section: Control) -> void:
    $VBoxContainer/Sections.add_child(section)

func _toggle_open() -> void:
    is_open = !is_open
    
    var position_y_start: float = _position_y
    var position_y_end: float
    var duration: float
    var text: String
    
    if is_open:
        position_y_end = POSITION_Y_OPEN
        duration = TOGGLE_DURATION
        text = TEXT_CLOSE_PANEL
    else:
        position_y_end = POSITION_Y_CLOSED
        duration = TOGGLE_DURATION
        text = TEXT_OPEN_PANEL
    
    # Start the sliding animation.
    _toggle_open_tween.reset_all()
    _toggle_open_tween.interpolate_property(self, "_position_y", \
            position_y_start, position_y_end, duration, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.0)
    _toggle_open_tween.start()
    
    $VBoxContainer/Panel/Button.text = text

func _set_position_y(value: float) -> void:
    rect_position.y = value

func _get_position_y() -> float:
    return rect_position.y
