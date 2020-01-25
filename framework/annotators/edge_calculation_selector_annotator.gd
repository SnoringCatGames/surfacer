extends Node2D
class_name EdgeCalculationSelectorAnnotator

var ORIGIN_SURFACE_SELECTION_COLOR := Colors.opacify(Colors.ORANGE, Colors.ALPHA_FAINT)

const ORIGIN_SURFACE_SELECTION_DASH_LENGTH := 6.0
const ORIGIN_SURFACE_SELECTION_DASH_GAP := 8.0
const ORIGIN_SURFACE_SELECTION_DASH_STROKE_WIDTH := 4.0

const POSSIBLE_JUMP_LAND_POSITION_RADIUS := 3.0
var POSSIBLE_JUMP_LAND_POSITION_COLOR := ORIGIN_SURFACE_SELECTION_COLOR

var global

var edge_attempt: MovementCalcOverallDebugState
var selected_step: MovementCalcStepDebugState

# Array<PositionAlongSurface>
var possible_jump_and_land_positions: Array

var origin: PositionAlongSurface
var destination: PositionAlongSurface

var previous_origin: PositionAlongSurface
var previous_destination: PositionAlongSurface

func _ready() -> void:
    self.global = $"/root/Global"

func _process(delta: float) -> void:
    if origin != previous_origin or \
            destination != previous_destination:
        previous_origin = origin
        previous_destination = destination
        update()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and \
            !event.pressed and event.control:
        # The user is ctrl+clicking.
        
        var click_position: Vector2 = global.current_level.get_global_mouse_position()
        var surface_position := SurfaceParser.find_closest_position_on_a_surface( \
                click_position, global.current_player_for_clicks)
        
        if origin == null:
            origin = surface_position
            destination = null
            edge_attempt = null
        else:
            destination = surface_position
            _calculate_edge_attempt()
            origin = null
            destination = null
        
    elif event is InputEventKey and \
            event.scancode == KEY_CONTROL and \
            !event.pressed:
        # The user is releasing the ctrl key.
        origin = null
        destination = null

func _draw() -> void:
    if edge_attempt != null:
        # The user has selected both surfaces in a new edge to debug. The edge-calculation debug
        # state will now be rendered by another annotator, and this selector annotator is done
        # with this edge.
        _draw_possible_jump_and_land_positions()
    elif origin != null:
        # So far, the user has only selected the first surface in the edge pair.
        _draw_selected_origin()

func _calculate_edge_attempt() -> void:
    var debug_state: Dictionary = global.DEBUG_STATE
    var origin_surface := origin.surface
    var destination_surface := destination.surface
    var player: Player = global.current_player_for_clicks
    var movement_params: MovementParams = player.movement_params
    var space_state := get_world_2d().direct_space_state
    var level = global.current_level
    var surface_parser: SurfaceParser = level.surface_parser
    var collision_params := CollisionCalcParams.new( \
            debug_state, space_state, movement_params, surface_parser)
    
    # Choose the jump and land positions according to which is closest to the click positions.
    var jump_positions := MovementUtils.get_all_jump_land_positions_from_surface( \
            movement_params, origin_surface, destination_surface.vertices, \
            destination_surface.bounding_box, destination_surface.side)
    var jump_position: PositionAlongSurface = jump_positions[0]
    if jump_positions.size() > 1:
        for i in range(1, jump_positions.size()):
            var other_jump_position: PositionAlongSurface = jump_positions[i]
            if other_jump_position.target_point.distance_squared_to(origin.target_point) < \
                    jump_position.target_point.distance_squared_to(origin.target_point):
                jump_position = other_jump_position
    var land_positions := MovementUtils.get_all_jump_land_positions_from_surface( \
            movement_params, destination_surface, origin_surface.vertices, \
            origin_surface.bounding_box, origin_surface.side)
    var land_position: PositionAlongSurface = land_positions[0]
    if land_positions.size() > 1:
        for i in range(1, land_positions.size()):
            var other_land_position: PositionAlongSurface = land_positions[i]
            if other_land_position.target_point.distance_squared_to(origin.target_point) < \
                    land_position.target_point.distance_squared_to(origin.target_point):
                land_position = other_land_position
    
    # Create the jump-calculation parameter object.
    var overall_calc_params := EdgeMovementCalculator.create_movement_calc_overall_params( \
            collision_params, origin_surface, jump_position.target_point, destination_surface, \
            land_position.target_point, true, Vector2.INF, true, true)
    
    if overall_calc_params.origin_constraint.is_valid and \
            overall_calc_params.destination_constraint.is_valid:
        # Calculate the actual jump steps, collision, trajectory, and input state.
        JumpFromSurfaceToSurfaceCalculator.create_edge_from_overall_params(overall_calc_params, \
                jump_position, land_position)
    
    # Record debug state for the jump calculation.
    edge_attempt = overall_calc_params.debug_state
    
    # Record the possible jump and land positions too.
    Utils.concat(jump_positions, land_positions)
    possible_jump_and_land_positions = jump_positions

func _draw_selected_origin() -> void:
    DrawUtils.draw_dashed_polyline(self, origin.surface.vertices, \
            ORIGIN_SURFACE_SELECTION_COLOR, ORIGIN_SURFACE_SELECTION_DASH_LENGTH, \
            ORIGIN_SURFACE_SELECTION_DASH_GAP, 0.0, ORIGIN_SURFACE_SELECTION_DASH_STROKE_WIDTH)

func _draw_possible_jump_and_land_positions() -> void:
    for position in possible_jump_and_land_positions:
        draw_circle(position.target_point, POSSIBLE_JUMP_LAND_POSITION_RADIUS, \
                POSSIBLE_JUMP_LAND_POSITION_COLOR)
