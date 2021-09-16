class_name PathPreselectionAnnotator
extends Node2D


# TODO: Move predictions out into a separate annotator.
var _predictions_container: Node2D

var character: SurfacerCharacter
var player_nav: PlayerNavigationBehavior
var surface_color: Color
var indicator_color: Color
var path_color: Color
var hash_color: Color

var path_front_end_trim_radius: float
var preselection_destination: PositionAlongSurface = null
var animation_start_time: float = -Sc.ann_params.preselection_default_duration
var animation_progress := 1.0
var phantom_surface := Surface.new(
        [Vector2.INF],
        SurfaceSide.NONE,
        null,
        [])
var phantom_surface_cw_neighbor := Surface.new(
        [Vector2.INF],
        SurfaceSide.NONE,
        null,
        [])
var phantom_surface_ccw_neighbor := Surface.new(
        [Vector2.INF],
        SurfaceSide.NONE,
        null,
        [])
var phantom_position_along_surface := PositionAlongSurface.new()
var preselection_path: PlatformGraphPath
var preselection_path_beats_time_start: float
var preselection_path_beats: Array


func _init(character: SurfacerCharacter) -> void:
    self.character = character
    self.player_nav = character.get_behavior(PlayerNavigationBehavior)
    
    phantom_surface.clockwise_convex_neighbor = \
            phantom_surface_cw_neighbor
    phantom_surface.counter_clockwise_convex_neighbor = \
            phantom_surface_ccw_neighbor
    
    surface_color = Sc.colors.opacify(
            character.navigation_annotation_color,
            Sc.ann_params.preselection_surface_opacity)
    indicator_color = Sc.colors.opacify(
            character.navigation_annotation_color,
            Sc.ann_params.preselection_indicator_opacity)
    path_color = Sc.colors.opacify(
            character.navigation_annotation_color,
            Sc.ann_params.preselection_path_opacity)
    hash_color = Sc.colors.opacify(
            character.navigation_annotation_color,
            Sc.ann_params.preselection_hash_opacity)
    
    self.path_front_end_trim_radius = min(
            character.movement_params.collider_half_width_height.x,
            character.movement_params.collider_half_width_height.y)
    
    self._predictions_container = Node2D.new()
    _predictions_container.visible = false
    _predictions_container.modulate.a = \
            Su.ann_manifest.nav_selection_prediction_opacity
    add_child(_predictions_container)
    
    Sc.slow_motion.connect(
            "slow_motion_toggled", self, "_on_slow_motion_toggled")
    Sc.slow_motion.music.connect(
            "tick_tock_beat", self, "_on_slow_motion_tick_tock_beat")


func _on_slow_motion_toggled(is_enabled: bool) -> void:
    animation_start_time = -Sc.ann_params.preselection_default_duration


func _on_slow_motion_tick_tock_beat(
        is_downbeat: bool,
        beat_index: int,
        meter: int) -> void:
    if is_downbeat or \
            animation_start_time < 0:
        animation_start_time = Sc.time.get_play_time()


func add_prediction(prediction: CharacterPrediction) -> void:
    _predictions_container.add_child(prediction)


