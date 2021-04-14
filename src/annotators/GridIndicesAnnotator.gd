class_name GridIndicesAnnotator
extends Node2D

var TILE_INDICES_COLOR := SurfacerColors.opacify(SurfacerColors.WHITE, SurfacerColors.ALPHA_FAINT)

var surface_parser: SurfaceParser

func _init(surface_parser: SurfaceParser) -> void:
    self.surface_parser = surface_parser

func _draw() -> void:
    _draw_tile_indices()

func _draw_tile_indices(only_render_used_indices := false) -> void:
    var half_cell_size: Vector2
    var positions: Array
    var cell_top_left_corner: Vector2
    var cell_center: Vector2
    var cell_position_text: String
    var tile_map_index: int
    var color := TILE_INDICES_COLOR
    
    for tile_map in surface_parser._tile_map_index_to_surface_maps:
        half_cell_size = tile_map.cell_size * 0.5
        
        if only_render_used_indices:
            positions = tile_map.get_used_cells()
        else:
            var tile_map_used_rect = tile_map.get_used_rect()
            var tile_map_start_x = tile_map_used_rect.position.x
            var tile_map_start_y = tile_map_used_rect.position.y
            var tile_map_width = tile_map_used_rect.size.x
            var tile_map_height = tile_map_used_rect.size.y
            positions = []
            positions.resize(tile_map_width * tile_map_height)
            for y in tile_map_height:
                for x in tile_map_width:
                    positions[y * tile_map_width + x] = \
                            Vector2(x + tile_map_start_x, y + tile_map_start_y)
        
        for position in positions:
            # Draw the grid index of the cell.
            cell_top_left_corner = tile_map.map_to_world(position)
            cell_center = cell_top_left_corner + half_cell_size
            tile_map_index = Gs.geometry.get_tile_map_index_from_grid_coord(
                    position,
                    tile_map)
            draw_string(
                    Gs.fonts.main_xs,
                    cell_center,
                    str(tile_map_index),
                    color)
            draw_circle(
                    cell_center,
                    1.0,
                    color)
