class_name Surface
extends Reference

# Vertices are always specified in clockwise order.
var vertices: PoolVector2Array

var side := SurfaceSide.NONE

var tile_map: SurfacesTileMap

# Array<int>
var tile_map_indices: Array

var bounding_box: Rect2
# The combined bounding box for the overall collection of transitively connected surfaces.
var connected_region_bounding_box := Rect2(Vector2.INF, Vector2.INF)

var normal := Vector2.INF

var clockwise_convex_neighbor: Surface
var counter_clockwise_convex_neighbor: Surface
var clockwise_concave_neighbor: Surface
var counter_clockwise_concave_neighbor: Surface

var first_point: Vector2 setget ,_get_first_point
var last_point: Vector2 setget ,_get_last_point

var center: Vector2 setget ,_get_center

var clockwise_neighbor: Surface setget ,_get_clockwise_neighbor
var counter_clockwise_neighbor: Surface setget ,_get_counter_clockwise_neighbor

func _init( \
        vertices: Array, \
        side: int, \
        tile_map: SurfacesTileMap, \
        tile_map_indices: Array) -> void:
    self.vertices = PoolVector2Array(vertices)
    self.side = side
    self.tile_map = tile_map
    self.tile_map_indices = tile_map_indices
    self.bounding_box = Gs.geometry.get_bounding_box_for_points(vertices)
    self.normal = SurfaceSide.get_normal(side)

func to_string() -> String:
    return "Surface{ %s, [ %s, %s ] }" % [ \
            SurfaceSide.get_string(side), \
            vertices[0], \
            vertices[vertices.size() - 1], \
        ]

func _get_first_point() -> Vector2:
    return vertices[0]

func _get_last_point() -> Vector2:
    return vertices[vertices.size() - 1]

func _get_center() -> Vector2:
    return bounding_box.position + (bounding_box.end - bounding_box.position) / 2.0

func _get_clockwise_neighbor() -> Surface:
    return clockwise_convex_neighbor if \
            clockwise_convex_neighbor != null else \
            clockwise_concave_neighbor

func _get_counter_clockwise_neighbor() -> Surface:
    return counter_clockwise_convex_neighbor if \
            counter_clockwise_convex_neighbor != null else \
            counter_clockwise_concave_neighbor

func serialize() -> Dictionary:
    # FIXME: ----------------------------------------
    pass
    return {}
