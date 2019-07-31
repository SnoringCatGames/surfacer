# Parameters that are used for calculating edge instructions.
# FIXME: --A ********* doc
extends Reference
class_name MovementCalcGlobalParams

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
var constraint_offset: Vector2

# The start position for the current edge instructions.
var position_start: Vector2

# The end position for the current edge instructions.
var position_end: Vector2

# Whether the calculations for the current edge are allowed to attempt backtracking to consider a
# higher jump.
var can_backtrack_on_height: bool

# The destination for the current edge instructions.
var destination_surface: Surface

# Any Surfaces that have previously been hit while calculating the current edge instructions.
# Dictionary<Surface, bool>
var collided_surfaces: Dictionary

func _init(movement_params: MovementParams, space_state: Physics2DDirectSpaceState, \
            surface_parser: SurfaceParser, can_backtrack_on_height := true) -> void:
    self.movement_params = movement_params
    self.space_state = space_state
    self.surface_parser = surface_parser
    self.can_backtrack_on_height = can_backtrack_on_height
    
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
    shape_query_params.set_shape(movement_params.collider_shape)
