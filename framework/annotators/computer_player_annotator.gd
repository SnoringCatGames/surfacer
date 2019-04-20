extends Node2D
class_name ComputerPlayerAnnotator

const PlayerSurfaceAnnotator = preload("res://framework/annotators/player_surface_annotator.gd")
const ComputerPlatformGraphNavigatorAnnotator = preload("res://framework/annotators/computer_platform_graph_navigator_annotator.gd")
const PositionAnnotator = preload("res://framework/annotators/position_annotator.gd")
const TileAnnotator = preload("res://framework/annotators/tile_annotator.gd")

var player: ComputerPlayer
var player_surface_annotator: PlayerSurfaceAnnotator
var computer_platform_graph_navigator_annotator: ComputerPlatformGraphNavigatorAnnotator
var position_annotator: PositionAnnotator
var tile_annotator: TileAnnotator

func _init(player: ComputerPlayer) -> void:
    self.player = player
    player_surface_annotator = PlayerSurfaceAnnotator.new(player)
    computer_platform_graph_navigator_annotator = ComputerPlatformGraphNavigatorAnnotator.new(player.platform_graph_navigator)
    position_annotator = PositionAnnotator.new(player)
    tile_annotator = TileAnnotator.new(player)
    z_index = 2

func _enter_tree() -> void:
    add_child(player_surface_annotator)
    add_child(computer_platform_graph_navigator_annotator)
    add_child(position_annotator)
    add_child(tile_annotator)

func check_for_update() -> void:
    player_surface_annotator.check_for_update()
    computer_platform_graph_navigator_annotator.check_for_update()
    position_annotator.check_for_update()
    tile_annotator.check_for_update()
