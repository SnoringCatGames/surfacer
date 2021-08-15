class_name MatchExpectedEdgeTrajectoryAction
extends CharacterActionHandler


const NAME := "MatchExpectedEdgeTrajectoryAction"
const TYPE := SurfaceType.OTHER
const USES_RUNTIME_PHYSICS := false
const PRIORITY := 10010


func _init().(
        NAME,
        TYPE,
        USES_RUNTIME_PHYSICS,
        PRIORITY) -> void:
    pass


func process(character) -> bool:
    var current_edge: Edge = character.navigator.edge
    if current_edge != null:
        var playback: InstructionsPlayback = character.navigator.playback
        var playback_previous_elapsed_time: float = \
                playback.get_previous_elapsed_time_scaled()
        var playback_elapsed_time: float = playback.get_elapsed_time_scaled()
        
        # Don't re-sync if we already synced for the current index.
        if !_get_has_trajectory_index_changed(
                    playback_previous_elapsed_time,
                    playback_elapsed_time) and \
                playback_elapsed_time != 0:
            return false
        
        var synced_positions := false
        if character.movement_params.syncs_character_position_to_edge_trajectory:
            var position := \
                    current_edge.get_position_at_time(playback_elapsed_time)
            var is_movement_beyond_expected_trajectory := \
                    position == Vector2.INF
            if !is_movement_beyond_expected_trajectory:
                character.set_position(position)
                synced_positions = true
        
        var synced_velocities := false
        if character.movement_params.syncs_character_velocity_to_edge_trajectory:
            var velocity := \
                    current_edge.get_velocity_at_time(playback_elapsed_time)
            var is_movement_beyond_expected_trajectory := \
                    velocity == Vector2.INF
            if !is_movement_beyond_expected_trajectory:
                character.velocity = velocity
                synced_velocities = true
        
        return synced_positions or synced_velocities
    
    return false


static func _get_has_trajectory_index_changed(
        previous_time: float,
        next_time: float) -> bool:
    return int(previous_time / Time.PHYSICS_TIME_STEP) != \
            int(next_time / Time.PHYSICS_TIME_STEP)
