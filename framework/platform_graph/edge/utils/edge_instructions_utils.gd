# A collection of utility functions for calculating state related to
# EdgeInstructions.
extends Reference
class_name EdgeInstructionsUtils

# FIXME: B
# - Should I remove this and force a slightly higher offset to target jump
#   position directly? What about passing through waypoints? Would the
#   increased time to get to the position for a wall-top waypoint result in too
#   much downward velocity into the ceiling?
# - Or what about the waypoint offset margins? Shouldn't those actually address
#   any needed jump-height epsilon? Is this needlessly redundant with that
#   mechanism?
# - Though I may need to always at least have _some_ small value here...
# FIXME: D Tweak this.
const JUMP_DURATION_INCREASE_EPSILON := Time.PHYSICS_TIME_STEP_SEC * 0.5
const MOVE_SIDEWAYS_DURATION_INCREASE_EPSILON := \
        Time.PHYSICS_TIME_STEP_SEC * 2.5

# Translates movement data from a form that is more useful when calculating the
# movement to a form that is more useful when executing the movement.
static func convert_calculation_steps_to_movement_instructions( \
        records_profile_or_edge_result_metadata, \
        collision_params: CollisionCalcParams, \
        calc_result: EdgeCalcResult, \
        includes_jump: bool, \
        destination_side: int) -> EdgeInstructions:
    Profiler.start( \
            ProfilerMetric \
                    .CONVERT_CALCULATION_STEPS_TO_MOVEMENT_INSTRUCTIONS, \
            collision_params.thread_id)
    
    var steps := calc_result.horizontal_steps
    var vertical_step := calc_result.vertical_step
    
    var instructions := []
    instructions.resize(steps.size() * 2)
    
    var step: EdgeStep
    var input_key: String
    var time_instruction_end: float
    var press: EdgeInstruction
    var release: EdgeInstruction

    # Record the various sideways movement instructions.
    for i in range(steps.size()):
        step = steps[i]
        input_key = \
                "move_left" if \
                step.horizontal_acceleration_sign < 0 else \
                "move_right"
        time_instruction_end = \
                step.time_instruction_end + \
                MOVE_SIDEWAYS_DURATION_INCREASE_EPSILON
        if i + 1 < steps.size():
            # Ensure that the boosted end time doesn't exceed the following
            # start time.
            time_instruction_end = max( \
                    min( \
                            time_instruction_end, \
                            steps[i + 1].time_instruction_start - 0.0001), \
                    0.0)
        press = EdgeInstruction.new( \
                input_key, \
                step.time_instruction_start, \
                true)
        release = EdgeInstruction.new( \
                input_key, \
                time_instruction_end, \
                false)
        instructions[i * 2] = press
        instructions[i * 2 + 1] = release
        # FIXME: REMOVE: This shouldn't be needed anymore.
        assert(press.time >= 0.0 and release.time >= press.time)
    
    # Record the jump instruction.
    if includes_jump:
        input_key = "jump"
        press = EdgeInstruction.new( \
                input_key, \
                vertical_step.time_instruction_start, \
                true)
        release = EdgeInstruction.new( \
                input_key, \
                vertical_step.time_instruction_end + \
                        JUMP_DURATION_INCREASE_EPSILON, \
                false)
        instructions.push_front(release)
        instructions.push_front(press)
    
    if destination_side == SurfaceSide.LEFT_WALL or \
            destination_side == SurfaceSide.RIGHT_WALL:
        # When landing on a wall, we need to press input that ensures we grab
        # on to the wall, but we also need to not do so in a way that changes
        # the trajectory we've carefully calculated.
        
        var last_step: EdgeStep = steps[steps.size() - 1]
        var time_step_start := last_step.time_instruction_end + \
                MOVE_SIDEWAYS_DURATION_INCREASE_EPSILON * 2
        
        input_key = "grab_wall"
        press = EdgeInstruction.new( \
                input_key, \
                time_step_start, \
                true)
        instructions.push_back(press)
        
        input_key = \
                "face_left" if \
                destination_side == SurfaceSide.LEFT_WALL else \
                "face_right"
        press = EdgeInstruction.new( \
                input_key, \
                time_step_start, \
                true)
        instructions.push_back(press)
    
    var duration := vertical_step.time_step_end - vertical_step.time_step_start
    
    var instructions_wrapper := EdgeInstructions.new( \
            instructions, \
            duration)
    
    Profiler.stop_with_optional_metadata( \
            ProfilerMetric \
                    .CONVERT_CALCULATION_STEPS_TO_MOVEMENT_INSTRUCTIONS, \
            collision_params.thread_id, \
            records_profile_or_edge_result_metadata)
    
    return instructions_wrapper

static func sub_instructions( \
        base_instructions: EdgeInstructions, \
        start_time: float) -> EdgeInstructions:
    # Dictionary<String, EdgeInstruction>
    var active_key_presses := {}
    var start_index := base_instructions.instructions.size()
    var instruction: EdgeInstruction
    
    # Determine what index the start time corresponds to, and what instructions
    # are currently being pressed at that point.
    for index in range(base_instructions.instructions.size()):
        instruction = base_instructions.instructions[index]
        if instruction.time >= start_time:
            start_index = index
            break
        if instruction.is_pressed:
            active_key_presses[instruction.input_key] = instruction
        else:
            active_key_presses.erase(instruction.input_key)
    
    # Record any already-active instructions.
    var instructions := []
    for active_key_press in active_key_presses:
        instruction = EdgeInstruction.new( \
                active_key_press, \
                0.0, \
                true, \
                active_key_presses[active_key_press].position)
        instructions.push_back(instruction)
    
    # Record all remaining instructions.
    var remaining_instructions := []
    var remaining_instructions_size := \
            base_instructions.instructions.size() - start_index
    remaining_instructions.resize(remaining_instructions_size)
    var base_instruction: EdgeInstruction
    for i in range(remaining_instructions_size):
        base_instruction = base_instructions.instructions[i + start_index]
        remaining_instructions[i] = EdgeInstruction.new( \
                base_instruction.input_key, \
                base_instruction.time - start_time, \
                base_instruction.is_pressed, \
                base_instruction.position)
        # FIXME: REMOVE: This shouldn't be needed anymore.
        assert(base_instruction.time - start_time >= 0.0)
    
    Utils.concat( \
            instructions, \
            remaining_instructions)
    
    var duration := base_instructions.duration - start_time
    
    return EdgeInstructions.new( \
            instructions, \
            duration)
