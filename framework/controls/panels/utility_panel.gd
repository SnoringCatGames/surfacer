extends Panel
class_name UtilityPanel

const PANEL_WIDTH := 240.0
const PANEL_HEIGHT := 400.0
const PANEL_MARGIN_RIGHT := 20.0

const FOOTER_HEIGHT := 20.0
const FOOTER_PADDING_TOTAL_HEIGHT := 8.0
const SECTIONS_HEIGHT := \
        PANEL_HEIGHT - \
        FOOTER_HEIGHT - \
        FOOTER_PADDING_TOTAL_HEIGHT

const POSITION_Y_OPEN := 0.0
const POSITION_Y_CLOSED := -PANEL_HEIGHT
const TOGGLE_DURATION := 0.2

var is_open: bool = Global.UTILITY_PANEL_STARTS_OPEN

var _toggle_open_tween: Tween

var _position_y: float setget _set_position_y, _get_position_y

func _ready() -> void:
    _initialize_dimensions()
    
    # Set initial open state.
    self._position_y = \
            POSITION_Y_OPEN if \
            self.is_open else \
            POSITION_Y_CLOSED
    $VBoxContainer/GearContainer/GearButton.visible = !is_open
    
    _toggle_open_tween = Tween.new()
    add_child(_toggle_open_tween)
    
    var global = $"/root/Global"
    global.platform_graph_inspector = \
            $VBoxContainer/Sections/InspectorContainer/PlatformGraphInspector

func _initialize_dimensions() -> void:
    self.anchor_left = 1.0
    self.anchor_top = 0.0
    self.anchor_right = 1.0
    self.anchor_bottom = 0.0
    self.rect_size.x = PANEL_WIDTH
    self.rect_size.y = PANEL_HEIGHT
    self.rect_min_size.x = PANEL_WIDTH
    self.rect_min_size.y = PANEL_HEIGHT
    self.margin_left = -PANEL_MARGIN_RIGHT - PANEL_WIDTH
    self.margin_right = -PANEL_MARGIN_RIGHT
    self.margin_bottom = PANEL_HEIGHT
    
    $VBoxContainer/Sections.rect_size.y = SECTIONS_HEIGHT
    $VBoxContainer/Sections.rect_min_size.y = SECTIONS_HEIGHT
    
    $VBoxContainer/Footer.rect_size.y = FOOTER_HEIGHT
    $VBoxContainer/Footer.rect_min_size.y = FOOTER_HEIGHT

func _on_credits_button_pressed():
    $CreditsPanel.popup()

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
    
    $VBoxContainer/GearContainer/GearButton.visible = !is_open

func _set_position_y(value: float) -> void:
    rect_position.y = value

func _get_position_y() -> float:
    return rect_position.y
