class_name PlayerNavigationState
extends Reference

var is_human_player := false
var is_expecting_to_enter_air := false
var just_interrupted_navigation := false
var just_left_air_unexpectedly := false
var just_entered_air_unexpectedly := false
var just_interrupted_by_user_action := false
var just_reached_end_of_edge := false
var expected_position_along_surface := PositionAlongSurface.new()

func reset() -> void:
    self.is_expecting_to_enter_air = false
    self.just_interrupted_navigation = false
    self.just_left_air_unexpectedly = false
    self.just_entered_air_unexpectedly = false
    self.just_interrupted_by_user_action = false
    self.just_reached_end_of_edge = false
    self.expected_position_along_surface.reset()
