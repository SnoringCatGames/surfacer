class_name GridIndicesAnnotator
extends Node2D


var TILE_INDICES_COLOR: Color = Sc.colors.grid_indices

var surface_store: SurfaceStore


func _init(surface_store: SurfaceStore) -> void:
    self.surface_store = surface_store


func _draw() -> void:
    _draw_tile_indices()


func _draw_tile_indices(only_render_used_indices := false) -> void:
    for tile_map in surface_store._tile_map_index_to_surface_maps:
        Sc.draw.draw_tile_map_indices(
                self,
                tile_map,
                TILE_INDICES_COLOR,
                only_render_used_indices)
