class_name LevelSelectItemUnlockedHeader
extends Button

const PADDING := Vector2(16.0, 8.0)

var level_id: String

func init_children() -> void:
    $HBoxContainer/Caret/TextureRect.rect_pivot_offset = \
            AccordionPanel.CARET_SIZE_DEFAULT / 2.0
    $HBoxContainer/Caret/TextureRect.rect_rotation = \
            AccordionPanel.CARET_ROTATION_CLOSED
    
    add_stylebox_override( \
            "normal", \
            Gs.utils.create_stylebox_flat(Gs.colors.dropdown_normal_color))
    add_stylebox_override( \
            "hover", \
            Gs.utils.create_stylebox_flat(Gs.colors.dropdown_hover_color))
    add_stylebox_override( \
            "pressed", \
            Gs.utils.create_stylebox_flat(Gs.colors.dropdown_pressed_color))
    
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
