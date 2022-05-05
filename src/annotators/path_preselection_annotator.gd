class_name PathPreselectionAnnotator
extends Node2D


# TODO: Move predictions out into a separate annotator.
var _predictions_container: Node2D

var last_player_character: SurfacerCharacter
var player_nav: PlayerNavigationBehavior
var surface_color: Color
var indicator_color: Color
var path_color: Color
var hash_color: Color

var did_player_character_change := false

var path_front_end_trim_radius: float
var preselection_destination: PositionAlongSurface = null
var animation_start_time: float
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
var invalid_destination_position := PositionAlongSurface.new()


func _init() -> void:
    self._predictions_container = Node2D.new()
    _predictions_container.visible = false
    add_child(_predictions_container)
    
    Sc.slow_motion.connect(
            "slow_motion_toggled", self, "_on_slow_motion_toggled")
    Sc.slow_motion.music.connect(
            "tick_tock_beat", self, "_on_slow_motion_tick_tock_beat")


func _check_active_player_character() -> void:
    var current_player_character := Sc.characters.get_active_player_character()
    if last_player_character == current_player_character:
        return
    
    self.did_player_character_change = true
    self.last_player_character = current_player_character
    
    self.animation_start_time = \
            -Sc.annotators.params.preselection_default_duration
    
    if is_instance_valid(current_player_character):
        self.player_nav = \
                last_player_character.get_behavior(PlayerNavigationBehavior)
        
        _predictions_container.modulate.a = \
            Sc.annotators.params.nav_selection_prediction_opacity
        
        phantom_surface.clockwise_convex_neighbor = \
                phantom_surface_cw_neighbor
        phantom_surface.counter_clockwise_convex_neighbor = \
                phantom_surface_ccw_neighbor
        
        surface_color = ColorFactory.opacify(
                last_player_character.navigation_annotation_color,
                Sc.annotators.params.preselection_surface_opacity).sample()
        indicator_color = ColorFactory.opacify(
                last_player_character.navigation_annotation_color,
                Sc.annotators.params.preselection_indicator_opacity).sample()
        path_color = ColorFactory.opacify(
                last_player_character.navigation_annotation_color,
                Sc.annotators.params.preselection_path_opacity).sample()
        hash_color = ColorFactory.opacify(
                last_player_character.navigation_annotation_color,
                Sc.annotators.params.preselection_hash_opacity).sample()
        
        self.path_front_end_trim_radius = min(
                last_player_character.collider.half_width_height.x,
                last_player_character.collider.half_width_height.y)
    else:
        self.player_nav = null
        _predictions_container.modulate.a = 0.0


