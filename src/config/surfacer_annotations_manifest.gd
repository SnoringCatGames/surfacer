tool
class_name SurfacerAnnotationsManifest
extends Node


# ---

var is_active_trajectory_shown: bool
var is_previous_trajectory_shown: bool
var is_preselection_trajectory_shown: bool
var is_navigation_destination_shown: bool

var is_human_current_nav_trajectory_shown_with_slow_mo := false
var is_computer_current_nav_trajectory_shown_with_slow_mo := true
var is_human_current_nav_trajectory_shown_without_slow_mo := true
var is_computer_current_nav_trajectory_shown_without_slow_mo := false
var is_human_nav_pulse_shown_with_slow_mo := false
var is_computer_nav_pulse_shown_with_slow_mo := true
var is_human_nav_pulse_shown_without_slow_mo := true
var is_computer_nav_pulse_shown_without_slow_mo := false
var is_human_new_nav_exclamation_mark_shown := false
var is_computer_new_nav_exclamation_mark_shown := true

var does_human_nav_pulse_grow := false
var does_computer_nav_pulse_grow := true
var is_human_prediction_shown := true
var is_computer_prediction_shown := true
var nav_selection_prediction_opacity := 0.5
var nav_selection_prediction_tween_duration := 0.15
var nav_path_fade_in_duration := 0.2
var new_path_pulse_duration := 0.7
var new_path_pulse_time_length := 1.0

# ---


func _init() -> void:
    Sc.logger.on_global_init(self, "SurfacerAnnotationsManifest")


func _register_manifest(manifest: Dictionary) -> void:
    if manifest.has(
            "is_human_current_nav_trajectory_shown_with_slow_mo"):
        self.is_human_current_nav_trajectory_shown_with_slow_mo = \
                manifest.is_human_current_nav_trajectory_shown_with_slow_mo
    if manifest.has(
            "is_computer_current_nav_trajectory_shown_with_slow_mo"):
        self.is_computer_current_nav_trajectory_shown_with_slow_mo = \
                manifest.is_computer_current_nav_trajectory_shown_with_slow_mo
    if manifest.has(
            "is_human_current_nav_trajectory_shown_without_slow_mo"):
        self.is_human_current_nav_trajectory_shown_without_slow_mo = \
                manifest.is_human_current_nav_trajectory_shown_without_slow_mo
    if manifest.has(
            "is_computer_current_nav_trajectory_shown_without_slow_mo"):
        self.is_computer_current_nav_trajectory_shown_without_slow_mo = \
                manifest \
                    .is_computer_current_nav_trajectory_shown_without_slow_mo
    if manifest.has("is_human_nav_pulse_shown_with_slow_mo"):
        self.is_human_nav_pulse_shown_with_slow_mo = \
                manifest.is_human_nav_pulse_shown_with_slow_mo
    if manifest.has("is_computer_nav_pulse_shown_with_slow_mo"):
        self.is_computer_nav_pulse_shown_with_slow_mo = \
                manifest.is_computer_nav_pulse_shown_with_slow_mo
    if manifest.has("is_human_nav_pulse_shown_without_slow_mo"):
        self.is_human_nav_pulse_shown_without_slow_mo = \
                manifest.is_human_nav_pulse_shown_without_slow_mo
    if manifest.has("is_computer_nav_pulse_shown_without_slow_mo"):
        self.is_computer_nav_pulse_shown_without_slow_mo = \
                manifest.is_computer_nav_pulse_shown_without_slow_mo
    if manifest.has("is_human_new_nav_exclamation_mark_shown"):
        self.is_human_new_nav_exclamation_mark_shown = \
                manifest.is_human_new_nav_exclamation_mark_shown
    if manifest.has("is_computer_new_nav_exclamation_mark_shown"):
        self.is_computer_new_nav_exclamation_mark_shown = \
                manifest.is_computer_new_nav_exclamation_mark_shown
    if manifest.has("does_human_nav_pulse_grow"):
        self.does_human_nav_pulse_grow = \
                manifest.does_human_nav_pulse_grow
    if manifest.has("does_computer_nav_pulse_grow"):
        self.does_computer_nav_pulse_grow = \
                manifest.does_computer_nav_pulse_grow
    if manifest.has("nav_selection_prediction_opacity"):
        self.nav_selection_prediction_opacity = \
                manifest.nav_selection_prediction_opacity
    if manifest.has("nav_path_fade_in_duration"):
        self.nav_path_fade_in_duration = \
                manifest.nav_path_fade_in_duration
    if manifest.has("new_path_pulse_duration"):
        self.new_path_pulse_duration = \
                manifest.new_path_pulse_duration
    if manifest.has("new_path_pulse_time_length"):
        self.new_path_pulse_time_length = \
                manifest.new_path_pulse_time_length
    
    if manifest.has("nav_selection_prediction_tween_duration"):
        self.nav_selection_prediction_tween_duration = \
                manifest.nav_selection_prediction_tween_duration
    
    if manifest.has("is_human_prediction_shown"):
        self.is_human_prediction_shown = \
                manifest.is_human_prediction_shown
    if manifest.has("is_computer_prediction_shown"):
        self.is_computer_prediction_shown = \
                manifest.is_computer_prediction_shown