func _process(_delta: float) -> void:
    var current_time: float = Sc.time.get_play_time()
    
    var did_preselection_change := \
            preselection_destination != \
                    player_nav.pre_selection.navigation_destination or \
            preselection_path_beats_time_start != \
                    player_nav.pre_selection.path_beats_time_start
    
    if did_preselection_change and \
            !player_nav.new_selection.get_has_selection():
        var previous_preselection_surface := \
                preselection_destination.surface if \
                preselection_destination != null else \
                null
        var next_preselection_surface := \
                player_nav.pre_selection.navigation_destination.surface if \
                player_nav.pre_selection.get_is_selection_navigable() else \
                null
        var did_preselection_surface_change := \
                previous_preselection_surface != next_preselection_surface
        
        preselection_destination = \
                player_nav.pre_selection.navigation_destination
        preselection_path = player_nav.pre_selection.path
        preselection_path_beats_time_start = \
                player_nav.pre_selection.path_beats_time_start
        preselection_path_beats = player_nav.pre_selection.path_beats
        
        if did_preselection_surface_change:
            _update_phantom_surface()
        
        if preselection_destination != null:
            _update_phantom_position_along_surface()
            
            if preselection_path != null:
                # Update the player-character prediction.
                if character is SurfacerCharacter:
                    character.prediction.match_navigator_or_path(
                            preselection_path,
                            preselection_path.duration)
                
                # Update npc predictions.
                for surfacer_character in Sc.utils.get_all_nodes_in_group(
                        Sc.characters.GROUP_NAME_SURFACER_CHARACTERS):
                    if !surfacer_character.is_player_character:
                        surfacer_character.prediction.match_navigator_or_path(
                                surfacer_character.navigator,
                                preselection_path.duration)
        else:
            preselection_path = null
            preselection_path_beats_time_start = INF
            preselection_path_beats = []
        
        _predictions_container.visible = \
                preselection_path != null and \
                Sc.annotators.is_annotator_enabled(AnnotatorType.CHARACTER)
        
        update()
    
    if preselection_destination != null:
        var preselection_duration: float = \
                Sc.slow_motion.music \
                        .tick_tock_beat_duration_unscaled * \
                    Sc.slow_motion.tick_tock_tempo_multiplier * \
                    2.0 if \
                Sc.slow_motion.is_enabled else \
                Sc.ann_params.preselection_default_duration
        animation_progress = fmod((current_time - animation_start_time) / \
                preselection_duration, 1.0)
        update()


func _draw() -> void:
    if preselection_destination == null:
        # When we don't render anything in this draw call, it clears the draw
        # buffer.
        return
    
    var alpha_multiplier: float = ((1 - animation_progress) * \
            (Sc.ann_params.preselection_max_opacity - \
                    Sc.ann_params.preselection_min_opacity) + \
            Sc.ann_params.preselection_min_opacity)
    
    var surface_base_color: Color
    var position_indicator_base_color: Color
    var path_base_color: Color
    var hash_base_color: Color
    if preselection_path != null:
        if character.is_player_character:
            surface_base_color = surface_color
            position_indicator_base_color = indicator_color
            path_base_color = path_color
            hash_base_color = hash_color
        else:
            surface_base_color = surface_color
            position_indicator_base_color = indicator_color
            path_base_color = path_color
            hash_base_color = hash_color
    else:
        surface_base_color = \
                Sc.ann_params.preselection_invalid_surface_color
        position_indicator_base_color = \
                Sc.ann_params.preselection_invalid_position_indicator_color
    
    if Su.ann_manifest.is_player_preselection_trajectory_shown:
        # Draw path.
        if preselection_path != null:
            var path_alpha := \
                    path_base_color.a * alpha_multiplier
            var path_color := Color(
                    path_base_color.r,
                    path_base_color.g,
                    path_base_color.b,
                    path_alpha)
            Sc.draw.draw_path(
                    self,
                    preselection_path,
                    Sc.ann_params.preselection_path_stroke_width,
                    path_color,
                    path_front_end_trim_radius,
                    Sc.ann_params.preselection_path_back_end_trim_radius,
                    false,
                    false,
                    true,
                    false)
            
            var hash_alpha := \
                    hash_base_color.a * alpha_multiplier
            var hash_color := Color(
                    hash_base_color.r,
                    hash_base_color.g,
                    hash_base_color.b,
                    hash_alpha)
            Sc.draw.draw_beat_hashes(
                    self,
                    preselection_path_beats,
                    Sc.ann_params.preselection_path_downbeat_hash_length,
                    Sc.ann_params.preselection_path_offbeat_hash_length,
                    Sc.ann_params.preselection_path_downbeat_stroke_width,
                    Sc.ann_params.preselection_path_offbeat_stroke_width,
                    hash_color,
                    hash_color)
        
        if phantom_surface.side != SurfaceSide.NONE:
            # Draw Surface.
            var surface_alpha := surface_base_color.a * alpha_multiplier
            var surface_color := Color(
                    surface_base_color.r,
                    surface_base_color.g,
                    surface_base_color.b,
                    Sc.ann_params.surface_alpha)
            Sc.draw.draw_surface(
                    self,
                    phantom_surface,
                    surface_color,
                    Sc.ann_params.preselection_surface_depth)
    
    if Su.ann_manifest.is_player_navigation_destination_shown:
        # Draw destination marker.
        var position_indicator_alpha := \
                position_indicator_base_color.a * alpha_multiplier
        var position_indicator_color := Color(
                position_indicator_base_color.r,
                position_indicator_base_color.g,
                position_indicator_base_color.b,
                position_indicator_alpha)
        var cone_length: float = \
                Sc.ann_params.preselection_position_indicator_length - \
                Sc.ann_params.preselection_position_indicator_radius
        Sc.draw.draw_destination_marker(
                self,
                phantom_position_along_surface,
                false,
                position_indicator_color,
                cone_length,
                Sc.ann_params.preselection_position_indicator_radius,
                true,
                INF,
                4.0)


