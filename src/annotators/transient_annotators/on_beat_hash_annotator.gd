class_name OnBeatHashAnnotator
extends TransientAnnotator


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
        downbeat_hash_length := Sc.ann_params.downbeat_hash_length_default,
        offbeat_hash_length := Sc.ann_params.offbeat_hash_length_default,
        downbeat_stroke_width := Sc.ann_params.hash_stroke_width_default,
        offbeat_stroke_width := Sc.ann_params.hash_stroke_width_default,
        downbeat_color := Color.white,
        offbeat_color := Color.white
        ).(
        Sc.ann_params.downbeat_duration if \
                beat.is_downbeat else \
                Sc.ann_params.offbeat_duration) -> void:
    self.beat = beat
    if beat.is_downbeat:
        self.length_start = \
                downbeat_hash_length * Sc.ann_params.downbeat_length_scale_start
        self.length_end = \
                downbeat_hash_length * Sc.ann_params.downbeat_length_scale_end
        self.width_start = \
                downbeat_stroke_width * Sc.ann_params.downbeat_width_scale_start
        self.width_end = \
                downbeat_stroke_width * Sc.ann_params.downbeat_width_scale_end
        self.color = downbeat_color
    else:
        self.length_start = \
                offbeat_hash_length * Sc.ann_params.offbeat_length_scale_start
        self.length_end = \
                offbeat_hash_length * Sc.ann_params.offbeat_length_scale_end
        self.width_start = \
                offbeat_stroke_width * Sc.ann_params.offbeat_width_scale_start
        self.width_end = \
                offbeat_stroke_width * Sc.ann_params.offbeat_width_scale_end
        self.color = offbeat_color
    
    _update()


func _update() -> void:
    ._update()
    
    length = lerp(length_start, length_end, progress)
    width = lerp(width_start, width_end, progress)
    color.a = lerp(
            Sc.ann_params.beat_opacity_start,
            Sc.ann_params.beat_opacity_end,
            progress)


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
