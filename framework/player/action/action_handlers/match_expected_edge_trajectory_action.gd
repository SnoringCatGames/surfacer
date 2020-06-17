extends PlayerActionHandler
class_name MatchExpectedEdgeTrajectoryAction

const NAME := "MatchExpectedEdgeTrajectoryAction"
const TYPE := SurfaceType.OTHER
const PRIORITY := 10010

func _init().( \
        NAME, \
        TYPE, \
        PRIORITY) -> void:
    pass

func process(player: Player) -> bool:
    var current_edge := player.navigator.current_edge
    if current_edge != null and current_edge.includes_air_trajectory:
        var playback_elapsed_time: float = \
                Time.elapsed_play_time_sec - \
                player.navigator.current_playback.start_time        
        var trajectory_velocities := \
                current_edge.trajectory.frame_continuous_velocities_from_steps
        var velocity_index := \
                floor(playback_elapsed_time / Time.PHYSICS_TIME_STEP_SEC)
        var is_movement_beyond_expected_trajectory := \
                velocity_index >= trajectory_velocities.size()
        
        if !is_movement_beyond_expected_trajectory:
            player.velocity = trajectory_velocities[velocity_index]
            return true
    
    return false
