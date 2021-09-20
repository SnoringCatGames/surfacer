class_name SurfaceStore
extends Reference


# TODO: Map the TileMap into an RTree or QuadTree.

const SURFACES_TILE_MAPS_COLLISION_LAYER := 1

const _CORNER_TARGET_LESS_PREFERRED_SURFACE_SIDE_OFFSET := 0.02
const _CORNER_TARGET_MORE_PREFERRED_SURFACE_SIDE_OFFSET := 0.01

# TODO: We might want to instead replace this with a ratio (like 1.1) of the
#       KinematicBody2D.get_safe_margin value (defaults to 0.08, but we set it
#       higher during graph calculations).
const _COLLISION_BETWEEN_CELLS_DISTANCE_THRESHOLD := 0.5

# Collections of surfaces.
# Array<Surface>
var floors := []
var ceilings := []
var left_walls := []
var right_walls := []

var all_surfaces := []
var non_ceiling_surfaces := []
var non_floor_surfaces := []
var non_wall_surfaces := []
var all_walls := []

var max_tile_map_cell_size: Vector2
var combined_tile_map_rect: Rect2

# This supports mapping a cell in a TileMap to its corresponding surface.
# Dictionary<SurfacesTileMap, Dictionary<String, Dictionary<int, Surface>>>
var _tile_map_index_to_surface_maps := {}

var _collision_surface_result := CollisionSurfaceResult.new()


# Gets the surface corresponding to the given side of the given tile in the
# given TileMap.
func get_surface_for_tile(
        tile_map: SurfacesTileMap,
        tile_map_index: int,
        side: int) -> Surface:
    var _tile_map_index_to_surfaces: Dictionary = \
            _tile_map_index_to_surface_maps[tile_map][side]
    if _tile_map_index_to_surfaces.has(tile_map_index):
        return _tile_map_index_to_surfaces[tile_map_index]
    else:
        return null


func get_subset_of_surfaces(
        include_walls: bool,
        include_ceilings: bool,
        include_floors: bool) -> Array:
    if include_walls:
        if include_ceilings:
            if include_floors:
                return all_surfaces
            else:
                return non_floor_surfaces
        else:
            if include_floors:
                return non_ceiling_surfaces
            else:
                return all_walls
    else:
        if include_ceilings:
            if include_floors:
                return non_wall_surfaces
            else:
                return ceilings
        else:
            if include_floors:
                return floors
            else:
                return []


func load_from_json_object(
        json_object: Dictionary,
        context: Dictionary,
        surface_parser) -> void:
    var tile_maps: Array = context.id_to_tile_map.values()
    surface_parser._calculate_max_tile_map_cell_size(self, tile_maps)
    surface_parser._calculate_combined_tile_map_rect(self, tile_maps)
    
    floors = _json_object_to_surface_array(json_object.floors, context)
    ceilings = _json_object_to_surface_array(json_object.ceilings, context)
    left_walls = _json_object_to_surface_array(json_object.left_walls, context)
    right_walls = \
            _json_object_to_surface_array(json_object.right_walls, context)
    
    # TODO: This is broken with multiple tilemaps.
    surface_parser._populate_derivative_collections(self, tile_maps[0])
    
    for i in floors.size():
        floors[i].load_references_from_json_context(
                json_object.floors[i],
                context)
    for i in ceilings.size():
        ceilings[i].load_references_from_json_context(
                json_object.ceilings[i],
                context)
    for i in left_walls.size():
        left_walls[i].load_references_from_json_context(
                json_object.left_walls[i],
                context)
    for i in right_walls.size():
        right_walls[i].load_references_from_json_context(
                json_object.right_walls[i],
                context)


func to_json_object() -> Dictionary:
    return {
        floors = _surface_array_to_json_object(floors),
        ceilings = _surface_array_to_json_object(ceilings),
        left_walls = _surface_array_to_json_object(left_walls),
        right_walls = _surface_array_to_json_object(right_walls),
    }


func _json_object_to_surface_array(
        json_object: Array,
        context: Dictionary) -> Array:
    var result := []
    result.resize(json_object.size())
    for i in json_object.size():
        var surface := Surface.new()
        surface.load_from_json_object(
                json_object[i],
                context)
        result[i] = surface
    return result


func _surface_array_to_json_object(surfaces: Array) -> Array:
    var result := []
    result.resize(surfaces.size())
    for i in surfaces.size():
        result[i] = surfaces[i].to_json_object()
    return result
