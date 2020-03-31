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
    # FIXME: LEFT OFF HERE: ----------------------------------------A:
    # - Add something to Edge that makes it queryable as to whether the edge includes trajectory
    #   position/velocity info (rather than hard-coding class instance checks here).
    var current_edge := player.navigator.current_edge
    if current_edge is AirToAirEdge or \
            current_edge is AirToSurfaceEdge or \
            current_edge is FallFromFloorEdge or \
            current_edge is FallFromWallEdge or \
            current_edge is JumpInterSurfaceEdge or \
            current_edge is JumpFromSurfaceToAirEdge:
        var playback_elapsed_time: float = \
                player.global.elapsed_play_time_sec - player.navigator.current_playback.start_time        
        var trajectory_velocities := \
                current_edge.trajectory.frame_continuous_velocities_from_steps
        var velocity_index := floor(playback_elapsed_time / Utils.PHYSICS_TIME_STEP)
        var is_movement_beyond_expected_trajectory := \
                velocity_index >= trajectory_velocities.size()
        
        if !is_movement_beyond_expected_trajectory:
            player.velocity = trajectory_velocities[velocity_index]
            return true
    
    return false
