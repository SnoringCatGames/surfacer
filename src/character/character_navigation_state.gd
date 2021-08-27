class_name CharacterNavigationState
extends Reference


var is_player_character := false

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
var just_reached_end_of_edge := false
var is_stalling_one_frame_before_reaching_end := false

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
    self.just_reached_end_of_edge = false
    self.is_stalling_one_frame_before_reaching_end = false
    
    self.expected_position_along_surface.reset()
