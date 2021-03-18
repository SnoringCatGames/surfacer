tool
extends Control
class_name AccordionPanel

signal toggled
signal caret_rotated

const CARET_LEFT_NORMAL: Texture = \
        preload("res://addons/scaffold/assets/images/gui/left_caret_normal.png")

const CARET_SIZE_DEFAULT := Vector2(23.0, 32.0)
const CARET_SCALE := Vector2(0.5, 0.5)
const CARET_ROTATION_CLOSED := 270.0
const CARET_ROTATION_OPEN := 90.0

const HEIGHT_TWEEN_DURATION_SEC := 0.2
const CARET_ROTATION_TWEEN_DURATION_SEC := 0.2
const SCROLL_TWEEN_DURATION_SEC := 0.3

export var is_open := false setget _set_is_open,_get_is_open
export var includes_header := true setget \
        _set_includes_header,_get_includes_header
export var header_text := "" setget _set_header_text,_get_header_text
export var header_min_height := 0.0 setget \
        _set_header_min_height,_get_header_min_height
export var header_font: Font setget _set_header_font,_get_header_font
export var is_caret_on_left := true setget \
        _set_is_caret_on_left,_get_is_caret_on_left
export var padding := Vector2(8.0, 4.0) setget _set_padding,_get_padding
export var extra_scroll_height_for_custom_header := 0.0 setget \
        _set_extra_scroll_height_for_custom_header, \
        _get_extra_scroll_height_for_custom_header

var height_override := INF

var configuration_warning := ""

var _is_ready := false
var _scroll_container: ScrollContainer
var _header: Button
var _header_hbox: HBoxContainer
var _projected_control: Control
var _caret: TextureRect
var _is_open_tween: Tween

var _start_scroll_vertical: int

func _enter_tree() -> void:
    _is_open_tween = Tween.new()
    _is_open_tween.connect( \
            "tween_all_completed", \
            self, \
            "_on_is_open_tween_completed")
    add_child(_is_open_tween)

func _ready() -> void:
    _is_ready = true
    rect_clip_content = true
    
    move_child(_is_open_tween, 0)
    
    _update_children()
    call_deferred("_update_children")

func add_child(child: Node, legible_unique_name=false) -> void:
    .add_child(child, legible_unique_name)
    _update_children()

func remove_child(child: Node) -> void:
    .remove_child(child)
    if child != _header:
        _update_children()

func _create_header() -> void:
    # TODO: For some reason, when running in-editor, there can be extra
    #       children created?
    if is_instance_valid(_header):
        _header.queue_free()
    
    _header = Button.new()
    _header.connect("pressed", self, "_on_header_pressed")
    
    var header_style_normal := StyleBoxFlat.new()
    header_style_normal.bg_color = ScaffoldConfig.option_button_normal_color
    _header.add_stylebox_override("normal", header_style_normal)
    
    var header_style_hover := StyleBoxFlat.new()
    header_style_hover.bg_color = ScaffoldConfig.option_button_hover_color
    _header.add_stylebox_override("hover", header_style_hover)
    
    var header_style_pressed := StyleBoxFlat.new()
    header_style_pressed.bg_color = ScaffoldConfig.option_button_pressed_color
    _header.add_stylebox_override("pressed", header_style_pressed)
    
    _header_hbox = HBoxContainer.new()
    _header_hbox.add_constant_override("separation", padding.x)
    _header.add_child(_header_hbox)
    
    var spacer1 := Control.new()
    spacer1.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    spacer1.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    
    var caret_wrapper := Control.new()
    caret_wrapper.rect_min_size = CARET_SIZE_DEFAULT * CARET_SCALE
    caret_wrapper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    caret_wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    
    _caret = TextureRect.new()
    _caret.texture = CARET_LEFT_NORMAL
    _caret.rect_pivot_offset = CARET_SIZE_DEFAULT / 2.0
    _caret.rect_scale = CARET_SCALE
    _caret.rect_rotation = CARET_ROTATION_CLOSED
    _caret.rect_position = -CARET_SIZE_DEFAULT * CARET_SCALE / 2.0
    caret_wrapper.add_child(_caret)
    
    var label := Label.new()
    label.text = header_text
    label.align = Label.ALIGN_LEFT
    label.valign = Label.VALIGN_CENTER
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    
    var spacer2 := Control.new()
    spacer2.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    spacer2.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    
    _header_hbox.add_child(spacer1)
    if is_caret_on_left:
        _header_hbox.add_child(caret_wrapper)
        _header_hbox.add_child(label)
    else:
        _header_hbox.add_child(label)
        _header_hbox.add_child(caret_wrapper)
    _header_hbox.add_child(spacer2)
    
    var texture_height := CARET_SIZE_DEFAULT.y * CARET_SCALE.y
    var label_height := label.rect_size.y
    var header_height := max( \
            header_min_height, \
            max( \
                    label_height, \
                    texture_height)) + \
            padding.y * 2.0
    _header.rect_size = Vector2(rect_size.x, header_height)
    _header_hbox.rect_size = _header.rect_size
    
    add_child(_header)

