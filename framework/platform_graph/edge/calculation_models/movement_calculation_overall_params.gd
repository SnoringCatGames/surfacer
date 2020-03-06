# Parameters that are used for calculating edge instructions.
extends Reference
class_name MovementCalcOverallParams

const TILE_MAP_COLLISION_LAYER := 7
# FIXME: Test these
const EDGE_MOVEMENT_TEST_MARGIN := 4.0#2.0
const EDGE_MOVEMENT_ACTUAL_MARGIN := 5.0#2.5

var movement_params: MovementParams

var surface_parser: SurfaceParser

# The Godot collision-detection APIs use this state.
var space_state: Physics2DDirectSpaceState

# The Godot collision-detection APIs use this data structure.
var shape_query_params: Physics2DShapeQueryParameters

# A margin to extend around the Player's Collider. This helps to compensate for the imprecision
# of these calculations.
var constraint_offset := Vector2.INF

# The initial velocity for the current edge instructions.
var velocity_start := Vector2.INF

var origin_position: PositionAlongSurface
var destination_position: PositionAlongSurface

# The origin for the current edge instructions.
var origin_constraint: MovementConstraint

# The destination for the current edge instructions.
var destination_constraint: MovementConstraint

# Whether the calculations for the current edge are allowed to attempt backtracking to consider a
# higher jump.
var can_backtrack_on_height: bool

# Any Surfaces that have previously been hit while calculating the current edge instructions.
# Dictionary<String, bool>
var _collided_surfaces: Dictionary

var debug_state: MovementCalcOverallDebugState

var in_debug_mode: bool setget _set_in_debug_mode,_get_in_debug_mode

func _init(collision_params: CollisionCalcParams, origin_position: PositionAlongSurface, \
            destination_position: PositionAlongSurface, origin_constraint: MovementConstraint, \
            destination_constraint: MovementConstraint, velocity_start := Vector2.INF, \
            can_backtrack_on_height := true) -> void:
    self.movement_params = collision_params.movement_params
    self.space_state = collision_params.space_state
    self.surface_parser = collision_params.surface_parser
    self.origin_position = origin_position
    self.destination_position = destination_position
    self.origin_constraint = origin_constraint
    self.destination_constraint = destination_constraint
    self.can_backtrack_on_height = can_backtrack_on_height
    self.velocity_start = velocity_start
    self.constraint_offset = calculate_constraint_offset(movement_params)
    self._collided_surfaces = {}
    
    var shape_query_params := Physics2DShapeQueryParameters.new()
    shape_query_params.collide_with_areas = false
    shape_query_params.collide_with_bodies = true
    shape_query_params.collision_layer = TILE_MAP_COLLISION_LAYER
    shape_query_params.exclude = []
    shape_query_params.margin = EDGE_MOVEMENT_TEST_MARGIN
    shape_query_params.motion = Vector2.ZERO
    shape_query_params.shape_rid = movement_params.collider_shape.get_rid()
    shape_query_params.transform = Transform2D(movement_params.collider_rotation, Vector2.ZERO)
    shape_query_params.set_shape(movement_params.collider_shape)
    self.shape_query_params = shape_query_params

func is_backtracking_valid_for_surface(surface: Surface, time_jump_release: float) -> bool:
    var key := str(surface) + str(time_jump_release)
    return _collided_surfaces.has(key)

func record_backtracked_surface(surface: Surface, time_jump_release: float) -> void:
    var key := str(surface) + str(time_jump_release)
    _collided_surfaces[key] = true

func _set_in_debug_mode(value: bool) -> void:
    debug_state = MovementCalcOverallDebugState.new(self) if value else null

func _get_in_debug_mode() -> bool:
    return debug_state != null

static func calculate_constraint_offset(movement_params: MovementParams) -> Vector2:
    return movement_params.collider_half_width_height + \
            Vector2(EDGE_MOVEMENT_ACTUAL_MARGIN, EDGE_MOVEMENT_ACTUAL_MARGIN)
