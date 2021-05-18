class_name PathPreselectionAnnotator
extends Node2D

var HUMAN_PRESELECTION_SURFACE_COLOR := Gs.colors.opacify(
        Gs.colors.human_navigation,
        ScaffolderColors.ALPHA_XFAINT)
var HUMAN_PRESELECTION_POSITION_INDICATOR_COLOR := Gs.colors.opacify(
        Gs.colors.human_navigation,
        ScaffolderColors.ALPHA_XFAINT)
var HUMAN_PRESELECTION_PATH_COLOR := Gs.colors.opacify(
        Gs.colors.human_navigation,
        ScaffolderColors.ALPHA_FAINT)

var COMPUTER_PRESELECTION_SURFACE_COLOR := Gs.colors.opacify(
        Gs.colors.computer_navigation,
        ScaffolderColors.ALPHA_XFAINT)
var COMPUTER_PRESELECTION_POSITION_INDICATOR_COLOR := Gs.colors.opacify(
        Gs.colors.computer_navigation,
        ScaffolderColors.ALPHA_XFAINT)
var COMPUTER_PRESELECTION_PATH_COLOR := Gs.colors.opacify(
        Gs.colors.computer_navigation,
        ScaffolderColors.ALPHA_FAINT)

var INVALID_SURFACE_COLOR := Gs.colors.opacify(
        Gs.colors.invalid, ScaffolderColors.ALPHA_XFAINT)
var INVALID_POSITION_INDICATOR_COLOR := Gs.colors.opacify(
        Gs.colors.invalid, ScaffolderColors.ALPHA_XFAINT)

const PRESELECTION_MIN_OPACITY := 0.5
const PRESELECTION_MAX_OPACITY := 1.0
const PRESELECTION_DURATION_SEC := 0.6
var PRESELECTION_SURFACE_DEPTH: float = DrawUtils.SURFACE_DEPTH + 4.0
const PRESELECTION_SURFACE_OUTWARD_OFFSET := 4.0
const PRESELECTION_SURFACE_LENGTH_PADDING := 4.0
const PRESELECTION_POSITION_INDICATOR_LENGTH := 128.0
const PRESELECTION_POSITION_INDICATOR_RADIUS := 32.0
const PRESELECTION_PATH_STROKE_WIDTH := 12.0
const PATH_BACK_END_TRIM_RADIUS := 0.0

var _predictions_container: Node2D
var player: Player
var path_front_end_trim_radius: float
var preselection_destination: PositionAlongSurface = null
var preselection_nearby_position_along_surface: PositionAlongSurface = null
var animation_start_time := -PRESELECTION_DURATION_SEC
var animation_progress := 1.0
var phantom_surface := Surface.new(
        [Vector2.INF],
        SurfaceSide.NONE,
        null,
        [])
var phantom_position_along_surface := PositionAlongSurface.new()
var phantom_path: PlatformGraphPath

func _init(player: Player) -> void:
    self.player = player
    self.path_front_end_trim_radius = min(
            player.movement_params.collider_half_width_height.x,
            player.movement_params.collider_half_width_height.y)
    self._predictions_container = Node2D.new()
    _predictions_container.visible = false
    _predictions_container.modulate.a = \
            Surfacer.nav_selection_prediction_opacity
    add_child(_predictions_container)

func add_prediction(prediction: PlayerPrediction) -> void:
    _predictions_container.add_child(prediction)

func remove_prediction(prediction: PlayerPrediction) -> void:
    _predictions_container.remove_child(prediction)

func _process(_delta_sec: float) -> void:
    var current_time: float = Gs.time.get_play_time_sec()
    
    var did_preselection_position_change := \
            preselection_destination != \
            player.pre_selection.navigation_destination
    
    if did_preselection_position_change and \
            !player.new_selection.get_has_selection():
        var previous_preselection_surface := \
                preselection_destination.surface if \
                preselection_destination != null else \
                null
        var next_preselection_surface := \
                player.pre_selection.navigation_destination.surface if \
                player.pre_selection.get_is_selection_navigatable() else \
                null
        var did_preselection_surface_change := \
                previous_preselection_surface != next_preselection_surface
        
        preselection_destination = \
                player.pre_selection.navigation_destination
        preselection_nearby_position_along_surface = \
                player.pre_selection.nearby_position_along_surface
        
        if did_preselection_surface_change:
            animation_start_time = current_time
            
            _update_phantom_surface()
        
        if preselection_destination != null:
            _update_phantom_position_along_surface()
            
            phantom_path = player.navigator.find_path(
                    preselection_destination,
                    preselection_nearby_position_along_surface)
            
            if phantom_path != null:
                # Update the human-player prediction.
                player.prediction.match_path(
                        phantom_path,
                        phantom_path.duration)
                
                # Update computer-player predictions.
                for computer_player in Gs.utils.get_all_nodes_in_group(
                        Surfacer.group_name_computer_players):
                    computer_player.prediction.match_navigator(
                            computer_player.navigator,
                            phantom_path.duration)
        else:
            phantom_path = null
        
        _predictions_container.visible = phantom_path != null
        
        update()
    
    if preselection_destination != null:
        animation_progress = fmod((current_time - animation_start_time) / \
                PRESELECTION_DURATION_SEC, 1.0)
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
    if phantom_path != null:
        if player.is_human_player:
            surface_base_color = HUMAN_PRESELECTION_SURFACE_COLOR
            position_indicator_base_color = \
                    HUMAN_PRESELECTION_POSITION_INDICATOR_COLOR
            path_base_color = HUMAN_PRESELECTION_PATH_COLOR
        else:
            surface_base_color = COMPUTER_PRESELECTION_SURFACE_COLOR
            position_indicator_base_color = \
                    COMPUTER_PRESELECTION_POSITION_INDICATOR_COLOR
            path_base_color = COMPUTER_PRESELECTION_PATH_COLOR
    else:
        surface_base_color = INVALID_SURFACE_COLOR
        position_indicator_base_color = INVALID_POSITION_INDICATOR_COLOR
    
    if Surfacer.is_preselection_trajectory_shown:
        # Draw path.
        if phantom_path != null:
            var path_alpha := \
                    path_base_color.a * alpha_multiplier
            var path_color := Color(
                    path_base_color.r,
                    path_base_color.g,
                    path_base_color.b,
                    path_alpha)
            Gs.draw_utils.draw_path(
                    self,
                    phantom_path,
                    PRESELECTION_PATH_STROKE_WIDTH,
                    path_color,
                    path_front_end_trim_radius,
                    PATH_BACK_END_TRIM_RADIUS,
                    false,
                    false,
                    true,
                    false)
        
        if phantom_surface.side != SurfaceSide.NONE:
            # Draw Surface.
            var surface_alpha := surface_base_color.a * alpha_multiplier
            var surface_color := Color(
                    surface_base_color.r,
                    surface_base_color.g,
                    surface_base_color.b,
                    surface_alpha)
            Gs.draw_utils.draw_surface(
                    self,
                    phantom_surface,
                    surface_color,
                    PRESELECTION_SURFACE_DEPTH)
    
    if Surfacer.is_navigation_destination_shown:
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
        Gs.draw_utils.draw_destination_marker(
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
    if preselection_destination.surface == null:
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
        
        phantom_surface.bounding_box = Gs.geometry.get_bounding_box_for_points(
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