func _update_children() -> void:
    if !_is_ready:
        return
    
    if includes_header and \
            !is_instance_valid(_header):
        _create_header()
    elif !includes_header and \
            is_instance_valid(_header):
        _header.queue_free()
        _header = null
    
    var expected_child_count := 3 if includes_header else 2
    var children := get_children()
    if children.size() != expected_child_count:
        configuration_warning = \
                "Must define a child node." if \
                children.size() < expected_child_count else \
                "Must define only one child node."
        update_configuration_warning()
        return
    
    if includes_header:
        move_child(_header, 2)
        _header.rect_size.x = rect_size.x
        _header.rect_position.y = 0.0
        _header_hbox.rect_size.x = rect_size.x
    
    var projected_node: Node = children[1]
    if !(projected_node is Control):
        configuration_warning = "Child node must be of type 'Control'."
        update_configuration_warning()
        return
    
    _projected_control = projected_node
    _projected_control.rect_size.x = rect_size.x
    _projected_control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    
    configuration_warning = ""
    update_configuration_warning()
    
    call_deferred("_trigger_open_change", false)

func _trigger_open_change(is_tweening: bool) -> void:
    _is_open_tween.stop_all()
    
    if is_tweening:
        _on_is_open_tween_started()
        
        var height_ratio_start: float
        var height_ratio_end: float
        var caret_rotation_start: float
        var caret_rotation_end: float
        if is_open:
            height_ratio_start = 0.0
            height_ratio_end = 1.0
            caret_rotation_start = CARET_ROTATION_CLOSED
            caret_rotation_end = CARET_ROTATION_OPEN
        else:
            height_ratio_start = 1.0
            height_ratio_end = 0.0
            caret_rotation_start = CARET_ROTATION_OPEN
            caret_rotation_end = CARET_ROTATION_CLOSED
        
        _is_open_tween.interpolate_method( \
                self, \
                "_interpolate_height", \
                height_ratio_start, \
                height_ratio_end, \
                HEIGHT_TWEEN_DURATION_SEC, \
                Tween.TRANS_QUAD, \
                Tween.EASE_IN_OUT)
        _is_open_tween.interpolate_method( \
                self, \
                "_interpolate_caret_rotation", \
                caret_rotation_start, \
                caret_rotation_end, \
                CARET_ROTATION_TWEEN_DURATION_SEC, \
                Tween.TRANS_QUAD, \
                Tween.EASE_IN_OUT)
        if is_open:
            var scroll_container: ScrollContainer = \
                    Nav.get_active_screen().scroll_container
            _start_scroll_vertical = scroll_container.scroll_vertical
            _is_open_tween.interpolate_method( \
                    self, \
                    "_interpolate_scroll", \
                    0.0, \
                    1.0, \
                    SCROLL_TWEEN_DURATION_SEC, \
                    Tween.TRANS_QUAD, \
                    Tween.EASE_IN_OUT)
        _is_open_tween.start()
    else:
        _on_is_open_tween_completed()

func _interpolate_height(open_ratio: float) -> void:
    # NOTE: For some reason, this assignment is needed in order to preserve the
    #       original height of the project content. Otherwise, us changing its
    #       position here seems to cause it's size to change as well.
    var projected_height := \
            height_override if \
            height_override != INF else \
            _projected_control.rect_size.y
    _projected_control.rect_size.y = projected_height
    
    rect_min_size.y = projected_height * open_ratio
    _projected_control.rect_position.y = -projected_height * (1.0 - open_ratio)
    if includes_header:
        rect_min_size.y += _header.rect_size.y
        _header_hbox.rect_size.y = _header.rect_size.y
        _projected_control.rect_position.y += _header.rect_size.y

