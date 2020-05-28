extends LegendItem
class_name ValidEdgeTrajectoryLegendItem

const TYPE := LegendItemType.VALID_EDGE_TRAJECTORY
const TEXT := "Valid edge\ntrajectory"

const NORMALIZED_FAKE_POSITIONS := [
    Vector2(0.0, 1.0), \
    Vector2(0.125, 0.5625), \
    Vector2(0.25, 0.25), \
    Vector2(0.375, 0.0625), \
    Vector2(0.5, 0.0), \
    Vector2(0.625, 0.0625), \
    Vector2(0.75, 0.25), \
    Vector2(0.875, 0.5625), \
    Vector2(1.0, 1.0), \
]
const SCALE := 0.8

func _init().( \
        TYPE, \
        TEXT) -> void:
    pass

func _draw_shape(
        center: Vector2, \
        size: Vector2) -> void:
    var offset := center - 0.5 * size * SCALE
    var positions := []
    positions.resize(NORMALIZED_FAKE_POSITIONS.size())
    for i in range(NORMALIZED_FAKE_POSITIONS.size()):
        positions[i] = NORMALIZED_FAKE_POSITIONS[i] * size * SCALE + offset
    draw_polyline( \
            PoolVector2Array(positions), \
            AnnotationElementDefaults.EDGE_COLOR_PARAMS.get_color(), \
            DrawUtils.EDGE_TRAJECTORY_WIDTH)
