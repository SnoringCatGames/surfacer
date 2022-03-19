tool
class_name SurfacerAnnotationsManifest
extends Node


# ---

var is_player_preselection_trajectory_shown := true

var is_player_slow_mo_trajectory_shown := false
var is_player_non_slow_mo_trajectory_shown := true
var is_player_previous_trajectory_shown := false
var is_player_navigation_destination_shown := true
var is_player_nav_pulse_shown := false

var is_npc_slow_mo_trajectory_shown := true
var is_npc_non_slow_mo_trajectory_shown := false
var is_npc_previous_trajectory_shown := false
var is_npc_navigation_destination_shown := false
var is_npc_nav_pulse_shown := true

var does_player_nav_pulse_grow := false
var is_player_prediction_shown := true

var does_npc_nav_pulse_grow := true
var is_npc_prediction_shown := true

var nav_selection_prediction_opacity := 0.5
var nav_selection_prediction_tween_duration := 0.15
var nav_path_fade_in_duration := 0.2
var new_path_pulse_duration := 0.7
var new_path_pulse_time_length := 1.0

# ---


func _init() -> void:
    Sc.logger.on_global_init(self, "SurfacerAnnotationsManifest")


func _parse_manifest(manifest: Dictionary) -> void:
    if manifest.has("is_player_slow_mo_trajectory_shown"):
        self.is_player_slow_mo_trajectory_shown = \
                manifest.is_player_slow_mo_trajectory_shown
    if manifest.has("is_npc_slow_mo_trajectory_shown"):
        self.is_npc_slow_mo_trajectory_shown = \
                manifest.is_npc_slow_mo_trajectory_shown
    if manifest.has("is_player_non_slow_mo_trajectory_shown"):
        self.is_player_non_slow_mo_trajectory_shown = \
                manifest.is_player_non_slow_mo_trajectory_shown
    if manifest.has("is_npc_non_slow_mo_trajectory_shown"):
        self.is_npc_non_slow_mo_trajectory_shown = \
                manifest.is_npc_non_slow_mo_trajectory_shown
    if manifest.has("is_player_nav_pulse_shown_with_slow_mo"):
        self.is_player_nav_pulse_shown_with_slow_mo = \
                manifest.is_player_nav_pulse_shown_with_slow_mo
    if manifest.has("is_npc_nav_pulse_shown_with_slow_mo"):
        self.is_npc_nav_pulse_shown_with_slow_mo = \
                manifest.is_npc_nav_pulse_shown_with_slow_mo
    if manifest.has("is_player_nav_pulse_shown_without_slow_mo"):
        self.is_player_nav_pulse_shown_without_slow_mo = \
                manifest.is_player_nav_pulse_shown_without_slow_mo
    if manifest.has("is_npc_nav_pulse_shown_without_slow_mo"):
        self.is_npc_nav_pulse_shown_without_slow_mo = \
                manifest.is_npc_nav_pulse_shown_without_slow_mo
    if manifest.has("does_player_nav_pulse_grow"):
        self.does_player_nav_pulse_grow = \
                manifest.does_player_nav_pulse_grow
    if manifest.has("does_npc_nav_pulse_grow"):
        self.does_npc_nav_pulse_grow = \
                manifest.does_npc_nav_pulse_grow
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
    
    if manifest.has("is_player_prediction_shown"):
        self.is_player_prediction_shown = \
                manifest.is_player_prediction_shown
    if manifest.has("is_npc_prediction_shown"):
        self.is_npc_prediction_shown = \
                manifest.is_npc_prediction_shown
