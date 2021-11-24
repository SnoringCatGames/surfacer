tool
class_name SurfaceMark, \
"res://addons/surfacer/assets/images/editor_icons/surfaces_tile_map.png"
extends TileMap
## For marking surfaces in the level editor.[br]
## [br]
## -   This is used for painting over surfaces in the level editor.[br]
## -   A surface is matched if it intersects with a cell that is painted by
##     this SurfaceMark.[br]
## -   In order to help distinguish between adjacent surfaces along different
##     sides of a cell, this node will auto-assign a smaller cell-size and a
##     slight position offset.[br]


const GROUP_NAME_SURFACE_MARKS := "surface_marks"

var _MODULATE_INCLUDE := Color.from_hsv(0.35, 1.0, 1.0, 0.7)
var _MODULATE_EXCLUDE := Color.from_hsv(0.0, 1.0, 1.0, 0.7)

## The characters that this applies to.
var characters: int

## If true, then only marked surfaces are included.
var include_exclusively := true setget _set_include_exclusively

## If true, then all surfaces are included unless they are marked.
var exclude := false setget _set_exclude

var should_be_removed := false

# Dictionary<Surface, bool>
var _marked_surfaces := {}

var _property_list_addendum := []


func _init() -> void:
    add_to_group(GROUP_NAME_SURFACE_MARKS, true)
    
    _property_list_addendum = [
        {
            name = "characters",
            type = TYPE_INT,
            hint = PROPERTY_HINT_FLAGS,
            hint_string = Sc.utils.join(Sc.characters.character_scenes.keys()),
            usage = Sc.utils.PROPERTY_USAGE_EXPORTED_ITEM,
        },
        {
            name = "include_exclusively",
            type = TYPE_BOOL,
            usage = Sc.utils.PROPERTY_USAGE_EXPORTED_ITEM,
        },
        {
            name = "exclude",
            type = TYPE_BOOL,
            usage = Sc.utils.PROPERTY_USAGE_EXPORTED_ITEM,
        },
    ]
    
    self.should_be_removed = \
            !Engine.editor_hint and \
            !Su.is_precomputing_platform_graphs and \
            !Su.are_loaded_surfaces_deeply_validated
    if should_be_removed:
        clear()
        queue_free()


func _enter_tree() -> void:
    cell_size = Sc.level_session.config.cell_size / 2.0
    position = -cell_size / 2.0
    collision_layer = 0
    collision_mask = 0
    light_mask = 0
    modulate = \
            _MODULATE_INCLUDE if \
            include_exclusively else \
            _MODULATE_EXCLUDE
    property_list_changed_notify()


# NOTE: _get_property_list **appends** to the default list of properties.
#       It does not replace.
func _get_property_list() -> Array:
    return _property_list_addendum


func add_surface(surface: Surface) -> void:
    _marked_surfaces[surface] = true


func get_is_surface_marked(surface: Surface) -> bool:
    return _marked_surfaces.has(surface)


func get_character_names() -> Array:
    var all_character_names := Sc.characters.character_scenes.keys()
    var result := []
    for i in all_character_names.size():
        var bitmask: int = 1 << i
        if bitmask & characters != 0:
            result.push_back(all_character_names[i])
    return result


func set_character_names(names: Array) -> void:
    var all_character_names := Sc.characters.character_scenes.keys()
    var character_name_to_index := {}
    for i in all_character_names.size():
        character_name_to_index[all_character_names[i]] = i
    characters = 0
    for character_name in names:
        characters |= 1 << character_name_to_index[character_name]


func _set_include_exclusively(value: bool) -> void:
    include_exclusively = value
    exclude = !include_exclusively
    modulate = \
            _MODULATE_INCLUDE if \
            include_exclusively else \
            _MODULATE_EXCLUDE
    property_list_changed_notify()


func _set_exclude(value: bool) -> void:
    exclude = value
    include_exclusively = !exclude
    modulate = \
            _MODULATE_INCLUDE if \
            include_exclusively else \
            _MODULATE_EXCLUDE
    property_list_changed_notify()


func load_from_json_object(
        json_object: Dictionary,
        context: Dictionary) -> void:
    for id in json_object.s:
        var surface: Surface = context.id_to_surface[int(id)]
        _marked_surfaces[surface] = true
    characters = json_object.c
    include_exclusively = json_object.i
    exclude = json_object.e


func to_json_object() -> Dictionary:
    var marked_surface_ids := _marked_surfaces.keys()
    for i in marked_surface_ids.size():
        marked_surface_ids[i] = marked_surface_ids[i].get_instance_id()
    
    return {
        s = marked_surface_ids,
        c = characters,
        i = include_exclusively,
        e = exclude,
    }
