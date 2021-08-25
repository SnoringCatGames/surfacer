class_name EdgeInstructionsUtils
extends Reference
# A collection of utility functions for calculating state related to
# EdgeInstructions.


# FIXME:
# - Should I remove this and force a slightly higher offset to target jump
#   position directly? What about passing through waypoints? Would the
#   increased time to get to the position for a wall-top waypoint result in
#   too much downward velocity into the ceiling?
# - Or what about the waypoint offset margins? Shouldn't those actually
#   address any needed jump-height epsilon? Is this needlessly redundant with
#   that mechanism?
# - Though I may need to always at least have _some_ small value here...
# FIXME: Tweak this.
const JUMP_DURATION_INCREASE_EPSILON := Time.PHYSICS_TIME_STEP * 0.5
const MOVE_SIDEWAYS_DURATION_INCREASE_EPSILON := \
        Time.PHYSICS_TIME_STEP * 2.5


# Translates movement data from a form that is more useful when calculating
# the movement to a form that is more useful when executing the movement.
static func convert_calculation_steps_to_movement_instructions(
        records_profile_or_edge_result_metadata,
        collision_params: CollisionCalcParams,
        calc_result: EdgeCalcResult,
        includes_jump: bool,
        destination_side: int) -> EdgeInstructions:
    Sc.profiler.start(
            "convert_calculation_steps_to_movement_instructions",
            collision_params.thread_id)
    
    var steps := calc_result.horizontal_steps
    var vertical_step := calc_result.vertical_step
    
    var vertical_step_duration := \
            vertical_step.time_step_end - vertical_step.time_step_start
    var duration := \
            min(vertical_step_duration, calc_result.collision_time) if \
            !is_inf(calc_result.collision_time) else \
            vertical_step_duration
    
    var instructions := []
    instructions.resize(steps.size() * 2)
    
    # Record the various sideways movement instructions.
    for i in steps.size():
        var step: EdgeStep = steps[i]
        var input_key := \
                "ml" if \
                step.horizontal_acceleration_sign < 0 else \
                "mr"
        var time_instruction_end := \
                step.time_instruction_end + \
                MOVE_SIDEWAYS_DURATION_INCREASE_EPSILON
        if i + 1 < steps.size():
            # Ensure that the boosted end time doesn't exceed the following
            # start time.
            time_instruction_end = max(
                    min(
                            time_instruction_end,
                            steps[i + 1].time_instruction_start - 0.0001),
                    0.0)
        var press := EdgeInstruction.new(
                input_key,
                step.time_instruction_start,
                true)
        var release := EdgeInstruction.new(
                input_key,
                time_instruction_end,
                false)
        instructions[i * 2] = press
        instructions[i * 2 + 1] = release
        
        assert(press.time >= -0.0001 and release.time >= press.time)
        press.time = max(press.time, 0.0)
        release.time = max(release.time, 0.0)
    
    # Record the jump instruction.
    if includes_jump:
        var input_key := "j"
        var press := EdgeInstruction.new(
                input_key,
                vertical_step.time_instruction_start,
                true)
        var jump_end_time := min(
                vertical_step.time_instruction_end + \
                JUMP_DURATION_INCREASE_EPSILON,
                vertical_step.time_step_start + duration)
        var release := EdgeInstruction.new(
                input_key,
                jump_end_time,
                false)
        instructions.push_front(release)
        instructions.push_front(press)
    
    if destination_side == SurfaceSide.LEFT_WALL or \
            destination_side == SurfaceSide.RIGHT_WALL or \
            destination_side == SurfaceSide.CEILING:
        # When landing on a wall or ceiling, we need to press input that
        # ensures we grab on to the surface, but we also need to not do so in a
        # way that changes the trajectory we've carefully calculated (e.g., by
        # pressing sideways).
        
        var last_step: EdgeStep = steps[steps.size() - 1]
        var time_instruction_start := \
                last_step.time_instruction_end + \
                MOVE_SIDEWAYS_DURATION_INCREASE_EPSILON * 2
        # Ensure that the boosted instruction time doesn't exceed the edge end
        # time.
        time_instruction_start = max(
                min(
                        time_instruction_start,
                        vertical_step.time_step_start + \
                                duration - \
                                Time.PHYSICS_TIME_STEP - \
                                0.0001),
                0.0)
        
        var input_key := "g"
        var press := EdgeInstruction.new(
                input_key,
                time_instruction_start,
                true)
        instructions.push_back(press)
        
        if destination_side == SurfaceSide.LEFT_WALL or \
                destination_side == SurfaceSide.RIGHT_WALL:
            input_key = \
                    "fl" if \
                    destination_side == SurfaceSide.LEFT_WALL else \
                    "fr"
            press = EdgeInstruction.new(
                    input_key,
                    time_instruction_start,
                    true)
            instructions.push_back(press)
    
    var instructions_wrapper := EdgeInstructions.new(
            instructions,
            duration)
    
    Sc.profiler.stop_with_optional_metadata(
            "convert_calculation_steps_to_movement_instructions",
            collision_params.thread_id,
            records_profile_or_edge_result_metadata)
    
    return instructions_wrapper


static func sub_instructions(
        base_instructions: EdgeInstructions,
        start_time: float) -> EdgeInstructions:
    # Dictionary<String, EdgeInstruction>
    var active_key_presses := {}
    var start_index := base_instructions.instructions.size()
    
    # Determine what index the start time corresponds to, and what instructions
    # are currently being pressed at that point.
    for index in base_instructions.instructions.size():
        var instruction: EdgeInstruction = \
                        base_instructions.instructions[index]
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
        var instruction := EdgeInstruction.new(
                active_key_press,
                0.0,
                true,
                active_key_presses[active_key_press].position)
        instructions.push_back(instruction)
    
    # Record all remaining instructions.
    var remaining_instructions := []
    var remaining_instructions_size := \
            base_instructions.instructions.size() - start_index
    remaining_instructions.resize(remaining_instructions_size)
    for i in remaining_instructions_size:
        var base_instruction: EdgeInstruction = \
                        base_instructions.instructions[i + start_index]
        remaining_instructions[i] = EdgeInstruction.new(
                base_instruction.input_key,
                base_instruction.time - start_time,
                base_instruction.is_pressed,
                base_instruction.position)
        # FIXME: REMOVE: This shouldn't be needed anymore.
        assert(base_instruction.time - start_time >= 0.0)
    
    Sc.utils.concat(
            instructions,
            remaining_instructions)
    
    var duration := base_instructions.duration - start_time
    
    return EdgeInstructions.new(
            instructions,
            duration)
