extends Control
class_name LegendItem

const HEIGHT := 32.0
const MARGIN_VERTICAL := 1.0
const MARGIN_HORIZONTAL := 4.0

const SHAPE_REGION_HEIGHT := HEIGHT - MARGIN_VERTICAL * 2.0
const SHAPE_REGION_WIDTH := SHAPE_REGION_HEIGHT
const SHAPE_REGION_CENTER := Vector2( \
        MARGIN_HORIZONTAL + SHAPE_REGION_WIDTH / 2.0, \
        MARGIN_VERTICAL + SHAPE_REGION_HEIGHT / 2.0)

var type := LegendItemType.UNKNOWN
var text: String
var label: Label

func _init( \
        type: int, \
        text: String) -> void:
    self.type = type
    self.text = text

func _enter_tree() -> void:
    rect_min_size.y = HEIGHT
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    size_flags_vertical = Control.SIZE_EXPAND_FILL
    
    label = Label.new()
    label.margin_left = SHAPE_REGION_WIDTH + MARGIN_HORIZONTAL * 2.0
    label.margin_top = MARGIN_VERTICAL
    label.rect_size.y = SHAPE_REGION_HEIGHT
    label.valign = Label.VALIGN_CENTER
    label.max_lines_visible = 2
    label.add_font_override("font", ScaffoldConfig.main_font_xs)
    label.text = text
    add_child(label)

func _draw() -> void:
    _draw_shape( \
            SHAPE_REGION_CENTER, \
            Vector2(SHAPE_REGION_WIDTH, SHAPE_REGION_HEIGHT))

func _draw_shape( \
        center: Vector2, \
        size: Vector2) -> void:
    ScaffoldUtils.error("Abstract LegendItem._draw_shape is not implemented")
