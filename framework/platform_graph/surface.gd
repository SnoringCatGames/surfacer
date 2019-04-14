extends Reference
class_name Surface

var vertices: PoolVector2Array
var side: int
var bounding_box: Rect2
var normal: Vector2 setget ,normal_get

func _init(vertices: PoolVector2Array, side: int) -> void:
    self.vertices = vertices
    self.side = side
    bounding_box = Geometry.get_bounding_box_for_points(vertices)

func normal_get() -> Vector2:
    return \
            Geometry.UP if side == SurfaceSide.FLOOR else (\
            Geometry.DOWN if side == SurfaceSide.CEILING else (\
            Geometry.RIGHT if side == SurfaceSide.LEFT_WALL else (\
            Geometry.LEFT)))
