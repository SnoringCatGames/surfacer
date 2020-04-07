extends Node2D
class_name PlayerRecentMovementAnnotator

const RECENT_POSITIONS_BUFFER_SIZE := 150

const MOVEMENT_HUE := Colors.TEAL.h
const MOVEMENT_OPACITY_NEWEST := 0.7
const MOVEMENT_OPACITY_OLDEST := 0.01
const MOVEMENT_STROKE_WIDTH := 1

const HORIZONTAL_INSTRUCTION_START_LENGTH := 9
const HORIZONTAL_INSTRUCTION_START_STROKE_WIDTH := 1
const HORIZONTAL_INSTRUCTION_END_LENGTH := 9
const HORIZONTAL_INSTRUCTION_END_STROKE_WIDTH := 1
const VERTICAL_INSTRUCTION_START_END_LENGTH := 11
const VERTICAL_INSTRUCTION_START_END_STROKE_WIDTH := 1

var player: Player

# We use this as a circular buffer.
var recent_positions: PoolVector2Array

# We use this as a circular buffer.
var recent_actions: PoolIntArray

var current_position_index := -1

var total_position_count := 0

func _init(player: Player) -> void:
    self.player = player
    self.recent_positions = PoolVector2Array()
    self.recent_positions.resize(RECENT_POSITIONS_BUFFER_SIZE)
    self.recent_actions = PoolIntArray()
    self.recent_actions.resize(RECENT_POSITIONS_BUFFER_SIZE)

func check_for_update() -> void:
    var most_recent_position := recent_positions[current_position_index]
    if !Geometry.are_points_equal_with_epsilon( \
            player.position, \
            most_recent_position, \
            0.01):
        # Record the action as belonging to the previous frame.
        if player.actions.just_pressed_jump:
            recent_actions[current_position_index] = PlayerActionType.PRESSED_JUMP
        elif player.actions.just_pressed_left:
            recent_actions[current_position_index] = PlayerActionType.PRESSED_LEFT
        elif player.actions.just_pressed_right:
            recent_actions[current_position_index] = PlayerActionType.PRESSED_RIGHT
        elif player.actions.just_pressed_grab_wall:
            recent_actions[current_position_index] = PlayerActionType.PRESSED_GRAB_WALL
        elif player.actions.just_pressed_face_left:
            recent_actions[current_position_index] = PlayerActionType.PRESSED_FACE_LEFT
        elif player.actions.just_pressed_face_right:
            recent_actions[current_position_index] = PlayerActionType.PRESSED_FACE_RIGHT
        elif player.actions.just_released_jump:
            recent_actions[current_position_index] = PlayerActionType.RELEASED_JUMP
        elif player.actions.just_released_left:
            recent_actions[current_position_index] = PlayerActionType.RELEASED_LEFT
        elif player.actions.just_released_right:
            recent_actions[current_position_index] = PlayerActionType.RELEASED_RIGHT
        elif player.actions.just_released_grab_wall:
            recent_actions[current_position_index] = PlayerActionType.RELEASED_GRAB_WALL
        elif player.actions.just_released_face_left:
            recent_actions[current_position_index] = PlayerActionType.RELEASED_FACE_LEFT
        elif player.actions.just_released_face_right:
            recent_actions[current_position_index] = PlayerActionType.RELEASED_FACE_RIGHT
        else:
            recent_actions[current_position_index] = PlayerActionType.NONE
        
        total_position_count += 1
        current_position_index = (current_position_index + 1) % RECENT_POSITIONS_BUFFER_SIZE
        
        # Record the new position for the current frame.
        recent_positions[current_position_index] = player.position
        # Record an empty place-holder action value for the current frame.
        recent_actions[current_position_index] = PlayerActionType.NONE
        
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
    var action: int
    
    for i in range(1, position_count):
        # Older positions fade out.
        opacity = i / (position_count as float) * \
                (MOVEMENT_OPACITY_NEWEST - MOVEMENT_OPACITY_OLDEST) + MOVEMENT_OPACITY_OLDEST
        color = Color.from_hsv( \
                MOVEMENT_HUE, \
                0.7, \
                0.7, \
                opacity)
        
        # Calculate our current index in the circular buffer.
        i = (start_index + i) % RECENT_POSITIONS_BUFFER_SIZE
        next_position = recent_positions[i]
        
        draw_line( \
                previous_position, \
                next_position, \
                color, \
                MOVEMENT_STROKE_WIDTH)
        
        action = recent_actions[i]
        if action != PlayerActionType.NONE:
            _draw_action_indicator( \
                    action, \
                    next_position, \
                    opacity)
        
        previous_position = next_position

# Draw an indicator for the action that happened at this point.
func _draw_action_indicator( \
        action: int, \
        position: Vector2, \
        opacity: float) -> void:
    var color := Color.from_hsv( \
            MOVEMENT_HUE, \
            0.3, \
            0.9, \
            opacity)
    
    if action == PlayerActionType.PRESSED_JUMP or action == PlayerActionType.RELEASED_JUMP:
        # Draw a plus for the jump instruction start/end.
        DrawUtils.draw_asterisk( \
                self, \
                position, \
                VERTICAL_INSTRUCTION_START_END_LENGTH, \
                VERTICAL_INSTRUCTION_START_END_LENGTH, \
                color, \
                VERTICAL_INSTRUCTION_START_END_STROKE_WIDTH)
    elif action == PlayerActionType.PRESSED_LEFT or action == PlayerActionType.PRESSED_RIGHT:
        # Draw a plus for the left/right instruction start.
        DrawUtils.draw_plus( \
                self, \
                position, \
                HORIZONTAL_INSTRUCTION_START_LENGTH, \
                HORIZONTAL_INSTRUCTION_START_LENGTH, 
                color, \
                HORIZONTAL_INSTRUCTION_START_STROKE_WIDTH)
    elif action == PlayerActionType.RELEASED_LEFT or action == PlayerActionType.RELEASED_RIGHT:
        # Draw a minus for the left/right instruction end.
        self.draw_line( \
                position + Vector2(-HORIZONTAL_INSTRUCTION_START_LENGTH / 2, 0), \
                position + Vector2(HORIZONTAL_INSTRUCTION_START_LENGTH / 2, 0), \
                color, \
                HORIZONTAL_INSTRUCTION_START_STROKE_WIDTH)
    elif action == PlayerActionType.PRESSED_GRAB_WALL or \
            action == PlayerActionType.RELEASED_GRAB_WALL or \
            action == PlayerActionType.PRESSED_FACE_LEFT or \
            action == PlayerActionType.RELEASED_FACE_LEFT or \
            action == PlayerActionType.PRESSED_FACE_RIGHT or \
            action == PlayerActionType.RELEASED_FACE_RIGHT:
        pass
    else:
        Utils.error("Unknown PlayerActionType passed to _draw_action_indicator: %s" % \
                PlayerActionType.to_string(action))
