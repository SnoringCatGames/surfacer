extends Node2D
class_name PlatformGraphAnnotator

var graph: PlatformGraph

const SURFACE_DEPTH := 8.0
const SURFACE_DEPTH_DIVISIONS_COUNT := 8
const SURFACE_ALPHA_START := .8
const SURFACE_ALPHA_END := .1

func _init(graph: PlatformGraph) -> void:
    self.graph = graph

func _draw() -> void:
    _draw_surfaces(graph.nodes.floors, Utils.UP)
    _draw_surfaces(graph.nodes.ceilings, Utils.DOWN)
    _draw_surfaces(graph.nodes.right_walls, Utils.LEFT)
    _draw_surfaces(graph.nodes.left_walls, Utils.RIGHT)
    _draw_tile_indices()

func _draw_surfaces(surfaces: Array, normal: Vector2) -> void:
    var depth_division_size = SURFACE_DEPTH / SURFACE_DEPTH_DIVISIONS_COUNT
    var surface_depth_division_offset = normal * -depth_division_size
    
    var color: Color
    var polyline: PoolVector2Array
    var translation: Vector2
    var progress: float
    
    for surface in surfaces:
        color = Color.from_hsv(randf(), 0.8, 0.8, 1)
        
        # "Surfaces" can single vertices in the degenerate case.
        if surface.size() > 1:
            for i in range(SURFACE_DEPTH_DIVISIONS_COUNT):
                translation = surface_depth_division_offset * i
                polyline = translate_polyline(surface, translation)
                progress = i / (SURFACE_DEPTH_DIVISIONS_COUNT - 1.0)
                color.a = SURFACE_ALPHA_START + progress * (SURFACE_ALPHA_END - SURFACE_ALPHA_START)
                draw_polyline(polyline, color, depth_division_size)
#                Utils.draw_dashed_polyline(self, polyline, color, 4.0, 3.0, 0.0, 2.0, false)
        else:
            color.a = 0.6
            draw_circle(surface[0], 8.0, color)

func _draw_tile_indices(only_render_used_indices := false) -> void:
    var half_cell_size: Vector2
    var positions: Array
    var cell_center: Vector2
    var tile_map_index: int
    var color = Color(1, 1, 1, 0.6)
    
    var label = Label.new()
    var font = label.get_font("")
    
    for tile_map in graph.nodes._tile_map_index_to_surface_maps:
        half_cell_size = tile_map.cell_size / 2
        
        if only_render_used_indices:
            positions = tile_map.get_used_cells()
        else:
            var tile_map_start_x = tile_map.get_used_rect().position.x
            var tile_map_start_y = tile_map.get_used_rect().position.y
            var tile_map_width = tile_map.get_used_rect().size.x
            var tile_map_height = tile_map.get_used_rect().size.y
            positions = []
            positions.resize(tile_map_width * tile_map_height)
            for y in tile_map_height:
                for x in tile_map_width:
                    positions[y * tile_map_width + x] = Vector2(x + tile_map_start_x, y + tile_map_start_y)
        
        for position in positions:
            cell_center = tile_map.map_to_world(position) + half_cell_size
            tile_map_index = Utils.get_tile_map_index_from_grid_coord(position, tile_map)
            draw_string(font, cell_center, str(tile_map_index), color)
            draw_circle(cell_center, 1.0, color)
    
    label.free()

static func translate_polyline(vertices: PoolVector2Array, translation: Vector2) \
        -> PoolVector2Array:
    var result := PoolVector2Array()
    result.resize(vertices.size())
    for i in range(vertices.size()):
        result[i] = vertices[i] + translation
    return result
