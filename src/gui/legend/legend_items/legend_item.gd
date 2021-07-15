class_name LegendItem
extends Control


const HEIGHT := 40.0
const MARGIN_VERTICAL := 1.0
const MARGIN_HORIZONTAL := 4.0
const LINE_SPACING := -3

const SHAPE_REGION_HEIGHT := HEIGHT - MARGIN_VERTICAL * 2.0
const SHAPE_REGION_WIDTH := SHAPE_REGION_HEIGHT
const SHAPE_REGION_CENTER := Vector2(
        MARGIN_HORIZONTAL + SHAPE_REGION_WIDTH / 2.0,
        MARGIN_VERTICAL + SHAPE_REGION_HEIGHT / 2.0)

var type := LegendItemType.UNKNOWN
var text: String
var label: ScaffolderLabel


func _init(
        type: int,
        text: String) -> void:
    self.type = type
    self.text = text


func _ready() -> void:
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    size_flags_vertical = Control.SIZE_EXPAND_FILL
    
    label = Sc.utils.add_scene(
            null, Sc.gui.SCAFFOLDER_LABEL_SCENE, false, true)
    label.align = Label.ALIGN_LEFT
    label.valign = Label.VALIGN_CENTER
    label.max_lines_visible = 2
    label.font_size = "Xs"
    label.add_constant_override("line_spacing", LINE_SPACING)
    label.text = text
    add_child(label)
    
    update()


func update() -> void:
    rect_min_size.y = HEIGHT * Sc.gui.scale
    
    label.margin_left = \
            (SHAPE_REGION_WIDTH + MARGIN_HORIZONTAL * 2.0) * Sc.gui.scale
    label.margin_top = MARGIN_VERTICAL * Sc.gui.scale
    label.rect_size.y = SHAPE_REGION_HEIGHT * Sc.gui.scale


func _draw() -> void:
    _draw_shape(
            SHAPE_REGION_CENTER * Sc.gui.scale,
            Vector2(SHAPE_REGION_WIDTH, SHAPE_REGION_HEIGHT) * Sc.gui.scale)


func _draw_shape(
        center: Vector2,
        size: Vector2) -> void:
    Sc.logger.error("Abstract LegendItem._draw_shape is not implemented")