func _interpolate_caret_rotation(rotation: float) -> void:
    if is_instance_valid(_caret):
        _caret.rect_rotation = rotation
    emit_signal("caret_rotated", rotation)

# Auto-scroll if opened past bottom of screen, but don't auto-scroll the header
# off the top of the screen!
func _interpolate_scroll(open_ratio: float) -> void:
    var scroll_container: ScrollContainer = \
            Nav.get_active_screen().scroll_container
    if scroll_container == null:
        return
    
    var accordion_position_y_in_scroll_container: int = \
            ScaffoldUtils.get_node_vscroll_position(scroll_container, self)
    var accordion_height := _projected_control.rect_size.y
    if includes_header:
        accordion_height += _header.rect_size.y
    
    var min_scroll_vertical_to_show_accordion_bottom := \
            accordion_position_y_in_scroll_container + \
            accordion_height - \
            scroll_container.rect_size.y
    var max_scroll_vertical_to_show_accordion_top := \
            accordion_position_y_in_scroll_container - \
            extra_scroll_height_for_custom_header
    
    var is_scrolling_upward := \
            scroll_container.scroll_vertical > \
            max_scroll_vertical_to_show_accordion_top
    
    var end_scroll_vertical: float
    end_scroll_vertical = max_scroll_vertical_to_show_accordion_top
    # TODO: Remove?
#    if is_scrolling_upward:
#        end_scroll_vertical = max_scroll_vertical_to_show_accordion_top
#    else:
#        end_scroll_vertical = min( \
#                min_scroll_vertical_to_show_accordion_bottom, \
#                max_scroll_vertical_to_show_accordion_top)
    
    scroll_container.scroll_vertical = lerp( \
            _start_scroll_vertical, \
            end_scroll_vertical, \
            open_ratio)

func _on_is_open_tween_started() -> void:
    _projected_control.visible = true

func _on_is_open_tween_completed( \
        _object = null, \
        _key = null) -> void:
    var open_ratio := 1.0 if is_open else 0.0
    _interpolate_height(open_ratio)
    _projected_control.visible = is_open

func _get_configuration_warning() -> String:
    return configuration_warning

func _on_header_pressed() -> void:
    ScaffoldUtils.give_button_press_feedback()
    toggle()

func toggle() -> void:
    is_open = !is_open
    _trigger_open_change(true)
    emit_signal("toggled")

func _set_is_open(value: bool) -> void:
    if value == is_open:
        return
    
    is_open = value
    if _is_ready:
        _trigger_open_change(false)

func _get_is_open() -> bool:
    return is_open

func _set_includes_header(value: bool) -> void:
    includes_header = value
    if _is_ready:
        _update_children()

func _get_includes_header() -> bool:
    return includes_header

func _set_header_text(value: String) -> void:
    header_text = value
    if _is_ready and includes_header:
        _header.text = value

func _get_header_text() -> String:
    return header_text

func _set_header_min_height(value: float) -> void:
    header_min_height = value
    if _is_ready:
        _update_children()

func _get_header_min_height() -> float:
    return header_min_height

func _set_header_font(value: Font) -> void:
    header_font = value
    if _is_ready:
        _update_children()

func _get_header_font() -> Font:
    return header_font

func _set_is_caret_on_left(value: bool) -> void:
    is_caret_on_left = value
    if _is_ready:
        _update_children()

func _get_is_caret_on_left() -> bool:
    return is_caret_on_left

func _set_padding(value: Vector2) -> void:
    padding = value
    if _is_ready:
        _update_children()

func _get_padding() -> Vector2:
    return padding

func _set_extra_scroll_height_for_custom_header(value: float) -> void:
    extra_scroll_height_for_custom_header = value
    if _is_ready:
        _update_children()

func _get_extra_scroll_height_for_custom_header() -> float:
    return extra_scroll_height_for_custom_header

func update() -> void:
    _update_children()
