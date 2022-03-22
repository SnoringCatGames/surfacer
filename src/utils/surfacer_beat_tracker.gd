tool
class_name SurfacerBeatTracker
extends BeatTracker


func calculate_path_beat_hashes_for_current_mode(
        path: PlatformGraphPath,
        path_start_time_scaled: float) -> Array:
    if !is_tracking_beat:
        return []
    
    var elapsed_path_time: float = \
            Sc.time.get_scaled_play_time() - path_start_time_scaled
    
    if Sc.slow_motion.get_is_enabled_or_transitioning():
        return calculate_path_beat_hashes(
                path,
                elapsed_path_time,
                Sc.slow_motion.music.time_to_next_music_beat,
                Sc.slow_motion.music.next_music_beat_index,
                Sc.slow_motion.music.music_beat_duration_unscaled,
                Sc.slow_motion.music.meter)
    else:
        return calculate_path_beat_hashes(
                path,
                elapsed_path_time,
                time_to_next_beat,
                next_beat_index,
                get_beat_duration_unscaled(),
                get_meter())


static func calculate_path_beat_hashes(
        path: PlatformGraphPath,
        elapsed_path_time: float,
        time_to_next_beat: float,
        next_beat_index: int,
        beat_duration: float,
        meter: int) -> Array:
    var time_from_path_start_to_next_beat := \
            time_to_next_beat + elapsed_path_time
    
    time_to_next_beat = fmod(
            time_from_path_start_to_next_beat,
            beat_duration)
    next_beat_index -= \
            int(time_from_path_start_to_next_beat / beat_duration)
    
    var path_time_of_next_beat := time_to_next_beat
    var edge_start_time := 0.0
    
    var beat_count := int(max(
            floor((path.duration - time_to_next_beat) / beat_duration) + 1,
            0))
    var hash_index := 0
    var hashes := []
    hashes.resize(beat_count)
    
    for edge in path.edges:
        var edge_end_time: float = edge_start_time + edge.duration
        
        while edge_end_time >= path_time_of_next_beat:
            var position_before: Vector2
            var position_after: Vector2
            var weight: float
            if edge.trajectory != null:
                var edge_vertices: PoolVector2Array = \
                        Sc.draw._get_edge_trajectory_vertices(
                                edge, false)
                var index_before_hash := \
                        int((path_time_of_next_beat - edge_start_time) / \
                                ScaffolderTime.PHYSICS_TIME_STEP)
                if index_before_hash < edge_vertices.size() - 1:
                    var time_of_index_before := \
                            edge_start_time + \
                            index_before_hash * ScaffolderTime.PHYSICS_TIME_STEP
                    position_before = edge_vertices[index_before_hash]
                    position_after = edge_vertices[index_before_hash + 1]
                    weight = \
                            (path_time_of_next_beat - time_of_index_before) / \
                            ScaffolderTime.PHYSICS_TIME_STEP
                else:
                    position_before = edge_vertices[edge_vertices.size() - 1]
                    position_after = position_before
                    weight = 1.0
            else:
                position_before = edge.get_start()
                position_after = edge.get_end()
                weight = \
                        (path_time_of_next_beat - edge_start_time) / \
                        edge.duration
            
            var position: Vector2 = lerp(
                    position_before,
                    position_after,
                    weight)
            var direction: Vector2 = \
                    (position_after - position_before).normalized()
            var is_downbeat := next_beat_index % meter == 0
            
            hashes[hash_index] = PathBeatPrediction.new(
                    path_time_of_next_beat,
                    position,
                    direction,
                    is_downbeat)
            
            path_time_of_next_beat += beat_duration
            next_beat_index += 1
            hash_index += 1
        
        edge_start_time = edge_end_time
    
    assert(hash_index == hashes.size())
    return hashes
