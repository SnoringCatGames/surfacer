class_name EdgeTrajectory
extends Reference


# The positions of each frame of movement according to the discrete per-frame
# movement calculations of the instruction test. This is used for annotation
# debugging.
# 
# - This is rendered by the annotator as the _lighter_ path.
# - This more accurately reflects actual run-time movement.
var frame_discrete_positions_from_test: PoolVector2Array

# The positions of each frame of movement according to the continous per-frame
# movement calculations of the underlying horizontal step calculations.
# 
# - This is rendered by the annotator as the _darker_ path.
# - This less accurately reflects actual run-time movement.
var frame_continuous_positions_from_steps: PoolVector2Array

# The velocities of each frame of movement according to the continous per-frame
# movement calculations of the underlying horizontal step calculations.
var frame_continuous_velocities_from_steps: PoolVector2Array

# The end positions of each EdgeStep. These correspond to
# intermediate-surface waypoints and the destination position. This is used for
# annotation debugging.
# Array<Vector2>
var waypoint_positions: Array

# Array<EdgeInstruction>
var horizontal_instructions: Array

var jump_instruction_end: EdgeInstruction

var distance_from_continuous_trajectory: float

var collided_early: bool

var position_duplication_start_index: int

var skipped_duplicated_positions: bool setget ,_get_skipped_duplicated_positions


func _init(frame_continuous_positions_from_steps := PoolVector2Array(),
            frame_continuous_velocities_from_steps := PoolVector2Array(),
            waypoint_positions := [],
            distance_from_continuous_trajectory := INF) -> void:
    self.frame_continuous_positions_from_steps = \
            frame_continuous_positions_from_steps
    self.frame_continuous_velocities_from_steps = \
            frame_continuous_velocities_from_steps
    self.waypoint_positions = waypoint_positions
    self.distance_from_continuous_trajectory = \
            distance_from_continuous_trajectory
    self.collided_early = false
    self.position_duplication_start_index = -1


func _get_skipped_duplicated_positions() -> bool:
    return position_duplication_start_index >= 0


func load_from_json_object(
        json_object: Dictionary,
        context: Dictionary) -> void:
    if json_object.has("d"):
        frame_discrete_positions_from_test = \
                Sc.json.decode_vector2_array(json_object.d)
    if json_object.has("p"):
        frame_continuous_positions_from_steps = \
                Sc.json.decode_vector2_array(json_object.p)
    if json_object.has("v"):
        frame_continuous_velocities_from_steps = \
                Sc.json.decode_vector2_array(json_object.v)
    if json_object.has("w"):
        waypoint_positions = Sc.json.decode_vector2_array(json_object.w)
    if json_object.has("h"):
        horizontal_instructions = _load_horizontal_instructions_json_array(
                json_object.h, context)
    if json_object.has("j"):
        jump_instruction_end = EdgeInstruction.new()
        jump_instruction_end.load_from_json_object(json_object.j, context)
    if json_object.has("c"):
        collided_early = json_object.c
    if json_object.has("s"):
        skipped_duplicated_positions = json_object.c
    distance_from_continuous_trajectory = json_object.f


func _load_horizontal_instructions_json_array(
        json_object: Array,
        context: Dictionary) -> Array:
    var result := []
    result.resize(json_object.size())
    for i in json_object.size():
        var instruction := EdgeInstruction.new()
        instruction.load_from_json_object(json_object[i], context)
        result[i] = instruction
    return result


func to_json_object() -> Dictionary:
    var json_object := {
        f = distance_from_continuous_trajectory,
        c = collided_early,
        s = skipped_duplicated_positions,
    }
    if !frame_discrete_positions_from_test.empty():
        json_object.d = Sc.json.encode_vector2_array(
                frame_discrete_positions_from_test)
    if !frame_continuous_positions_from_steps.empty():
        json_object.p = Sc.json.encode_vector2_array(
                frame_continuous_positions_from_steps)
    if !frame_continuous_velocities_from_steps.empty():
        json_object.v = Sc.json.encode_vector2_array(
                frame_continuous_velocities_from_steps)
    if !waypoint_positions.empty():
        json_object.w = Sc.json.encode_vector2_array(waypoint_positions)
    var horizontal_instructions_json_object := \
            _get_horizontal_instructions_json_array()
    if !horizontal_instructions_json_object.empty():
        json_object.h = horizontal_instructions_json_object
    if jump_instruction_end != null:
        json_object.j = jump_instruction_end.to_json_object()
    return json_object


func _get_horizontal_instructions_json_array() -> Array:
    var result := []
    result.resize(horizontal_instructions.size())
    for i in horizontal_instructions.size():
        result[i] = horizontal_instructions[i].to_json_object()
    return result
