class_name LevelSelectItemUnlockedHeader
extends Button

const PADDING := Vector2(16.0, 8.0)

var level_id: String

var normal_stylebox: StyleBoxFlatScalable
var hover_stylebox: StyleBoxFlatScalable
var pressed_stylebox: StyleBoxFlatScalable

func _exit_tree() -> void:
    if is_instance_valid(normal_stylebox):
        normal_stylebox.destroy()
    if is_instance_valid(hover_stylebox):
        hover_stylebox.destroy()
    if is_instance_valid(pressed_stylebox):
        pressed_stylebox.destroy()

func init_children() -> void:
    $HBoxContainer/Caret/TextureRect.rect_pivot_offset = \
            AccordionPanel.CARET_SIZE_DEFAULT / 2.0
    $HBoxContainer/Caret/TextureRect.rect_rotation = \
            AccordionPanel.CARET_ROTATION_CLOSED
    
    normal_stylebox = Gs.utils.create_stylebox_flat_scalable({
        bg_color = Gs.colors.dropdown_normal_color,
        corner_radius = Gs.styles.dropdown_corner_radius,
        corner_detail = Gs.styles.dropdown_corner_detail,
    })
    hover_stylebox = Gs.utils.create_stylebox_flat_scalable({
        bg_color = Gs.colors.dropdown_hover_color,
        corner_radius = Gs.styles.dropdown_corner_radius,
        corner_detail = Gs.styles.dropdown_corner_detail,
    })
    pressed_stylebox = Gs.utils.create_stylebox_flat_scalable({
        bg_color = Gs.colors.dropdown_pressed_color,
        corner_radius = Gs.styles.dropdown_corner_radius,
        corner_detail = Gs.styles.dropdown_corner_detail,
    })
    
    add_stylebox_override("normal", normal_stylebox)
    add_stylebox_override("hover", hover_stylebox)
    add_stylebox_override("pressed", pressed_stylebox)
    
    Gs.utils.set_mouse_filter_recursively( \
            self, \
            Control.MOUSE_FILTER_IGNORE)

func update_size(header_size: Vector2) -> void:
    rect_min_size = header_size
    
    $HBoxContainer.add_constant_override( \
            "separation", \
            PADDING.x * Gs.gui_scale)
    $HBoxContainer.rect_min_size = header_size
    $HBoxContainer.rect_size = header_size
    
    $HBoxContainer/Caret.texture_scale = \
            AccordionPanel.CARET_SCALE * Gs.gui_scale
    
    rect_size = header_size

func update_is_unlocked(is_unlocked: bool) -> void:
    visible = is_unlocked
    
    var config: Dictionary = \
            Gs.level_config.get_level_config(level_id)
    $HBoxContainer/LevelNumber.text = str(config.number) + "."
    $HBoxContainer/LevelName.text = config.name

func update_caret_rotation(rotation: float) -> void:
    $HBoxContainer/Caret/TextureRect.rect_rotation = rotation
