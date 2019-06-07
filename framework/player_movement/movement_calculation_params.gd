# Parameters that are used for calculating edge instructions.
extends Reference
class_name MovementCalcParams

const TILE_MAP_COLLISION_LAYER := 2
const EDGE_MOVEMENT_TEST_MARGIN := 4.0
const EDGE_MOVEMENT_ACTUAL_MARGIN := 5.0

# The Godot collision-detection APIs use this state.
var space_state: Physics2DDirectSpaceState

# The Godot collision-detection APIs use this data structure.
var shape_query_params: Physics2DShapeQueryParameters

# A margin to extend around the Player's Collider. This helps to compensate for the imprecision
# of these calculations.
var constraint_offset: Vector2

# The single vertical step for this jump movement.
var vertical_step: MovementCalcStep

# The total duration of the overall movement.
var total_duration: float

# The destination for the current edge instructions calculations.
var destination_surface: Surface

# Any Surfaces that have previously been hit while calculating the current edge instructions.
# Dictionary<Surface, bool>
var collided_surfaces: Dictionary

func _init(movement_params: MovementParams, space_state: Physics2DDirectSpaceState) -> void:
    self.space_state = space_state
    
    constraint_offset = movement_params.collider_half_width_height + \
        Vector2(EDGE_MOVEMENT_ACTUAL_MARGIN, EDGE_MOVEMENT_ACTUAL_MARGIN)
    
    collided_surfaces = {}
    
    shape_query_params = Physics2DShapeQueryParameters.new()
    shape_query_params.collide_with_areas = false
    shape_query_params.collide_with_bodies = true
    shape_query_params.collision_layer = TILE_MAP_COLLISION_LAYER
    shape_query_params.exclude = []
    shape_query_params.margin = EDGE_MOVEMENT_TEST_MARGIN
    shape_query_params.motion = Vector2.ZERO
    shape_query_params.shape_rid = movement_params.collider_shape.get_rid()
    shape_query_params.transform = Transform2D.IDENTITY
