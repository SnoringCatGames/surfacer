extends Node2D
class_name CollisionCalculationAnnotator

# FIXME: LEFT OFF HERE: -----------------------------------

const HUE_START := 0.11
const HUE_END := 0.61
const HUE_PREVIOUS := 0.91
const HUE_COLLISION := 0.0

var COLOR_FRAME_START := Color.from_hsv( \
        HUE_START, \
        0.7, \
        0.9, \
        0.5)
var COLOR_FRAME_END := Color.from_hsv( \
        HUE_END, \
        0.7, \
        0.9, \
        0.5)
var COLOR_FRAME_PREVIOUS := Color.from_hsv( \
        HUE_PREVIOUS, \
        0.7, \
        0.9, \
        0.2)
var COLOR_MOTION_ARROW := Color.from_hsv( \
        lerp(HUE_START, HUE_END, 0.5), \
        0.7, \
        0.9, \
        0.5)
var COLOR_INTERSECTION_POINT := Color.from_hsv( \
        0.8, \
        0.8, \
        0.9, \
        0.7)# FIXME: ------------
#var COLOR_INTERSECTION_POINT := Color.from_hsv( \
#        HUE_COLLISION, \
#        0.8, \
#        0.9, \
#        0.7)
var COLOR_JUST_BEFORE_COLLISION := Color.from_hsv( \
        HUE_COLLISION, \
        0.5, \
        0.6, \
        0.2)
var COLOR_AT_COLLISION := Color.from_hsv( \
        HUE_COLLISION, \
        0.7, \
        0.9, \
        0.5)

const STROKE_WIDTH_BOUNDING_BOX := 1.0
const STROKE_WIDTH_MARGIN := 1.0
const STROKE_WIDTH_MOTION_ARROW := 1.0

const RADIUS_INTERSECTION_POINT := 2.0

const DASH_LENGTH_MARGIN := 6.0
const DASH_GAP_MARGIN := 10.0

const MOTION_ARROW_HEAD_LENGTH := 14.0
const MOTION_ARROW_HEAD_WIDTH := 8.0

#var edge_attempt: MovementCalcOverallDebugState
#var selected_step: MovementCalcStepDebugState
#
#func _draw() -> void:
#    if selected_step == null or selected_step.collision_result_metadata == null:
#        return
#
#    var collision_result_metadata := selected_step.collision_result_metadata
#
#    # Draw the bounding boxes at frame start, end, and previous.
#    _draw_bounding_box_and_margin( \
#            collision_result_metadata.frame_start_position, \
#            COLOR_FRAME_START)
#    _draw_bounding_box_and_margin( \
#            collision_result_metadata.frame_end_position, \
#            COLOR_FRAME_END)
#    _draw_bounding_box_and_margin( \
#            collision_result_metadata.frame_previous_position, \
#            COLOR_FRAME_PREVIOUS)
#
#    # FIXME: REMOVE
##    # Draw an arrow showing the motion from frame start to frame end.
##    DrawUtils.draw_arrow( \
##            self, \
##            collision_result_metadata.frame_start_position, \
##            collision_result_metadata.frame_end_position, \
##            MOTION_ARROW_HEAD_LENGTH, \
##            MOTION_ARROW_HEAD_WIDTH, \
##            COLOR_MOTION_ARROW, \
##            STROKE_WIDTH_MOTION_ARROW)
#
#    # Draw the intersection points that were calculated by Godot's collision engine.
#    for intersection_point in collision_result_metadata.intersection_points:
#        draw_circle( \
#                intersection_point, \
#                RADIUS_INTERSECTION_POINT, \
#                COLOR_INTERSECTION_POINT)
#
#    # Check whether there was a pre-existing collision.
#    if collision_result_metadata.collision_ratios.size() > 0:
#        # Draw the bounding boxes at the moment of collision and the moment just before collision.
#        _draw_bounding_box_and_margin( \
#                collision_result_metadata.get_position_at_collision_ratio_index(0), \
#                COLOR_AT_COLLISION)
#        _draw_bounding_box_and_margin( \
#                collision_result_metadata.get_position_at_collision_ratio_index(1), \
#                COLOR_JUST_BEFORE_COLLISION)
#
#func _draw_bounding_box_and_margin( \
#        center: Vector2, \
#        color: Color) -> void:
#    var collision_result_metadata := selected_step.collision_result_metadata
#    DrawUtils.draw_rectangle_outline( \
#            self, \
#            center, 
#            collision_result_metadata.collider_half_width_height, \
#            false, \
#            color, \
#            STROKE_WIDTH_BOUNDING_BOX)
#    DrawUtils.draw_dashed_rectangle( \
#            self, \
#            center, \
#            collision_result_metadata.collider_half_width_height + \
#                    Vector2(collision_result_metadata.margin, collision_result_metadata.margin), \
#            false, \
#            color, \
#            DASH_LENGTH_MARGIN, \
#            DASH_GAP_MARGIN, \
#            0.0, \
#            STROKE_WIDTH_MARGIN, \
#            false)
