tool
class_name LabeledControlList, "res://addons/scaffold/assets/images/editor_icons/LabeledControlList.png"
extends VBoxContainer

signal item_changed(item)

const ABOUT_ICON_NORMAL := \
        preload("res://addons/scaffold/assets/images/gui/about_icon_normal.png")
const ABOUT_ICON_HOVER := \
        preload("res://addons/scaffold/assets/images/gui/about_icon_hover.png")
const ABOUT_ICON_ACTIVE := \
        preload("res://addons/scaffold/assets/images/gui/about_icon_active.png")

const SCAFFOLD_CHECK_BOX_SCENE_PATH := \
        "res://addons/scaffold/src/gui/ScaffoldCheckBox.tscn"

const ENABLED_ALPHA := 1.0
const DISABLED_ALPHA := 0.3

# Array<LabeledControlItem>
var items := [] setget _set_items,_get_items
var even_row_color := Gs.key_value_even_row_color setget \
        _set_even_row_color,_get_even_row_color

export var font: Font setget _set_font,_get_font
export var row_height := 40.0 setget _set_row_height,_get_row_height
export var padding_horizontal := 8.0 setget \
        _set_padding_horizontal,_get_padding_horizontal

var _odd_row_style: StyleBoxEmpty
var _even_row_style: StyleBoxFlat

func _init() -> void:
    _odd_row_style = StyleBoxEmpty.new()
    
    _even_row_style = StyleBoxFlat.new()
    _even_row_style.bg_color = even_row_color

func _ready() -> void:
    _update_children()

func _update_children() -> void:
    for child in get_children():
        child.queue_free()
    
    for index in range(items.size()):
        var item: LabeledControlItem = items[index]
        
        var row := PanelContainer.new()
        var style: StyleBox = \
                _odd_row_style if \
                index % 2 == 0 else \
                _even_row_style
        row.add_stylebox_override("panel", style)
        add_child(row)
        
        var hbox := HBoxContainer.new()
        hbox.rect_min_size.y = row_height
        hbox.add_constant_override("separation", 0)
        row.add_child(hbox)
        
        var spacer1 := Control.new()
        spacer1.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        spacer1.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        spacer1.rect_min_size.x = padding_horizontal
        hbox.add_child(spacer1)
        
        var label := Label.new()
        label.text = item.label
        label.modulate.a = \
                ENABLED_ALPHA if \
                item.enabled else \
                DISABLED_ALPHA
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        hbox.add_child(label)
        
        if item.description != "":
            var description_button = TextureButton.new()
            description_button.texture_normal = ABOUT_ICON_NORMAL
            description_button.texture_hover = ABOUT_ICON_HOVER
            description_button.texture_pressed = ABOUT_ICON_ACTIVE
            description_button.connect( \
                    "pressed", \
                    self, \
                    "_on_description_button_pressed", \
                    [
                        item.label,
                        item.description
                    ])
            description_button.size_flags_horizontal = \
                    Control.SIZE_SHRINK_CENTER
            description_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
            hbox.add_child(description_button)
            
            var spacer3 := Control.new()
            spacer3.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
            spacer3.size_flags_vertical = Control.SIZE_SHRINK_CENTER
            spacer3.rect_min_size.x = padding_horizontal * 2.0
            hbox.add_child(spacer3)
        
        var control := _create_control(item, index, !item.enabled)
        control.size_flags_horizontal = Control.SIZE_SHRINK_END
        control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        hbox.add_child(control)
        
        var spacer2 := Control.new()
        spacer2.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        spacer2.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        spacer2.rect_min_size.x = padding_horizontal
        hbox.add_child(spacer2)
    
    Gs.utils.set_mouse_filter_recursively( \
            self, \
            Control.MOUSE_FILTER_PASS)
    
    if font != null:
        _set_font_recursively(font, self)

