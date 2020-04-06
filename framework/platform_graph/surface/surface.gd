extends Reference
class_name Surface

# Vertices are always specified in clockwise order.
var vertices: PoolVector2Array

# SurfaceSide
var side: int

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

func _init( \
        vertices: Array, \
        side: int, \
        tile_map_indices: Array) -> void:
    self.vertices = PoolVector2Array(vertices)
    self.side = side
    self.tile_map_indices = tile_map_indices
    bounding_box = Geometry.get_bounding_box_for_points(vertices)
    normal = SurfaceSide.get_normal(side)

func to_string() -> String:
    return "Surface{ %s, [ %s, %s ] }" % [ \
            SurfaceSide.to_string(side), \
            vertices[0], \
            vertices[vertices.size() - 1], \
        ]

func _get_first_point() -> Vector2:
    return vertices[0]

func _get_last_point() -> Vector2:
    return vertices[vertices.size() - 1]
