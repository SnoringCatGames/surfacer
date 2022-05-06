class_name CharacterNavigationState
extends Reference


var character

var is_currently_navigating := false
var just_ended := false

var has_reached_destination := false
var just_reached_destination := false

var has_canceled := false
var just_canceled := false

var has_interrupted := false
var just_interrupted := false

var is_expecting_to_enter_air := false
var just_left_air_unexpectedly := false
var just_entered_air_unexpectedly := false
var just_interrupted_by_unexpected_collision := false
var just_interrupted_by_player_action := false
var just_interrupted_by_being_stuck := false
var just_started_edge := false
var just_reached_end_of_edge := false
var is_stalling_one_frame_before_reaching_end := false

var is_triggered_by_player_selection := false

var stopping_at_next_surface := false

var path_start_time := -1.0
var edge_start_time := -1.0

var edge_start_frame := -1
var edge_frame_count := 0

var last_interruption_position := Vector2.INF

var expected_position_along_surface := PositionAlongSurface.new()


func reset() -> void:
    self.is_currently_navigating = false
    self.just_ended = false
    self.has_reached_destination = false
    self.just_reached_destination = false
    self.has_canceled = false
    self.just_canceled = false
    self.has_interrupted = false
    self.just_interrupted = false
    
    self.is_expecting_to_enter_air = false
    self.just_left_air_unexpectedly = false
    self.just_entered_air_unexpectedly = false
    self.just_interrupted_by_unexpected_collision = false
    self.just_interrupted_by_player_action = false
    self.just_interrupted_by_being_stuck = false
    self.just_started_edge = false
    self.just_reached_end_of_edge = false
    self.is_stalling_one_frame_before_reaching_end = false
    
    self.is_triggered_by_player_selection = false
    
    self.stopping_at_next_surface = false
    
    self.path_start_time = -1.0
    self.edge_start_time = -1.0
    
    self.edge_start_frame = -1
    self.edge_frame_count = 0
    
    self.last_interruption_position = Vector2.INF
    
    self.expected_position_along_surface.reset()
