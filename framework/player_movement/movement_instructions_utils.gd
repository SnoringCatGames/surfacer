# A collection of utility functions for calculating state related to PlayerInstructions.
class_name MovementInstructionsUtils

const PlayerInstruction := preload("res://framework/player_movement/models/player_instruction.gd")

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

var JUMP_RELEASE_INSTRUCTION = PlayerInstruction.new("jump", -1, false)

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
static func convert_calculation_steps_to_player_instructions( \
        position_start: Vector2, position_end: Vector2, \
        calc_results: MovementCalcResults, includes_jump := true) -> PlayerInstructions:
    var steps := calc_results.horizontal_steps
    var vertical_step := calc_results.vertical_step
    
    var distance_squared := position_start.distance_squared_to(position_end)
    
    var constraint_positions := []
    
    var instructions := []
    instructions.resize(steps.size() * 2)
    
    var step: MovementCalcStep
    var input_key: String
    var press: PlayerInstruction
    var release: PlayerInstruction

    # Record the various sideways movement instructions.
    for i in range(steps.size()):
        step = steps[i]
        input_key = "move_left" if step.horizontal_acceleration_sign < 0 else "move_right"
        press = PlayerInstruction.new(input_key, step.time_instruction_start, true)
        release = PlayerInstruction.new(input_key, \
                step.time_instruction_end + MOVE_SIDEWAYS_DURATION_INCREASE_EPSILON, false)
        instructions[i * 2] = press
        instructions[i * 2 + 1] = release
        
        # Keep track of some info for edge annotation debugging.
        constraint_positions.push_back(step.position_step_end)
    
    # Record the jump instruction.
    if includes_jump:
        input_key = "jump"
        press = PlayerInstruction.new(input_key, vertical_step.time_instruction_start, true)
        release = PlayerInstruction.new(input_key, \
                vertical_step.time_instruction_end + JUMP_DURATION_INCREASE_EPSILON, false)
        instructions.push_front(release)
        instructions.push_front(press)
    
    return PlayerInstructions.new(instructions, vertical_step.time_step_end, distance_squared, \
            constraint_positions)

# Test that the given instructions were created correctly.
static func test_instructions(instructions: PlayerInstructions, \
        global_calc_params: MovementCalcGlobalParams, calc_results: MovementCalcResults) -> bool:
    assert(instructions.instructions.size() > 0)
    assert(instructions.instructions.size() % 2 == 0)
    
    assert(instructions.instructions[0].time == 0.0)
    
    # FIXME: B: REMOVE
    global_calc_params.movement_params.gravity_fast_fall /= \
            GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    global_calc_params.movement_params.gravity_slow_ascent /= \
            GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    
    var collision := CollisionCheckUtils.check_instructions_for_collision(global_calc_params, \
            instructions, calc_results.vertical_step, calc_results.horizontal_steps)
    assert(collision == null or \
            collision.surface == global_calc_params.destination_constraint.surface)
    var final_frame_position := \
            instructions.frame_discrete_positions[instructions.frame_discrete_positions.size() - 1]
    # FIXME: B: Add back in after fixing the use of GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION.
#    assert(final_frame_position.distance_squared_to( \
#            global_calc_params.destination_constraint.position) < \
#            VALID_END_POSITION_DISTANCE_SQUARED_THRESHOLD)

    # FIXME: B: REMOVE
    global_calc_params.movement_params.gravity_fast_fall *= \
            GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    global_calc_params.movement_params.gravity_slow_ascent *= \
            GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    
    return true
