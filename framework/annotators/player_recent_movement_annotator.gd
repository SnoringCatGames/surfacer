extends Node2D
class_name PlayerRecentMovementAnnotator

const RECENT_POSITIONS_BUFFER_SIZE := 150

const MOVEMENT_HUE := Colors.TEAL.h
const MOVEMENT_OPACITY_NEWEST := 0.7
const MOVEMENT_OPACITY_OLDEST := 0.01
const MOVEMENT_STROKE_WIDTH := 1.5

var player: Player

# We use this as a circular buffer.
var recent_positions: PoolVector2Array

var current_position_index := 0

var total_position_count := 0

func _init(player: Player) -> void:
    self.player = player
    self.recent_positions = PoolVector2Array()
    self.recent_positions.resize(RECENT_POSITIONS_BUFFER_SIZE)

func check_for_update() -> void:
    var most_recent_position := recent_positions[current_position_index]
    if !Geometry.are_points_equal_with_epsilon(player.position, most_recent_position, 0.01):
        total_position_count += 1
        current_position_index = (current_position_index + 1) % RECENT_POSITIONS_BUFFER_SIZE
        recent_positions[current_position_index] = player.position
        update()

func _draw() -> void:
    if total_position_count < 2:
        # Don't try to draw the starting position by itself.
        return
    
    # Until we've actually been in enough positions, we won't actually render points for the whole
    # buffer.
    var position_count := min(RECENT_POSITIONS_BUFFER_SIZE, total_position_count) as int
    
    # Calculate the oldest index that we'll render. We start drawing here.
    var start_index := \
            (current_position_index + 1 - position_count + RECENT_POSITIONS_BUFFER_SIZE) % \
            RECENT_POSITIONS_BUFFER_SIZE
    
    var previous_position := recent_positions[start_index]
    var next_position: Vector2
    var opacity: float
    var color: Color
    
    for i in range(1, position_count):
        # Older positions fade out.
        opacity = i / (position_count as float) * \
                (MOVEMENT_OPACITY_NEWEST - MOVEMENT_OPACITY_OLDEST) + MOVEMENT_OPACITY_OLDEST
        color = Color.from_hsv(MOVEMENT_HUE, 0.7, 0.7, opacity)
        
        # Calculate our current index in the circular buffer.
        i = (start_index + i) % RECENT_POSITIONS_BUFFER_SIZE
        next_position = recent_positions[i]
        
        draw_line(previous_position, next_position, color, MOVEMENT_STROKE_WIDTH)
        
        previous_position = next_position