func _on_slow_motion_toggled(is_enabled: bool) -> void:
    animation_start_time = -Sc.annotators.params.preselection_default_duration


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
    
    _check_active_player_character()
    if did_player_character_change:
        update()
    if !is_instance_valid(last_player_character):
        return
    
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
                for character in Sc.utils.get_all_nodes_in_group(
                        Sc.characters.GROUP_NAME_CHARACTERS):
                    if character.is_player_control_active:
                        character.prediction.match_navigator_or_path(
                                preselection_path,
                                preselection_path.duration)
                    else:
                        character.prediction.match_navigator_or_path(
                                character.navigator,
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
        _update_animation_progress()
        update()
    
    if !player_nav.pre_selection.get_is_selection_navigable() and \
            !player_nav.new_selection.get_has_selection() and \
            last_player_character.touch_listener.get_is_drag_active():
        if Sc.level.touch_listener \
                    .current_drag_level_position_with_current_camera_pan != \
                invalid_destination_position.target_point:
            update()
        invalid_destination_position.target_point = Sc.level.touch_listener \
                .current_drag_level_position_with_current_camera_pan
        _update_animation_progress()
    else:
        invalid_destination_position.target_point = Vector2.INF


func _update_animation_progress() -> void:
    var preselection_duration: float = \
            Sc.slow_motion.music \
                    .tick_tock_beat_duration_unscaled * \
                Sc.slow_motion.tick_tock_tempo_multiplier * \
                2.0 if \
            Sc.slow_motion.is_enabled else \
            Sc.annotators.params.preselection_default_duration
    animation_progress = \
            fmod((Sc.time.get_play_time() - animation_start_time) / \
            preselection_duration, 1.0)


func _draw() -> void:
    if !is_instance_valid(last_player_character) or \
            !last_player_character.touch_listener.get_is_drag_active():
        # When we don't render anything in this draw call, it clears the draw
        # buffer.
        return
    
    var alpha_multiplier: float = ((1 - animation_progress) * \
            (Sc.annotators.params.preselection_max_opacity - \
                    Sc.annotators.params.preselection_min_opacity) + \
            Sc.annotators.params.preselection_min_opacity)
    
    var surface_base_color: Color
    var position_indicator_base_color: Color
    var path_base_color: Color
    var hash_base_color: Color
    if preselection_path != null:
        surface_base_color = surface_color
        position_indicator_base_color = indicator_color
        path_base_color = path_color
        hash_base_color = hash_color
    else:
        surface_base_color = \
                Sc.palette.get_color("preselection_invalid_surface_color")
        position_indicator_base_color = Sc.palette.get_color(
                "preselection_invalid_position_indicator_color")
    
    if preselection_destination != null and \
            Sc.annotators.params.is_player_preselection_trajectory_shown:
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
                    Sc.annotators.params.preselection_path_stroke_width,
                    path_color,
                    path_front_end_trim_radius,
                    Sc.annotators.params.preselection_path_back_end_trim_radius,
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
                    Sc.annotators.params.preselection_path_downbeat_hash_length,
                    Sc.annotators.params.preselection_path_offbeat_hash_length,
                    Sc.annotators.params.preselection_path_downbeat_stroke_width,
                    Sc.annotators.params.preselection_path_offbeat_stroke_width,
                    hash_color,
                    hash_color)
        
        if phantom_surface.side != SurfaceSide.NONE:
            # Draw Surface.
            var surface_alpha := surface_base_color.a * alpha_multiplier
            var surface_color := Color(
                    surface_base_color.r,
                    surface_base_color.g,
                    surface_base_color.b,
                    Sc.annotators.params.surface_alpha)
            Sc.draw.draw_surface(
                    self,
                    phantom_surface,
                    surface_color,
                    Sc.annotators.params.preselection_surface_depth)
    
    if Sc.annotators.params.is_player_navigation_destination_shown:
        # Draw destination marker.
        var position_indicator_alpha := \
                position_indicator_base_color.a * alpha_multiplier
        var position_indicator_color := Color(
                position_indicator_base_color.r,
                position_indicator_base_color.g,
                position_indicator_base_color.b,
                position_indicator_alpha)
        var cone_length: float = \
                Sc.annotators.params.preselection_position_indicator_length - \
                Sc.annotators.params.preselection_position_indicator_radius
        var position_along_surface := \
                phantom_position_along_surface if \
                preselection_destination != null else \
                invalid_destination_position
        Sc.draw.draw_destination_marker(
                self,
                position_along_surface,
                false,
                position_indicator_color,
                cone_length,
                Sc.annotators.params.preselection_position_indicator_radius,
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
        var enlarged_normal := phantom_surface.normal * 1000
        
        var preceding_neighbor_vertices := \
                preselection_destination.surface.counter_clockwise_neighbor \
                        .vertices if \
                preselection_destination.surface.counter_clockwise_neighbor \
                        .vertices.size() > 1 else \
                preselection_destination.surface.counter_clockwise_neighbor \
                        .counter_clockwise_neighbor.vertices
        var following_neighbor_vertices := \
                preselection_destination.surface.clockwise_neighbor \
                        .vertices if \
                preselection_destination.surface.clockwise_neighbor \
                        .vertices.size() > 1 else \
                preselection_destination.surface.clockwise_neighbor \
                        .clockwise_neighbor.vertices
        var preceding_point := preceding_neighbor_vertices[ \
                preceding_neighbor_vertices.size() - 2]
        var following_point := following_neighbor_vertices[1]
        
        phantom_surface_ccw_neighbor.vertices = [preceding_point, start]
        phantom_surface_cw_neighbor.vertices = [end, following_point]
        
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
                Sc.annotators.params.preselection_surface_length_padding * 2.0) / \
                length
        var scale := Vector2(scale_factor, scale_factor)
        
        var translation: Vector2 = \
                preselection_destination.surface.normal * \
                Sc.annotators.params.preselection_surface_outward_offset
        
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
                null,
                true,
                true,
                false)
    else:
        phantom_position_along_surface.surface = null
        phantom_position_along_surface.target_point = \
                preselection_destination.target_point
        phantom_position_along_surface.target_projection_onto_surface = \
                Vector2.INF
