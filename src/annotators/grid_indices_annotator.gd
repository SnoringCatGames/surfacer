class_name GridIndicesAnnotator
extends Node2D


var TILE_INDICES_COLOR: Color = Sc.colors.grid_indices

var surface_parser: SurfaceParser


func _init(surface_parser: SurfaceParser) -> void:
    self.surface_parser = surface_parser


func _draw() -> void:
    _draw_tile_indices()


func _draw_tile_indices(only_render_used_indices := false) -> void:
    for tile_map in surface_parser._tile_map_index_to_surface_maps:
        Sc.draw.draw_tile_map_indices(
                self,
                tile_map,
                TILE_INDICES_COLOR,
                only_render_used_indices)
