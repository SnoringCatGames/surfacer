class_name NavigatorAnnotator
extends Node2D

var navigator: Navigator
var previous_path: PlatformGraphPath
var current_path: PlatformGraphPath
var current_destination: PositionAlongSurface

var previous_path_back_end_trim_radius: float

func _init(navigator: Navigator) -> void:
    self.navigator = navigator
    self.previous_path_back_end_trim_radius = min(
            navigator.player.movement_params.collider_half_width_height.x,
            navigator.player.movement_params.collider_half_width_height.y)

func _physics_process(delta_sec: float) -> void:
    if navigator.current_path != current_path:
        current_path = navigator.current_path
        current_destination = navigator.current_destination
        update()
    if navigator.previous_path != previous_path:
        previous_path = navigator.previous_path
        update()

func _draw() -> void:
    if !navigator.player.is_human_player:
        return
    
    if current_path != null:
        if Surfacer.is_active_trajectory_shown:
            Gs.draw_utils.draw_path(
                    self,
                    current_path,
                    AnnotationElementDefaults \
                            .NAVIGATOR_TRAJECTORY_STROKE_WIDTH,
                    Surfacer.ann_defaults.NAVIGATOR_CURRENT_PATH_COLOR,
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
            self.draw_circle(
                    current_path.origin,
                    AnnotationElementDefaults.NAVIGATOR_ORIGIN_INDICATOR_RADIUS,
                    Surfacer.ann_defaults \
                            .NAVIGATOR_ORIGIN_INDICATOR_FILL_COLOR)
            Gs.draw_utils.draw_circle_outline(
                    self,
                    current_path.origin,
                    AnnotationElementDefaults.NAVIGATOR_ORIGIN_INDICATOR_RADIUS,
                    Surfacer.ann_defaults \
                            .NAVIGATOR_ORIGIN_INDICATOR_STROKE_COLOR,
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
            Gs.draw_utils.draw_destination_marker(
                    self,
                    cone_end_point,
                    false,
                    current_destination.side,
                    Surfacer.ann_defaults \
                            .NAVIGATOR_DESTINATION_INDICATOR_FILL_COLOR,
                    cone_length,
                    AnnotationElementDefaults \
                            .NAVIGATOR_DESTINATION_INDICATOR_RADIUS,
                    true,
                    INF,
                    4.0)
            Gs.draw_utils.draw_destination_marker(
                    self,
                    cone_end_point,
                    false,
                    current_destination.side,
                    Surfacer.ann_defaults \
                            .NAVIGATOR_DESTINATION_INDICATOR_STROKE_COLOR,
                    cone_length,
                    AnnotationElementDefaults \
                            .NAVIGATOR_DESTINATION_INDICATOR_RADIUS,
                    false,
                    AnnotationElementDefaults.NAVIGATOR_INDICATOR_STROKE_WIDTH,
                    4.0)
    
    elif previous_path != null and \
            Surfacer.is_previous_trajectory_shown:
        Gs.draw_utils.draw_path(
                self,
                previous_path,
                AnnotationElementDefaults \
                        .NAVIGATOR_TRAJECTORY_STROKE_WIDTH,
                Surfacer.ann_defaults.NAVIGATOR_PREVIOUS_PATH_COLOR,
                0.0,
                previous_path_back_end_trim_radius,
                true,
                false,
                true,
                false)