func _create_control( \
        item: LabeledControlItem, \
        index: int, \
        disabled: bool) -> Control:
    var alpha := \
            DISABLED_ALPHA if \
            disabled else \
            ENABLED_ALPHA
    match item.type:
        LabeledControlItem.TEXT:
            var label := Label.new()
            label.text = item.text
            label.modulate.a = alpha
            item.control = label
            return label
        LabeledControlItem.CHECKBOX:
            var checkbox: ScaffoldCheckBox = Gs.utils.add_scene( \
                    null, \
                    SCAFFOLD_CHECK_BOX_SCENE_PATH, \
                    false, \
                    true)
            checkbox.pressed = item.pressed
            checkbox.disabled = disabled
            checkbox.modulate.a = alpha
            checkbox.size_flags_horizontal = 0
            checkbox.size_flags_vertical = 0
            checkbox.rect_min_size.x = \
                    Gs.default_checkbox_icon_size * Gs.gui_scale
            checkbox.connect( \
                    "pressed", \
                    self, \
                    "_on_control_pressed", \
                    [index])
            checkbox.connect( \
                    "pressed", \
                    self, \
                    "_on_checkbox_pressed", \
                    [index])
#            var checkbox_inner: CheckBox = checkbox.get_node("CheckBox")
#            checkbox_inner.
            item.control = checkbox
            return checkbox
        LabeledControlItem.DROPDOWN:
            var dropdown := OptionButton.new()
            for option in item.options:
                dropdown.add_item(option)
            dropdown.select(item.selected_index)
            dropdown.disabled = disabled
            dropdown.connect( \
                    "pressed", \
                    self, \
                    "_on_control_pressed", \
                    [index])
            dropdown.connect( \
                    "item_selected", \
                    self, \
                    "_on_dropdown_item_selected", \
                    [index])
            item.control = dropdown
            return dropdown
        _:
            Gs.utils.error()
            return null

func _on_control_pressed(_index: int) -> void:
    Gs.utils.give_button_press_feedback()

func _on_checkbox_pressed(checkbox_index: int) -> void:
    var item: CheckboxLabeledControlItem = items[checkbox_index]
    item.pressed = !item.pressed
    item.on_pressed(item.pressed)
    emit_signal("item_changed", item)

func _on_dropdown_item_selected( \
        _option_index: int, \
        dropdown_index: int) -> void:
    Gs.utils.give_button_press_feedback()
    var item: DropdownLabeledControlItem = items[dropdown_index]
    item.selected_index = item.control.selected
    item.on_selected( \
            item.selected_index, \
            item.options[item.selected_index])
    emit_signal("item_changed", item)

func _on_description_button_pressed( \
        label: String, \
        description: String) -> void:
    Gs.utils.give_button_press_feedback()
    Gs.nav.open( \
            "notification", \
            false, \
            {
                header_text = label,
                is_back_button_shown = true,
                body_text = description,
                close_button_text = "OK",
                body_alignment = ALIGN_BEGIN,
            })

func find_index(label: String) -> int:
    for index in range(items.size()):
        if items[index].label == label:
            return index
    Gs.utils.error()
    return -1

func find_item(label: String) -> Dictionary:
    return items[find_index(label)]

func _update_item(item: LabeledControlItem) -> void:
    item.enabled = item.get_is_enabled()
    
    match item.type:
        LabeledControlItem.TEXT:
            item.text = item.get_text()
        LabeledControlItem.CHECKBOX:
            item.pressed = item.get_is_pressed()
        LabeledControlItem.DROPDOWN:
            item.selected_index = item.get_selected_index()
        _:
            Gs.utils.error()

func _set_items(value: Array) -> void:
    items = value
    for item in items:
        _update_item(item)
    _update_children()

func _get_items() -> Array:
    return items

func _set_row_height(value: float) -> void:
    row_height = value
    _update_children()

func _get_row_height() -> float:
    return row_height

func _set_padding_horizontal(value: float) -> void:
    padding_horizontal = value
    _update_children()

func _get_padding_horizontal() -> float:
    return padding_horizontal

func _set_even_row_color(value: Color) -> void:
    even_row_color = value
    _even_row_style.bg_color = even_row_color

func _get_even_row_color() -> Color:
    return even_row_color

func _set_font(value: Font) -> void:
    var old_font := font
    if old_font != value:
        font = value
        if font != null:
            _set_font_recursively(font, self)

func _get_font() -> Font:
    return font

static func _set_font_recursively( \
        font: Font, \
        control: Node) -> void:
    if !(control is Control):
        return
    
    if control is Label or \
            control is CheckBox or \
            control is OptionButton:
        control.add_font_override("font", font)
    
    for child in control.get_children():
        _set_font_recursively(font, child)
