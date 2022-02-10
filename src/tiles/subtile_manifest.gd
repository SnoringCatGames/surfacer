class_name SubtileManifest
extends Node


# TODO: Add support for:
# - !forces_convex_collision_shapes
# - Multiple autotiling 90/45/27-tile-collections.
# - One-way collisions
# - Configuring z-index


###

var quadrant_size: int
var subtile_collision_margin: float
var autotile_name_prefix: String
var are_45_degree_subtiles_used: bool
var are_27_degree_subtiles_used: bool
var forces_convex_collision_shapes: bool
var allows_partial_matches: bool
var supports_runtime_autotiling: bool

var corner_type_annotation_key_path: String
var tile_set_quadrants_path: String
var tile_set_corner_type_annotations_path: String

var tile_set: CornerMatchTileset
var tile_set_image_parser: TileSetImageParser
var subtile_target_corner_calculator: SubtileTargetCornerCalculator
var shape_calculator: CornerMatchAutotileShapeCalculator
var initializer: CornerMatchAutotileInitializer

var corner_type_annotation_key_texture: Texture
var tile_set_quadrants_texture: Texture
var tile_set_corner_type_annotations_texture: Texture

# Dictionary<int, int>
var corner_types_to_swap_for_bottom_quadrants: Dictionary

###


func register_manifest(manifest: Dictionary) -> void:
    self.quadrant_size = manifest.quadrant_size
    self.subtile_collision_margin = manifest.subtile_collision_margin
    self.autotile_name_prefix = manifest.autotile_name_prefix
    self.are_45_degree_subtiles_used = manifest.are_45_degree_subtiles_used
    self.are_27_degree_subtiles_used = manifest.are_27_degree_subtiles_used
    self.forces_convex_collision_shapes = \
            manifest.forces_convex_collision_shapes
    self.allows_partial_matches = manifest.allows_partial_matches
    self.supports_runtime_autotiling = manifest.supports_runtime_autotiling
    
    self.corner_type_annotation_key_path = \
            manifest.corner_type_annotation_key_path
    self.tile_set_quadrants_path = \
            manifest.tile_set_quadrants_path
    self.tile_set_corner_type_annotations_path = \
            manifest.tile_set_corner_type_annotations_path
    
    assert(manifest.tile_set is CornerMatchTileset)
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
    
    if manifest.has("shape_calculator_class"):
        self.shape_calculator = manifest.shape_calculator_class.new()
        assert(self.shape_calculator is CornerMatchAutotileShapeCalculator)
    else:
        self.shape_calculator = CornerMatchAutotileShapeCalculator.new()
    self.add_child(shape_calculator)
    
    if manifest.has("initializer_class"):
        self.initializer = manifest.initializer_class.new()
        assert(self.initializer is CornerMatchAutotileInitializer)
    else:
        self.initializer = CornerMatchAutotileInitializer.new()
    self.add_child(initializer)
    
    _parse_corner_types_to_swap_for_bottom_quadrants(manifest)
    
    if !supports_runtime_autotiling and \
            Engine.editor_hint:
        return
    
    self.corner_type_annotation_key_texture = \
            load(corner_type_annotation_key_path)
    self.tile_set_quadrants_texture = load(tile_set_quadrants_path)
    self.tile_set_corner_type_annotations_texture = \
            load(tile_set_corner_type_annotations_path)
    
    initializer.initialize_tiles(tile_set)


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
