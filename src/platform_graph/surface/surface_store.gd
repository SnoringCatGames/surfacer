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

# Array<SurfaceMark>
var marks: Array

var max_tilemap_cell_size: Vector2
var combined_tilemap_rect: Rect2

# This supports mapping a cell in a TileMap to its corresponding surface.
# Dictionary<TileMap, Dictionary<int, Dictionary<int, Surface>>>
var _tilemap_index_to_surface_maps := {}

var _collision_surface_result := CollisionSurfaceResult.new()


# Gets the surface corresponding to the given side of the given tile in the
# given TileMap.
func get_surface_for_tile(
        tile_map: TileMap,
        tilemap_index: int,
        side: int) -> Surface:
    var _tilemap_index_to_surfaces: Dictionary = \
            _tilemap_index_to_surface_maps[tile_map][side]
    if _tilemap_index_to_surfaces.has(tilemap_index):
        return _tilemap_index_to_surfaces[tilemap_index]
    else:
        return null


func get_surface_set(movement_params: MovementParameters) -> Dictionary:
    var set := {}
    
    # Collect all surfaces for each surface-side the character could grab.
    var surface_collections := []
    if movement_params.can_grab_floors:
        surface_collections.push_back(floors)
    if movement_params.can_grab_walls:
        surface_collections.push_back(all_walls)
    if movement_params.can_grab_ceilings:
        surface_collections.push_back(ceilings)
    for surface_collection in surface_collections:
        for surface in surface_collection:
            # Filter-out surfaces that cannot be grabbed according to their
            # properties.
            if surface.properties.can_grab:
                set[surface] = true
    
    # Filter-out surfaces according to SurfaceMarks.
    for mark in marks:
        if !(mark is SurfaceEnablement):
            # Only omit surfaces for the enablement mark.
            continue
        
        var does_mark_match_character: bool = \
                mark.get_character_category_names() \
                    .has(movement_params.character_category_name)
        if does_mark_match_character:
            if mark.include_exclusively:
                # Remove any surface that isn't marked.
                for surface in set.keys():
                    if !mark.get_is_surface_marked(surface):
                        set.erase(surface)
            elif mark.exclude:
                # Remove any surface that is marked.
                for surface in mark._marked_surfaces:
                    if surface.first_point == Vector2(-352, 256):
                        print("break")
                    set.erase(surface)
    
    return set


func load_from_json_object(
        json_object: Dictionary,
        context: Dictionary,
        surface_parser) -> void:
    var tilemaps: Array = context.id_to_tilemap.values()
    surface_parser._calculate_max_tilemap_cell_size(self, tilemaps)
    surface_parser._calculate_combined_tilemap_rect(self, tilemaps)
    
    floors = _json_object_to_surface_array(json_object.floors, context)
    ceilings = _json_object_to_surface_array(json_object.ceilings, context)
    left_walls = _json_object_to_surface_array(json_object.left_walls, context)
    right_walls = \
            _json_object_to_surface_array(json_object.right_walls, context)
    
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
    
    surface_parser._populate_derivative_collections(self, tilemaps)


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
