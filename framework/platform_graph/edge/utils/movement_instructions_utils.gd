# A collection of utility functions for calculating state related to MovementInstructions.
class_name MovementInstructionsUtils

const MovementInstruction := preload("res://framework/platform_graph/edge/calculation_models/movement_instruction.gd")

# FIXME: B 
# - Should I remove this and force a slightly higher offset to target jump position directly? What
#   about passing through waypoints? Would the increased time to get to the position for a
#   wall-top waypoint result in too much downward velocity into the ceiling?
# - Or what about the waypoint offset margins? Shouldn't those actually address any needed
#   jump-height epsilon? Is this needlessly redundant with that mechanism?
# - Though I may need to always at least have _some_ small value here...
# FIXME: D Tweak this.
const JUMP_DURATION_INCREASE_EPSILON := Utils.PHYSICS_TIME_STEP * 0.5
const MOVE_SIDEWAYS_DURATION_INCREASE_EPSILON := Utils.PHYSICS_TIME_STEP * 2.5

# Translates movement data from a form that is more useful when calculating the movement to a form
# that is more useful when executing the movement.
static func convert_calculation_steps_to_movement_instructions( \
        calc_results: MovementCalcResults, \
        includes_jump: bool, \
        destination_side: int) -> MovementInstructions:
    var steps := calc_results.horizontal_steps
    var vertical_step := calc_results.vertical_step
    
    var instructions := []
    instructions.resize(steps.size() * 2)
    
    var step: MovementCalcStep
    var input_key: String
    var time_instruction_end: float
    var press: MovementInstruction
    var release: MovementInstruction

    # Record the various sideways movement instructions.
    for i in range(steps.size()):
        step = steps[i]
        input_key = \
                "move_left" if \
                step.horizontal_acceleration_sign < 0 else \
                "move_right"
        time_instruction_end = \
                step.time_instruction_end + MOVE_SIDEWAYS_DURATION_INCREASE_EPSILON
        if i + 1 < steps.size():
            # Ensure that the boosted end time doesn't exceed the following start time.
            time_instruction_end = min( \
                    time_instruction_end, \
                    steps[i + 1].time_instruction_start - 0.0001)
        press = MovementInstruction.new( \
                input_key, \
                step.time_instruction_start, \
                true)
        release = MovementInstruction.new( \
                input_key, \
                time_instruction_end, \
                false)
        instructions[i * 2] = press
        instructions[i * 2 + 1] = release
    
    # Record the jump instruction.
    if includes_jump:
        input_key = "jump"
        press = MovementInstruction.new( \
                input_key, \
                vertical_step.time_instruction_start, \
                true)
        release = MovementInstruction.new( \
                input_key, \
                vertical_step.time_instruction_end + JUMP_DURATION_INCREASE_EPSILON, \
                false)
        instructions.push_front(release)
        instructions.push_front(press)
    
    if destination_side == SurfaceSide.LEFT_WALL or destination_side == SurfaceSide.RIGHT_WALL:
        # When landing on a wall, we need to press input that ensures we grab on to the wall, but
        # we also need to not do so in a way that changes the trajectory we've carefully
        # calculated.
        
        var last_step: MovementCalcStep = steps[steps.size() - 1]
        var time_step_start := last_step.time_instruction_end + \
                MOVE_SIDEWAYS_DURATION_INCREASE_EPSILON * 2
        
        input_key = "grab_wall"
        press = MovementInstruction.new( \
                input_key, \
                time_step_start, \
                true)
        instructions.push_back(press)
        
        input_key = \
                "face_left" if \
                destination_side == SurfaceSide.LEFT_WALL else \
                "face_right"
        press = MovementInstruction.new( \
                input_key, \
                time_step_start, \
                true)
        instructions.push_back(press)
    
    var duration := vertical_step.time_step_end - vertical_step.time_step_start
    
    return MovementInstructions.new(instructions, duration)
