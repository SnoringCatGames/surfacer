class_name SurfaceContact
extends Reference


enum {
    UNKNOWN,
    PHYSICS,
    MATCH_ROUNDING_CORNER,
    MATCH_TRAJECTORY,
    INITIAL_ATTACHMENT,
}


## This indicates what mechanism led to the creation of this contact.
var type := UNKNOWN

var surface: Surface
var contact_position := Vector2.INF
var contact_normal := Vector2.INF
var tile_map: SurfacesTileMap
var tile_map_coord := Vector2.INF
var tile_map_index := -1
var position_along_surface := PositionAlongSurface.new()
var just_started := false
var _is_still_touching := false
