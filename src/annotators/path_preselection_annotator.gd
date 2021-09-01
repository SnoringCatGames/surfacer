class_name PathPreselectionAnnotator
extends Node2D


var INVALID_SURFACE_COLOR := Sc.colors.opacify(
        Sc.colors.invalid, ScaffolderColors.ALPHA_XFAINT)
var INVALID_POSITION_INDICATOR_COLOR := Sc.colors.opacify(
        Sc.colors.invalid, ScaffolderColors.ALPHA_XFAINT)

const PRESELECTION_MIN_OPACITY := 0.5
const PRESELECTION_MAX_OPACITY := 1.0
const PRESELECTION_DEFAULT_DURATION := 0.6
var PRESELECTION_SURFACE_DEPTH: float = SurfacerDrawUtils.SURFACE_DEPTH + 4.0
const PRESELECTION_SURFACE_OUTWARD_OFFSET := 4.0
const PRESELECTION_SURFACE_LENGTH_PADDING := 4.0
const PRESELECTION_POSITION_INDICATOR_LENGTH := 128.0
const PRESELECTION_POSITION_INDICATOR_RADIUS := 32.0
const PRESELECTION_PATH_STROKE_WIDTH := 12.0
const PRESELECTION_PATH_DOWNBEAT_HASH_LENGTH := \
        PRESELECTION_PATH_STROKE_WIDTH * 5
const PRESELECTION_PATH_OFFBEAT_HASH_LENGTH := \
        PRESELECTION_PATH_STROKE_WIDTH * 3
const PRESELECTION_PATH_DOWNBEAT_STROKE_WIDTH := PRESELECTION_PATH_STROKE_WIDTH
const PRESELECTION_PATH_OFFBEAT_STROKE_WIDTH := PRESELECTION_PATH_STROKE_WIDTH
const PATH_BACK_END_TRIM_RADIUS := 0.0

var _predictions_container: Node2D
var character: SurfacerCharacter
var player_nav: PlayerNavigationBehavior
var surface_color: Color
var indicator_color: Color
var path_color: Color

var path_front_end_trim_radius: float
var preselection_destination: PositionAlongSurface = null
var animation_start_time := -PRESELECTION_DEFAULT_DURATION
var animation_progress := 1.0
var phantom_surface := Surface.new(
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
    self.player_nav = \
            character.get_behavior(PlayerNavigationBehavior)
    
    surface_color = Sc.colors.opacify(
            character.navigation_annotation_color,
            ScaffolderColors.ALPHA_XFAINT)
    indicator_color = Sc.colors.opacify(
            character.navigation_annotation_color,
            ScaffolderColors.ALPHA_XFAINT)
    path_color = Sc.colors.opacify(
            character.navigation_annotation_color,
            ScaffolderColors.ALPHA_XFAINT)
    
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
    animation_start_time = -PRESELECTION_DEFAULT_DURATION


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
        
        _predictions_container.visible = preselection_path != null
        
        update()
    
    if preselection_destination != null:
        var preselection_duration: float = \
                Sc.slow_motion.music \
                        .tick_tock_beat_duration_unscaled * \
                    Sc.slow_motion.tick_tock_tempo_multiplier * \
                    2.0 if \
                Sc.slow_motion.is_enabled else \
                PRESELECTION_DEFAULT_DURATION
        animation_progress = fmod((current_time - animation_start_time) / \
                preselection_duration, 1.0)
        update()


func _draw() -> void:
    if preselection_destination == null:
        # When we don't render anything in this draw call, it clears the draw
        # buffer.
        return
    
    var alpha_multiplier := ((1 - animation_progress) * \
            (PRESELECTION_MAX_OPACITY - PRESELECTION_MIN_OPACITY) + \
            PRESELECTION_MIN_OPACITY)
    
    var surface_base_color: Color
    var position_indicator_base_color: Color
    var path_base_color: Color
    if preselection_path != null:
        if character.is_player_character:
            surface_base_color = surface_color
            position_indicator_base_color = indicator_color
            path_base_color = path_color
        else:
            surface_base_color = surface_color
            position_indicator_base_color = indicator_color
            path_base_color = path_color
    else:
        surface_base_color = INVALID_SURFACE_COLOR
        position_indicator_base_color = INVALID_POSITION_INDICATOR_COLOR
    
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
                    PRESELECTION_PATH_STROKE_WIDTH,
                    path_color,
                    path_front_end_trim_radius,
                    PATH_BACK_END_TRIM_RADIUS,
                    false,
                    false,
                    true,
                    false)
            
            Sc.draw.draw_beat_hashes(
                    self,
                    preselection_path_beats,
                    PRESELECTION_PATH_DOWNBEAT_HASH_LENGTH,
                    PRESELECTION_PATH_OFFBEAT_HASH_LENGTH,
                    PRESELECTION_PATH_DOWNBEAT_STROKE_WIDTH,
                    PRESELECTION_PATH_OFFBEAT_STROKE_WIDTH,
                    path_color,
                    path_color)
        
        if phantom_surface.side != SurfaceSide.NONE:
            # Draw Surface.
            var surface_alpha := surface_base_color.a * alpha_multiplier
            var surface_color := Color(
                    surface_base_color.r,
                    surface_base_color.g,
                    surface_base_color.b,
                    surface_alpha)
            Sc.draw.draw_surface(
                    self,
                    phantom_surface,
                    surface_color,
                    PRESELECTION_SURFACE_DEPTH)
    
    if Su.ann_manifest.is_player_navigation_destination_shown:
        # Draw destination marker.
        var position_indicator_alpha := \
                position_indicator_base_color.a * alpha_multiplier
        var position_indicator_color := Color(
                position_indicator_base_color.r,
                position_indicator_base_color.g,
                position_indicator_base_color.b,
                position_indicator_alpha)
        var cone_length := PRESELECTION_POSITION_INDICATOR_LENGTH - \
                PRESELECTION_POSITION_INDICATOR_RADIUS
        Sc.draw.draw_destination_marker(
                self,
                phantom_position_along_surface,
                false,
                position_indicator_color,
                cone_length,
                PRESELECTION_POSITION_INDICATOR_RADIUS,
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
        
        # Enlarge and offset the phantom surface, so that it stands out more.
        
        var surface_center := preselection_destination.surface.center
        
        var length := \
                preselection_destination.surface.bounding_box.size.x if \
                preselection_destination.surface.normal.x == 0.0 else \
                preselection_destination.surface.bounding_box.size.y
        var scale_factor := \
                (length + PRESELECTION_SURFACE_LENGTH_PADDING * 2.0) / length
        var scale := Vector2(scale_factor, scale_factor)
        
        var translation := preselection_destination.surface.normal * \
                PRESELECTION_SURFACE_OUTWARD_OFFSET
        
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
