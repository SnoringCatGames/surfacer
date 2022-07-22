tool
class_name CrashTestDummy
extends KinematicBody2D


const COLLISION_MASK_FOR_ONLY_SURFACES_TILE_MAP = 1

var character_category_name: String
var movement_params: MovementParameters
var graph
var surface_store: SurfaceStore
# Dictionary<Surface, Surface>
var possible_surfaces_set: Dictionary
var collider: RotatedShape


func _init(character_category_name: String) -> void:
    self.character_category_name = character_category_name
    self.movement_params = \
            Su.movement.character_movement_params[character_category_name]
    self.collider = movement_params.collider
    
    self.set_safe_margin(
            movement_params.collision_margin_for_edge_calculations)
    self.collision_mask = COLLISION_MASK_FOR_ONLY_SURFACES_TILE_MAP
    self.collision_layer = 0
    
    var collision_shape := CollisionShape2D.new()
    collision_shape.shape = collider.shape
    collision_shape.rotation = collider.rotation
    add_child(collision_shape)


func set_platform_graph(graph) -> void:
    self.graph = graph
    self.surface_store = graph.surface_store
    self.possible_surfaces_set = graph.surfaces_set
