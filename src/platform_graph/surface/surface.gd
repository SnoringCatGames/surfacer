class_name Surface
extends Reference
## -   A section of a collidable tile map formed from all continguous tiles
##     along one axially-aligned side.[br]
## -   E.g., a single disconnected tile will have four surfaces:
##     FLOOR, LEFT_WALL, RIGHT_WALL, and CEILING.[br]
## -   **NOTE**: "left wall" is from the perspective of the openspace around
##               the tile. So a "left-wall" surface, is actually along the
##               "right-side" of the tile.[br]


# Vertices are always specified in clockwise order.
var vertices: PoolVector2Array

var side := SurfaceSide.NONE

var properties: SurfaceProperties

var tile_map: TileMap

# Array<int>
var tilemap_indices: Array

var bounding_box: Rect2
# The combined bounding box for the overall collection of transitively
# connected surfaces.
var connected_region_bounding_box := Rect2(Vector2.INF, Vector2.INF)

var normal := Vector2.INF

var clockwise_convex_neighbor: Surface
var clockwise_concave_neighbor: Surface
var clockwise_collinear_neighbor: Surface

var counter_clockwise_convex_neighbor: Surface
var counter_clockwise_concave_neighbor: Surface
var counter_clockwise_collinear_neighbor: Surface

var first_point: Vector2 setget ,_get_first_point
var last_point: Vector2 setget ,_get_last_point

var center: Vector2 setget ,_get_center

var clockwise_neighbor: Surface setget ,_get_clockwise_neighbor
var counter_clockwise_neighbor: Surface setget ,_get_counter_clockwise_neighbor

var is_single_vertex: bool setget ,_get_is_single_vertex
var is_axially_aligned: bool setget ,_get_is_axially_aligned


func _init(
        vertices := [],
        side := SurfaceSide.NONE,
        tile_map = null,
        tilemap_indices := [],
        properties: SurfaceProperties = null) -> void:
    self.vertices = PoolVector2Array(vertices)
    self.side = side
    self.tile_map = tile_map
    self.tilemap_indices = tilemap_indices
    self.properties = properties
    if !vertices.empty():
        self.bounding_box = Sc.geometry.get_bounding_box_for_points(vertices)
    if side != SurfaceSide.NONE:
        self.normal = SurfaceSide.get_normal(side)
    if !is_instance_valid(properties):
        self.properties = Su.surface_properties.properties["default"]


func to_string(verbose := true) -> String:
    if verbose:
        return "Surface{ %s, [ %s, %s ] }" % [
                SurfaceSide.get_string(side),
                vertices[0],
                vertices[vertices.size() - 1],
            ]
    else:
        return "%s%s" % [
                SurfaceSide.get_prefix(side),
                Sc.utils.get_vector_string(vertices[0], 1),
            ]


func _get_first_point() -> Vector2:
    return vertices[0]


func _get_last_point() -> Vector2:
    return vertices[vertices.size() - 1]


func _get_center() -> Vector2:
    return bounding_box.position + \
            (bounding_box.end - bounding_box.position) / 2.0


func _get_clockwise_neighbor() -> Surface:
    return clockwise_convex_neighbor if \
            clockwise_convex_neighbor != null else \
            clockwise_concave_neighbor if \
            clockwise_concave_neighbor != null else \
            clockwise_collinear_neighbor


func _get_counter_clockwise_neighbor() -> Surface:
    return counter_clockwise_convex_neighbor if \
            counter_clockwise_convex_neighbor != null else \
            counter_clockwise_concave_neighbor if \
            counter_clockwise_concave_neighbor != null else \
            counter_clockwise_collinear_neighbor


func _get_is_single_vertex() -> bool:
    return vertices.size() == 1


func _get_is_axially_aligned() -> bool:
    return vertices.size() <= 2 and \
            (normal.x == 0.0 or normal.y == 0.0)


