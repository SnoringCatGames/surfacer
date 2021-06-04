class_name GridIndicesAnnotator
extends Node2D

var TILE_INDICES_COLOR: Color = Gs.colors.grid_indices

var surface_parser: SurfaceParser

func _init(surface_parser: SurfaceParser) -> void:
    self.surface_parser = surface_parser

func _draw() -> void:
    _draw_tile_indices()

func _draw_tile_indices(only_render_used_indices := false) -> void:
    for tile_map in surface_parser._tile_map_index_to_surface_maps:
        var half_cell_size: Vector2 = tile_map.cell_size * 0.5
        
        var positions: Array
        if only_render_used_indices:
            positions = tile_map.get_used_cells()
        else:
            var tile_map_used_rect: Rect2 = tile_map.get_used_rect()
            var tile_map_start_x := tile_map_used_rect.position.x
            var tile_map_start_y := tile_map_used_rect.position.y
            var tile_map_width := tile_map_used_rect.size.x
            var tile_map_height := tile_map_used_rect.size.y
            positions = []
            positions.resize(tile_map_width * tile_map_height)
            for y in tile_map_height:
                for x in tile_map_width:
                    positions[y * tile_map_width + x] = \
                            Vector2(x + tile_map_start_x, y + tile_map_start_y)
        
        for position in positions:
            # Draw the grid index of the cell.
            var cell_top_left_corner: Vector2 = tile_map.map_to_world(position)
            var cell_center := cell_top_left_corner + half_cell_size
            var tile_map_index := \
                    Gs.geometry.get_tile_map_index_from_grid_coord(
                            position,
                            tile_map)
            draw_string(
                    Gs.fonts.main_xs,
                    cell_center,
                    str(tile_map_index),
                    TILE_INDICES_COLOR)
            draw_circle(
                    cell_center,
                    1.0,
                    TILE_INDICES_COLOR)
