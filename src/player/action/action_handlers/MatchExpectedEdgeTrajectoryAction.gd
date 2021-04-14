class_name MatchExpectedEdgeTrajectoryAction
extends PlayerActionHandler

const NAME := "MatchExpectedEdgeTrajectoryAction"
const TYPE := SurfaceType.OTHER
const PRIORITY := 10010

func _init().(
        NAME,
        TYPE,
        PRIORITY) -> void:
    pass

func process(player: Player) -> bool:
    var current_edge := player.navigator.current_edge
    if current_edge != null and current_edge.includes_air_trajectory:
        var playback_elapsed_time: float = \
                Gs.time.elapsed_play_time_actual_sec - \
                player.navigator.current_playback.start_time
        var index := floor(playback_elapsed_time / Time.PHYSICS_TIME_STEP_SEC)
        var trajectory_positions := current_edge.trajectory \
                .frame_continuous_positions_from_steps
        var trajectory_velocities := current_edge.trajectory \
                .frame_continuous_velocities_from_steps
        var is_movement_beyond_expected_trajectory := \
                index >= trajectory_positions.size()
        
        var synced_positions := false
        var synced_velocities := false
        
        if !is_movement_beyond_expected_trajectory:
            if player.movement_params.syncs_player_position_to_edge_trajectory:
                    player.position = trajectory_positions[index]
                    synced_positions = true
            
            if player.movement_params.syncs_player_velocity_to_edge_trajectory:
                    player.velocity = trajectory_velocities[index]
                    synced_velocities = true
        
        return synced_positions or synced_velocities
    
    return false
