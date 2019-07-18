extends Node2D
class_name HumanPlayerAnnotator

const PlayerSurfaceAnnotator = preload("res://framework/annotators/player_surface_annotator.gd")
const HumanPlatformGraphNavigatorAnnotator = preload("res://framework/annotators/human_platform_graph_navigator_annotator.gd")
const PositionAnnotator = preload("res://framework/annotators/position_annotator.gd")
const TileAnnotator = preload("res://framework/annotators/tile_annotator.gd")

var has_entered_tree := false

var player # TODO: Add type back in
var player_surface_annotator: PlayerSurfaceAnnotator
var human_platform_graph_navigator_annotator: HumanPlatformGraphNavigatorAnnotator
var position_annotator: PositionAnnotator
var tile_annotator: TileAnnotator

# TODO: Try adding player type back once Godot fixes the bug that values are silently re-assigned
# to null when types don't match (even though they do, but Godot's type system has a bug with
# inheritance).
func _init(player) -> void:
    self.player = player
    player_surface_annotator = PlayerSurfaceAnnotator.new(player)
    human_platform_graph_navigator_annotator = null
    position_annotator = PositionAnnotator.new(player)
    tile_annotator = TileAnnotator.new(player)
    z_index = 2

func _enter_tree() -> void:
    has_entered_tree = true
    
    add_child(player_surface_annotator)
    add_child(human_platform_graph_navigator_annotator)
    add_child(position_annotator)
    add_child(tile_annotator)
    
    if human_platform_graph_navigator_annotator != null:
        add_child(human_platform_graph_navigator_annotator)

func initialize_platform_graph_navigator() -> void:
    human_platform_graph_navigator_annotator = \
            HumanPlatformGraphNavigatorAnnotator.new(player.platform_graph_navigator)
    
    if has_entered_tree:
        add_child(human_platform_graph_navigator_annotator)

func check_for_update() -> void:
    player_surface_annotator.check_for_update()
    human_platform_graph_navigator_annotator.check_for_update()
    position_annotator.check_for_update()
    tile_annotator.check_for_update()
