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
    if current_edge != null:
        var playback_elapsed_time: float = \
                Gs.time.elapsed_play_time_actual_sec - \
                player.navigator.current_playback.start_time
        
        var synced_positions := false
        if player.movement_params.syncs_player_position_to_edge_trajectory:
            var position := \
                    current_edge.get_position_at_time(playback_elapsed_time)
            var is_movement_beyond_expected_trajectory := \
                    position == Vector2.INF
            if !is_movement_beyond_expected_trajectory:
                player.position = position
                synced_positions = true
        
        var synced_velocities := false
        if player.movement_params.syncs_player_velocity_to_edge_trajectory:
            var velocity := \
                    current_edge.get_velocity_at_time(playback_elapsed_time)
            var is_movement_beyond_expected_trajectory := \
                    velocity == Vector2.INF
            if !is_movement_beyond_expected_trajectory:
                player.velocity = velocity
                synced_velocities = true
        
        return synced_positions or synced_velocities
    
    return false
