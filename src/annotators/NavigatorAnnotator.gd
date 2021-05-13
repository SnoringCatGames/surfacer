class_name NavigatorAnnotator
extends Node2D

var navigator: Navigator
var previous_path: PlatformGraphPath
var current_path: PlatformGraphPath
var current_destination: PositionAlongSurface
var is_slow_motion_enabled := false

var previous_path_back_end_trim_radius: float

func _init(navigator: Navigator) -> void:
    self.navigator = navigator
    self.previous_path_back_end_trim_radius = min(
            navigator.player.movement_params.collider_half_width_height.x,
            navigator.player.movement_params.collider_half_width_height.y)

func _physics_process(_delta_sec: float) -> void:
    if navigator.current_path != current_path:
        current_path = navigator.current_path
        current_destination = navigator.current_destination
        update()
    if navigator.previous_path != previous_path:
        previous_path = navigator.previous_path
        update()
    if Surfacer.slow_motion.is_enabled != is_slow_motion_enabled:
        is_slow_motion_enabled = Surfacer.slow_motion.is_enabled
        update()

func _draw() -> void:
    if navigator.player.is_human_player:
        if is_slow_motion_enabled and \
                !Surfacer \
                    .is_human_current_nav_trajectory_shown_with_slow_mo or \
                !is_slow_motion_enabled and \
                !Surfacer \
                    .is_human_current_nav_trajectory_shown_without_slow_mo:
            return
    else:
        if is_slow_motion_enabled and \
                !Surfacer \
                    .is_computer_current_nav_trajectory_shown_with_slow_mo or \
                !is_slow_motion_enabled and \
                !Surfacer \
                    .is_computer_current_nav_trajectory_shown_without_slow_mo:
            return
    
    if current_path != null:
        if Surfacer.is_active_trajectory_shown:
            var current_path_color: Color = \
                    Surfacer.ann_defaults \
                            .HUMAN_NAVIGATOR_CURRENT_PATH_COLOR if \
                    navigator.player.is_human_player else \
                    Surfacer.ann_defaults.COMPUTER_NAVIGATOR_CURRENT_PATH_COLOR
            Gs.draw_utils.draw_path(
                    self,
                    current_path,
                    AnnotationElementDefaults \
                            .NAVIGATOR_TRAJECTORY_STROKE_WIDTH,
                    current_path_color,
                    AnnotationElementDefaults \
                            .NAVIGATOR_ORIGIN_INDICATOR_RADIUS + 
                            AnnotationElementDefaults \
                                .NAVIGATOR_TRAJECTORY_STROKE_WIDTH / 2.0,
                    AnnotationElementDefaults \
                            .NAVIGATOR_DESTINATION_INDICATOR_RADIUS + 
                            AnnotationElementDefaults \
                                .NAVIGATOR_TRAJECTORY_STROKE_WIDTH / 2.0,
                    true,
                    false,
                    true,
                    false)
            
            # Draw the origin indicator.
            var origin_indicator_fill_color: Color = \
                    Surfacer.ann_defaults \
                            .HUMAN_NAVIGATOR_ORIGIN_INDICATOR_FILL_COLOR if \
                    navigator.player.is_human_player else \
                    Surfacer.ann_defaults \
                            .COMPUTER_NAVIGATOR_ORIGIN_INDICATOR_FILL_COLOR
            self.draw_circle(
                    current_path.origin,
                    AnnotationElementDefaults.NAVIGATOR_ORIGIN_INDICATOR_RADIUS,
                    origin_indicator_fill_color)
            var origin_indicator_stroke_color: Color = \
                    Surfacer.ann_defaults \
                            .HUMAN_NAVIGATOR_ORIGIN_INDICATOR_STROKE_COLOR if \
                    navigator.player.is_human_player else \
                    Surfacer.ann_defaults \
                            .COMPUTER_NAVIGATOR_ORIGIN_INDICATOR_STROKE_COLOR
            Gs.draw_utils.draw_circle_outline(
                    self,
                    current_path.origin,
                    AnnotationElementDefaults.NAVIGATOR_ORIGIN_INDICATOR_RADIUS,
                    origin_indicator_stroke_color,
                    AnnotationElementDefaults.NAVIGATOR_INDICATOR_STROKE_WIDTH,
                    4.0)
        
        if Surfacer.is_navigation_destination_shown:
            # Draw the destination indicator.
            var cone_end_point := \
                    current_destination.target_projection_onto_surface
            var cone_length: float = \
                    AnnotationElementDefaults \
                            .NAVIGATOR_DESTINATIAN_INDICATOR_LENGTH - \
                    AnnotationElementDefaults \
                            .NAVIGATOR_DESTINATION_INDICATOR_RADIUS
            var destination_indicator_fill_color: Color = \
                    Surfacer.ann_defaults \
                            .HUMAN_NAVIGATOR_DESTINATION_INDICATOR_FILL_COLOR if \
                    navigator.player.is_human_player else \
                    Surfacer.ann_defaults \
                            .COMPUTER_NAVIGATOR_DESTINATION_INDICATOR_FILL_COLOR
            Gs.draw_utils.draw_destination_marker(
                    self,
                    cone_end_point,
                    false,
                    current_destination.side,
                    destination_indicator_fill_color,
                    cone_length,
                    AnnotationElementDefaults \
                            .NAVIGATOR_DESTINATION_INDICATOR_RADIUS,
                    true,
                    INF,
                    4.0)
            var destination_indicator_stroke_color: Color = \
                    Surfacer.ann_defaults \
                            .HUMAN_NAVIGATOR_DESTINATION_INDICATOR_STROKE_COLOR if \
                    navigator.player.is_human_player else \
                    Surfacer.ann_defaults \
                            .COMPUTER_NAVIGATOR_DESTINATION_INDICATOR_STROKE_COLOR
            Gs.draw_utils.draw_destination_marker(
                    self,
                    cone_end_point,
                    false,
                    current_destination.side,
                    destination_indicator_stroke_color,
                    cone_length,
                    AnnotationElementDefaults \
                            .NAVIGATOR_DESTINATION_INDICATOR_RADIUS,
                    false,
                    AnnotationElementDefaults.NAVIGATOR_INDICATOR_STROKE_WIDTH,
                    4.0)
    
    elif previous_path != null and \
            Surfacer.is_previous_trajectory_shown:
        var previous_path_color: Color = \
                Surfacer.ann_defaults.HUMAN_NAVIGATOR_PREVIOUS_PATH_COLOR if \
                navigator.player.is_human_player else \
                Surfacer.ann_defaults.COMPUTER_NAVIGATOR_PREVIOUS_PATH_COLOR
        Gs.draw_utils.draw_path(
                self,
                previous_path,
                AnnotationElementDefaults \
                        .NAVIGATOR_TRAJECTORY_STROKE_WIDTH,
                previous_path_color,
                0.0,
                previous_path_back_end_trim_radius,
                true,
                false,
                true,
                false)
