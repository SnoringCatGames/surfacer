tool
class_name SurfacesTileMap, \
"res://addons/surfacer/assets/images/editor_icons/surfaces_tile_map.png"
extends TileMap
## The surfaces that a character can collide with.


signal cell_tile_changed(
        cell_position,
        next_tile_id,
        previous_tile_id)
signal cell_autotile_changed(
        cell_position,
        next_autotile_position,
        previous_autotile_position,
        tile_id)

const GROUP_NAME_SURFACES := "surfaces"

export var id: String
## This can be useful for debugging.
export var draws_tile_indices := false setget _set_draws_tile_indices


func _ready() -> void:
    add_to_group(GROUP_NAME_SURFACES, true)
    
    if !is_instance_valid(tile_set) or \
            tile_set.resource_path == Su.PLACEHOLDER_SURFACES_TILE_SET_PATH:
        tile_set = Su.default_tile_set
        property_list_changed_notify()


func _enter_tree() -> void:
    cell_size = Sc.level_session.config.cell_size
    position = Vector2.ZERO
    property_list_changed_notify()


func _draw() -> void:
    if draws_tile_indices:
        Sc.draw.draw_tile_map_indices(
                self,
                self,
                Color.white,
                false)


func _set_draws_tile_indices(value: bool) -> void:
    draws_tile_indices = value
    update()


func set_cell(
        x: int,
        y: int,
        tile_id: int,
        flip_x := false,
        flip_y := false,
        transpose := false,
        autotile_coord := Vector2.ZERO) -> void:
    var previous_tile_id := get_cell(x, y)
    var is_autotile := \
            tile_id != INVALID_CELL and \
            tile_set.tile_get_tile_mode(tile_id) == TileSet.AUTO_TILE
    var previous_autotile_coord := \
            get_cell_autotile_coord(x, y) if \
            is_autotile else \
            Vector2.INF
    .set_cell(x, y, tile_id, flip_x, flip_y, transpose, autotile_coord)
    if previous_tile_id != tile_id:
        emit_signal(
                "cell_tile_changed",
                Vector2(x, y),
                tile_id,
                previous_tile_id)
    else:
        if is_autotile and \
                previous_autotile_coord != autotile_coord:
            emit_signal(
                    "cell_autotile_changed",
                    Vector2(x, y),
                    autotile_coord,
                    previous_autotile_coord,
                    tile_id)


# FIXME: --------------------------------
# - Make sure this doesn't trigger set_cell() under the hood, which would cause
#   our signal to emit twice.
func set_cellv(
        position: Vector2,
        tile_id: int,
        flip_x := false,
        flip_y := false,
        transpose := false) -> void:
    var previous_tile_id := get_cellv(position)
    .set_cellv(position, tile_id, flip_x, flip_y, transpose)
    if previous_tile_id != tile_id:
        emit_signal(
                "cell_tile_changed",
                position,
                tile_id,
                previous_tile_id)