func _update_phantom_surface() -> void:
    if preselection_destination == null or \
            preselection_destination.surface == null:
        phantom_surface.vertices = []
        phantom_surface.side = SurfaceSide.NONE
        phantom_surface.normal = Vector2.INF
        phantom_surface.bounding_box = Rect2()
    else:
        # Copy the vertices from the target surface.
        
        phantom_surface.vertices = preselection_destination.surface.vertices
        phantom_surface.side = preselection_destination.surface.side
        phantom_surface.normal = preselection_destination.surface.normal
        
        # Assign placeholder neighbor surfaces.
        
        var start := phantom_surface.first_point
        var end := phantom_surface.last_point
        var normal := phantom_surface.normal
        
        phantom_surface_ccw_neighbor.vertices = [start - normal, start]
        phantom_surface_cw_neighbor.vertices = [end, end + normal]
        
        # Enlarge and offset the phantom surface, so that it stands out more.
        
        var surface_center := preselection_destination.surface.center
        
        var length := \
                preselection_destination.surface.bounding_box.size.x if \
                preselection_destination.surface.normal.x == 0.0 else \
                preselection_destination.surface.bounding_box.size.y
        # Single-vertex surfaces have zero length.
        length = max(1.0, length)
        var scale_factor: float = \
                (length + \
                Sc.ann_params.preselection_surface_length_padding * 2.0) / \
                length
        var scale := Vector2(scale_factor, scale_factor)
        
        var translation: Vector2 = \
                preselection_destination.surface.normal * \
                Sc.ann_params.preselection_surface_outward_offset
        
        var transform := Transform2D()
        transform = transform.translated(-surface_center)
        transform = transform.scaled(scale)
        transform = transform.translated(translation / scale_factor)
        transform = transform.translated(surface_center / scale_factor)
        
        for i in phantom_surface.vertices.size():
            phantom_surface.vertices[i] = \
                    transform.xform(phantom_surface.vertices[i])
        
        phantom_surface.bounding_box = Sc.geometry.get_bounding_box_for_points(
                phantom_surface.vertices)


func _update_phantom_position_along_surface() -> void:
    if phantom_surface.side != SurfaceSide.NONE:
        phantom_position_along_surface.match_surface_target_and_collider(
                phantom_surface,
                preselection_destination.target_point,
                Vector2.ZERO,
                true,
                true)
    else:
        phantom_position_along_surface.surface = null
        phantom_position_along_surface.target_point = \
                preselection_destination.target_point
        phantom_position_along_surface.target_projection_onto_surface = \
                Vector2.INF