func probably_equal(other: Surface) -> bool:
    if self.side != other.side:
        return false
    
    if self.tile_map != other.tile_map:
        return false
    
    if self.vertices.size() != other.vertices.size():
        return false
    for i in self.vertices.size():
        if !Sc.geometry.are_points_equal_with_epsilon(
                self.vertices[i],
                other.vertices[i],
                0.0001):
            return false
    
    if self.tilemap_indices.size() != other.tilemap_indices.size():
        return false
    for i in self.tilemap_indices.size():
        if self.tilemap_indices[i] != other.tilemap_indices[i]:
            return false
    
    if !Sc.geometry.are_rects_equal_with_epsilon(
            self.bounding_box,
            other.bounding_box,
            0.0001):
        return false
    
    if !Sc.geometry.are_rects_equal_with_epsilon(
            self.connected_region_bounding_box,
            other.connected_region_bounding_box,
            0.0001):
        return false
    
    if (self.clockwise_convex_neighbor == null) != \
            (other.clockwise_convex_neighbor == null):
        return false
    
    if (self.counter_clockwise_convex_neighbor == null) != \
            (other.counter_clockwise_convex_neighbor == null):
        return false
    
    if (self.clockwise_concave_neighbor == null) != \
            (other.clockwise_concave_neighbor == null):
        return false
    
    if (self.counter_clockwise_concave_neighbor == null) != \
            (other.counter_clockwise_concave_neighbor == null):
        return false
    
    if (self.clockwise_collinear_neighbor == null) != \
            (other.clockwise_collinear_neighbor == null):
        return false
    
    if (self.counter_clockwise_collinear_neighbor == null) != \
            (other.counter_clockwise_collinear_neighbor == null):
        return false
    
    return true


func load_from_json_object(
        json_object: Dictionary,
        context: Dictionary) -> void:
    context.id_to_surface[int(json_object.d)] = self
    vertices = PoolVector2Array(Sc.json.decode_vector2_array(json_object.v))
    side = json_object.s
    tilemap_indices = to_int_array(json_object.i)
    properties = Su.surface_properties.properties[json_object.p]
    bounding_box = Sc.geometry.get_bounding_box_for_points(vertices)
    normal = SurfaceSide.get_normal(side)


func load_references_from_json_context(
        json_object: Dictionary,
        context: Dictionary) -> void:
    tile_map = context.id_to_tilemap[json_object.t]
    connected_region_bounding_box = Sc.json.decode_rect2(json_object.crbb)
    clockwise_convex_neighbor = \
            _get_surface_from_id(json_object.cwv, context.id_to_surface)
    clockwise_concave_neighbor = \
            _get_surface_from_id(json_object.cwc, context.id_to_surface)
    clockwise_collinear_neighbor = \
            _get_surface_from_id(json_object.cwl, context.id_to_surface)
    counter_clockwise_convex_neighbor = \
            _get_surface_from_id(json_object.ccwv, context.id_to_surface)
    counter_clockwise_concave_neighbor = \
            _get_surface_from_id(json_object.ccwc, context.id_to_surface)
    counter_clockwise_collinear_neighbor = \
            _get_surface_from_id(json_object.ccwl, context.id_to_surface)


func to_json_object() -> Dictionary:
    return {
        d = self.get_instance_id(),
        v = Sc.json.encode_vector2_array(vertices),
        s = side,
        t = tile_map.id,
        i = tilemap_indices,
        p = properties.name,
        crbb = Sc.json.encode_rect2(connected_region_bounding_box),
        cwv = Sc.utils.get_instance_id_or_not(clockwise_convex_neighbor),
        cwc = Sc.utils.get_instance_id_or_not(clockwise_concave_neighbor),
        cwl = Sc.utils.get_instance_id_or_not(clockwise_collinear_neighbor),
        ccwv = Sc.utils.get_instance_id_or_not(
                counter_clockwise_convex_neighbor),
        ccwc = Sc.utils.get_instance_id_or_not(
                counter_clockwise_concave_neighbor),
        ccwl = Sc.utils.get_instance_id_or_not(
                counter_clockwise_collinear_neighbor),
    }


func _get_surface_from_id(
        id: int,
        id_to_surface: Dictionary) -> Surface:
    return id_to_surface[id] if \
            id >= 0 else \
            null


func to_int_array(source: Array) -> Array:
    var result := []
    result.resize(source.size())
    for i in source.size():
        result[i] = int(source[i])
    return result
