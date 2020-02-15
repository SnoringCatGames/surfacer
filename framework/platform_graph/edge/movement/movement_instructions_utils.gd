# A collection of utility functions for calculating state related to MovementInstructions.
class_name MovementInstructionsUtils

const MovementInstruction := preload("res://framework/platform_graph/edge/movement/models/movement_instruction.gd")

# FIXME: B 
# - Should I remove this and force a slightly higher offset to target jump position directly? What
#   about passing through constraints? Would the increased time to get to the position for a
#   wall-top constraint result in too much downward velocity into the ceiling?
# - Or what about the constraint offset margins? Shouldn't those actually address any needed
#   jump-height epsilon? Is this needlessly redundant with that mechanism?
# - Though I may need to always at least have _some_ small value here...
# FIXME: D Tweak this.
const JUMP_DURATION_INCREASE_EPSILON := Utils.PHYSICS_TIME_STEP * 0.5
const MOVE_SIDEWAYS_DURATION_INCREASE_EPSILON := Utils.PHYSICS_TIME_STEP * 0.5

var JUMP_RELEASE_INSTRUCTION = MovementInstruction.new("jump", -1, false)

const VALID_END_POSITION_DISTANCE_SQUARED_THRESHOLD := 64.0

# FIXME: B: use this to record slow/fast gravities on the movement_params when initializing and
#        update all usages to use the right one (rather than mutating the movement_params in the
#        middle of edge calculations below).
# FIXME: B: Update step calculation to increase durations by a slight amount (after calculating
#        them all), in order to not have the rendered/discrete trajectory stop short?
# FIXME: B: Update tests to use the new acceleration values.
const GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION := 1.00#1.08

# Translates movement data from a form that is more useful when calculating the movement to a form
# that is more useful when executing the movement.
static func convert_calculation_steps_to_movement_instructions( \
        position_start: Vector2, position_end: Vector2, \
        calc_results: MovementCalcResults, includes_jump: bool, \
        destination_side: int) -> MovementInstructions:
    var steps := calc_results.horizontal_steps
    var vertical_step := calc_results.vertical_step
    
    var constraint_positions := []
    
    var instructions := []
    instructions.resize(steps.size() * 2)
    
    var step: MovementCalcStep
    var input_key: String
    var press: MovementInstruction
    var release: MovementInstruction

    # Record the various sideways movement instructions.
    for i in range(steps.size()):
        step = steps[i]
        input_key = "move_left" if step.horizontal_acceleration_sign < 0 else "move_right"
        press = MovementInstruction.new(input_key, step.time_instruction_start, true)
        release = MovementInstruction.new(input_key, \
                step.time_instruction_end + MOVE_SIDEWAYS_DURATION_INCREASE_EPSILON, false)
        instructions[i * 2] = press
        instructions[i * 2 + 1] = release
        
        # Keep track of some info for edge annotation debugging.
        constraint_positions.push_back(step.position_step_end)
    
    if destination_side == SurfaceSide.LEFT_WALL or destination_side == SurfaceSide.RIGHT_WALL:
        # When landing on a wall, make sure we are pressing into the wall when we land (otherwise,
        # we won't grab on).
        
        var last_step: MovementCalcStep = steps[steps.size() - 1]
        var time_step_start := last_step.time_instruction_end + \
                MOVE_SIDEWAYS_DURATION_INCREASE_EPSILON * 2
        input_key = "grab_wall"
        press = MovementInstruction.new(input_key, time_step_start, true)
        instructions.push_back(press)
    
    # Record the jump instruction.
    if includes_jump:
        input_key = "jump"
        press = MovementInstruction.new(input_key, vertical_step.time_instruction_start, true)
        release = MovementInstruction.new(input_key, \
                vertical_step.time_instruction_end + JUMP_DURATION_INCREASE_EPSILON, false)
        instructions.push_front(release)
        instructions.push_front(press)
    
    var frame_continous_positions_from_steps := _concatenate_step_frame_positions(steps)
    # FIXME: Remove? Do a performance test to see if using this would be significantly faster.
#    var distance_from_end_to_end := position_start.distance_to(position_end)
    
    var result := MovementInstructions.new(instructions, INF, constraint_positions)
    result.frame_continous_positions_from_steps = frame_continous_positions_from_steps
    
    return result

static func _concatenate_step_frame_positions(steps: Array) -> PoolVector2Array:
    var combined_positions := []
    
    for step in steps:
        Utils.concat(combined_positions, step.frame_positions)
        # Since the start-position of the next step is always the same as the end-position of the
        # previous step, we can de-dup them here.
        combined_positions.remove(combined_positions.size() - 1)
    
    # Fix the fencepost problem.
    combined_positions.push_back(steps.back().frame_positions.back())
    
    return PoolVector2Array(combined_positions)

# Test that the given instructions were created correctly.
static func test_instructions(instructions: MovementInstructions, \
        overall_calc_params: MovementCalcOverallParams, calc_results: MovementCalcResults) -> bool:
    assert(instructions.instructions.size() > 0)
    
    assert(instructions.instructions[0].time == 0.0)
    
    # FIXME: B: REMOVE
    overall_calc_params.movement_params.gravity_fast_fall /= \
            GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    overall_calc_params.movement_params.gravity_slow_rise /= \
            GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    
    var collision := CollisionCheckUtils.check_instructions_for_collision(overall_calc_params, \
            instructions, calc_results.vertical_step, calc_results.horizontal_steps)
    assert(collision == null or \
            (collision.is_valid_collision_state and \
            collision.surface == overall_calc_params.destination_constraint.surface))
    var final_frame_position := instructions.frame_discrete_positions_from_test[ \
            instructions.frame_discrete_positions_from_test.size() - 1]
    # FIXME: B: Add back in after fixing the use of GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION.
#    assert(final_frame_position.distance_squared_to( \
#            overall_calc_params.destination_constraint.position) < \
#            VALID_END_POSITION_DISTANCE_SQUARED_THRESHOLD)

    # FIXME: B: REMOVE
    overall_calc_params.movement_params.gravity_fast_fall *= \
            GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    overall_calc_params.movement_params.gravity_slow_rise *= \
            GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    
    return true
