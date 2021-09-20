tool
class_name CrashTestDummy
extends KinematicBody2D


const COLLISION_MASK_FOR_ONLY_SURFACES_TILE_MAP = 1

var character_name: String
var movement_params: MovementParameters
var graph
var surface_store: SurfaceStore
# Dictionary<Surface, Surface>
var possible_surfaces_set: Dictionary


func _init(character_name: String) -> void:
    self.character_name = character_name
    self.movement_params = \
            Su.movement.character_movement_params[character_name]
    self.set_safe_margin(
            movement_params.collision_margin_for_edge_calculations)
    self.collision_mask = COLLISION_MASK_FOR_ONLY_SURFACES_TILE_MAP
    self.collision_layer = 0
    _add_collision_shape()


func _add_collision_shape() -> void:
    var collision_shape := CollisionShape2D.new()
    collision_shape.shape = movement_params.collider.shape
    collision_shape.rotation = movement_params.collider.rotation
    add_child(collision_shape)


func set_platform_graph(graph) -> void:
    self.graph = graph
    self.surface_store = graph.surface_store
    self.possible_surfaces_set = graph.surfaces_set
