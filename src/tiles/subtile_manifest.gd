class_name SubtileManifest
extends Node


var quadrant_size: int
var autotile_name_prefix: String
var are_45_degree_subtiles_used: bool
var are_27_degree_subtiles_used: bool

var corner_type_annotation_key_path: String
var tile_set_quadrants_path: String
var tile_set_corner_type_annotations_path: String

var tile_set: TileSet
var tile_set_image_parser: TileSetImageParser
var subtile_target_corner_calculator: SubtileTargetCornerCalculator

# Dictionary<int, int>
var corner_types_to_swap_for_bottom_quadrants: Dictionary


func register_manifest(manifest: Dictionary) -> void:
    self.quadrant_size = manifest.quadrant_size
    self.autotile_name_prefix = manifest.autotile_name_prefix
    self.are_45_degree_subtiles_used = manifest.are_45_degree_subtiles_used
    self.are_27_degree_subtiles_used = manifest.are_27_degree_subtiles_used
    
    self.corner_type_annotation_key_path = \
            manifest.corner_type_annotation_key_path
    self.tile_set_quadrants_path = \
            manifest.tile_set_quadrants_path
    self.tile_set_corner_type_annotations_path = \
            manifest.tile_set_corner_type_annotations_path
    
    self.tile_set = manifest.tile_set
    
    if manifest.has("tile_set_image_parser_class"):
        self.tile_set_image_parser = manifest.tile_set_image_parser_class.new()
        assert(self.tile_set_image_parser is TileSetImageParser)
    else:
        self.tile_set_image_parser = TileSetImageParser.new()
    self.add_child(tile_set_image_parser)
    
    if manifest.has("subtile_target_corner_calculator_class"):
        self.subtile_target_corner_calculator = \
                manifest.subtile_target_corner_calculator_class.new()
        assert(self.subtile_target_corner_calculator is \
                SubtileTargetCornerCalculator)
    else:
        self.subtile_target_corner_calculator = \
                SubtileTargetCornerCalculator.new()
    self.add_child(subtile_target_corner_calculator)
    
    _parse_corner_types_to_swap_for_bottom_quadrants(manifest)


func _parse_corner_types_to_swap_for_bottom_quadrants(
        manifest: Dictionary) -> void:
    self.corner_types_to_swap_for_bottom_quadrants = {}
    for corner_type_pair in manifest.corner_types_to_swap_for_bottom_quadrants:
        assert(corner_type_pair is Array and \
                corner_type_pair.size() == 2 and \
                corner_type_pair[0] is int and \
                corner_type_pair[1] is int)
        self.corner_types_to_swap_for_bottom_quadrants[corner_type_pair[0]] = \
                corner_type_pair[1]
        self.corner_types_to_swap_for_bottom_quadrants[corner_type_pair[1]] = \
                corner_type_pair[0]
