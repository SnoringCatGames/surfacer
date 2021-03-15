extends Reference
class_name EdgeTrajectory

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
var waypoint_positions: Array

var horizontal_instructions: Array

var jump_instruction_end: EdgeInstruction

var distance_from_continuous_frames: float

func _init(frame_continuous_positions_from_steps: PoolVector2Array, \
            frame_continuous_velocities_from_steps: PoolVector2Array, \
            waypoint_positions: Array,
            distance_from_continuous_frames: float) -> void:
    self.frame_continuous_positions_from_steps = \
            frame_continuous_positions_from_steps
    self.frame_continuous_velocities_from_steps = \
            frame_continuous_velocities_from_steps
    self.waypoint_positions = waypoint_positions
    self.distance_from_continuous_frames = distance_from_continuous_frames
