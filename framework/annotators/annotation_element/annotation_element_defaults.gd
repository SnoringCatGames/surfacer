extends Node
# This is given the underscore suffix as a workaround for Godot's unfortunate limitation of not
# allowing the class_name to match the singleton name.
class_name AnnotationElementDefaults_

### Surface

const SURFACE_HUE_MIN := 0.0
const SURFACE_HUE_MAX := 1.0
const SURFACE_SATURATION := 0.9
const SURFACE_VALUE := 0.9
const SURFACE_ALPHA := 0.6

const ORIGIN_SURFACE_HUE := 0.61
const DESTINATION_SURFACE_HUE := 0.97

const SURFACE_DEPTH := 16.0

var SURFACE_COLOR_PARAMS := ColorParamsFactory.create_hsv_range_color_params_with_constant_sva( \
        SURFACE_HUE_MIN, \
        SURFACE_HUE_MAX, \
        SURFACE_SATURATION, \
        SURFACE_VALUE, \
        SURFACE_ALPHA)

var ORIGIN_SURFACE_COLOR_PARAMS := HsvColorParams.new( \
        ORIGIN_SURFACE_HUE, \
        SURFACE_SATURATION, \
        SURFACE_VALUE, \
        SURFACE_ALPHA)

var DESTINATION_SURFACE_COLOR_PARAMS := HsvColorParams.new( \
        DESTINATION_SURFACE_HUE, \
        SURFACE_SATURATION, \
        SURFACE_VALUE, \
        SURFACE_ALPHA)

### Edge

# FIXME: Remove
const EDGE_BASE_COLOR := Color.white

const EDGE_HUE_MIN := 0.0
const EDGE_HUE_MAX := 1.0
const EDGE_SATURATION := 0.9
const EDGE_VALUE := 0.9
const EDGE_ALPHA := 0.9

const INCLUDES_WAYPOINTS := true
const INCLUDES_INSTRUCTION_INDICATORS := true
const INCLUDES_DISCRETE_POSITIONS := true

var EDGE_COLOR_PARAMS := ColorParamsFactory.create_hsv_range_color_params_with_constant_sva( \
        EDGE_HUE_MIN, \
        EDGE_HUE_MAX, \
        EDGE_SATURATION, \
        EDGE_VALUE, \
        EDGE_ALPHA)

### FailedEdgeAttempt

const FAILED_EDGE_ATTEMPT_RADIUS := 6.0
const FAILED_EDGE_ATTEMPT_DASH_LENGTH := 4.0
const FAILED_EDGE_ATTEMPT_DASH_GAP := 4.0
const FAILED_EDGE_ATTEMPT_DASH_STROKE_WIDTH := 1.0

const FAILED_EDGE_ATTEMPT_INCLUDES_SURFACES := false

var FAILED_EDGE_ATTEMPT_COLOR_PARAMS := EDGE_COLOR_PARAMS

### JumpLandPositions

const JUMP_LAND_POSITIONS_HUE_MIN := 0.0
const JUMP_LAND_POSITIONS_HUE_MAX := 1.0
const JUMP_LAND_POSITIONS_SATURATION := 0.7
const JUMP_LAND_POSITIONS_VALUE := 0.7
const JUMP_LAND_POSITIONS_ALPHA := 0.7

const JUMP_LAND_POSITIONS_RADIUS := 6.0
const JUMP_LAND_POSITIONS_DASH_LENGTH := 4.0
const JUMP_LAND_POSITIONS_DASH_GAP := 4.0
const JUMP_LAND_POSITIONS_DASH_STROKE_WIDTH := 1.0

var JUMP_LAND_POSITIONS_COLOR_PARAMS := \
        ColorParamsFactory.create_hsv_range_color_params_with_constant_sva( \
                JUMP_LAND_POSITIONS_HUE_MIN, \
                JUMP_LAND_POSITIONS_HUE_MAX, \
                JUMP_LAND_POSITIONS_SATURATION, \
                JUMP_LAND_POSITIONS_VALUE, \
                JUMP_LAND_POSITIONS_ALPHA)
