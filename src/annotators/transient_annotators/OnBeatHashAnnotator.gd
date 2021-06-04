class_name OnBeatHashAnnotator
extends TransientAnnotator


const DOWNBEAT_DURATION := 0.35
const OFFBEAT_DURATION := DOWNBEAT_DURATION

const DOWNBEAT_LENGTH_SCALE_START := 1.0
const DOWNBEAT_LENGTH_SCALE_END := 8.0
const DOWNBEAT_WIDTH_SCALE_START := DOWNBEAT_LENGTH_SCALE_START
const DOWNBEAT_WIDTH_SCALE_END := DOWNBEAT_LENGTH_SCALE_END

const OFFBEAT_LENGTH_SCALE_START := DOWNBEAT_LENGTH_SCALE_START
const OFFBEAT_LENGTH_SCALE_END := DOWNBEAT_LENGTH_SCALE_END
const OFFBEAT_WIDTH_SCALE_START := OFFBEAT_LENGTH_SCALE_START
const OFFBEAT_WIDTH_SCALE_END := OFFBEAT_LENGTH_SCALE_END

const OPACITY_START := 0.9
const OPACITY_END := 0.0

var beat: PathBeatPrediction
var color: Color

var length_start: float
var length_end: float
var width_start: float
var width_end: float

var length: float
var width: float


func _init(
        beat: PathBeatPrediction,
        downbeat_hash_length := SurfacerDrawUtils.PATH_DOWNBEAT_HASH_LENGTH,
        offbeat_hash_length := SurfacerDrawUtils.PATH_OFFBEAT_HASH_LENGTH,
        downbeat_stroke_width := SurfacerDrawUtils.EDGE_TRAJECTORY_WIDTH,
        offbeat_stroke_width := SurfacerDrawUtils.EDGE_TRAJECTORY_WIDTH,
        downbeat_color := Color.white,
        offbeat_color := Color.white
        ).(
        DOWNBEAT_DURATION if \
                beat.is_downbeat else \
                OFFBEAT_DURATION) -> void:
    self.beat = beat
    if beat.is_downbeat:
        self.length_start = downbeat_hash_length * DOWNBEAT_LENGTH_SCALE_START
        self.length_end = downbeat_hash_length * DOWNBEAT_LENGTH_SCALE_END
        self.width_start = downbeat_stroke_width * DOWNBEAT_WIDTH_SCALE_START
        self.width_end = downbeat_stroke_width * DOWNBEAT_WIDTH_SCALE_END
        self.color = downbeat_color
    else:
        self.length_start = offbeat_hash_length * OFFBEAT_LENGTH_SCALE_START
        self.length_end = offbeat_hash_length * OFFBEAT_LENGTH_SCALE_END
        self.width_start = offbeat_stroke_width * OFFBEAT_WIDTH_SCALE_START
        self.width_end = offbeat_stroke_width * OFFBEAT_WIDTH_SCALE_END
        self.color = offbeat_color
    
    _update()


func _update() -> void:
    ._update()
    
    length = lerp(length_start, length_end, progress)
    width = lerp(width_start, width_end, progress)
    color.a = lerp(OPACITY_START, OPACITY_END, progress)


func _draw() -> void:
    var half_displacement: Vector2 = \
            length * beat.direction.tangent() / 2.0
    var from: Vector2 = beat.position + half_displacement
    var to: Vector2 = beat.position - half_displacement
    
    draw_line(
            from,
            to,
            color,
            width,
            false)
