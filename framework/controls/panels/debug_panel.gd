extends Panel
class_name DebugPanel

const PANEL_WIDTH := 240.0
const PANEL_HEIGHT := 328.0
const CREDITS_BUTTON_HEIGHT := 20.0
const PADDING_TOTAL_HEIGHT := 8.0
const SECTIONS_HEIGHT := \
        PANEL_HEIGHT - \
        CREDITS_BUTTON_HEIGHT - \
        PADDING_TOTAL_HEIGHT

const POSITION_Y_OPEN := 0.0
const POSITION_Y_CLOSED := -PANEL_HEIGHT
const TOGGLE_DURATION := 0.2

var is_open: bool = Global.UTILITY_PANEL_STARTS_OPEN

var _toggle_open_tween: Tween

var _position_y: float setget _set_position_y, _get_position_y

func _ready() -> void:
    # Set initial open state.
    self._position_y = \
            POSITION_Y_OPEN if \
            self.is_open else \
            POSITION_Y_CLOSED
    $VBoxContainer/Panel2/GearButton.visible = !is_open
    
    _toggle_open_tween = Tween.new()
    add_child(_toggle_open_tween)

func _on_credits_button_pressed():
    $CreditsPanel.popup()

func add_section(section: Control) -> void:
    $VBoxContainer/Sections.add_child(section)

func set_is_open(is_open: bool) -> void:
    if self.is_open != is_open:
        _toggle_open()

func _toggle_open() -> void:
    is_open = !is_open
    
    var position_y_start: float = _get_position_y()
    var position_y_end: float
    var duration: float
    var text: String
    
    if is_open:
        position_y_end = POSITION_Y_OPEN
        duration = TOGGLE_DURATION
    else:
        position_y_end = POSITION_Y_CLOSED
        duration = TOGGLE_DURATION
    
    # Start the sliding animation.
    _toggle_open_tween.reset_all()
    _toggle_open_tween.interpolate_property( \
            self, \
            "_position_y", \
            position_y_start, \
            position_y_end, \
            duration, \
            Tween.TRANS_LINEAR, \
            Tween.EASE_IN, \
            0.0)
    _toggle_open_tween.start()
    
    $VBoxContainer/Panel2/GearButton.visible = !is_open

func _set_position_y(value: float) -> void:
    rect_position.y = value

func _get_position_y() -> float:
    return rect_position.y
