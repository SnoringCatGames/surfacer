extends Node2D
class_name PlayerAnnotator

const PlayerSurfaceAnnotator = preload("res://framework/annotators/player_surface_annotator.gd")
const PlatformGraphNavigatorAnnotator = preload("res://framework/annotators/platform_graph_navigator_annotator.gd")
const PositionAnnotator = preload("res://framework/annotators/position_annotator.gd")
const TileAnnotator = preload("res://framework/annotators/tile_annotator.gd")

var player: Player
var player_surface_annotator: PlayerSurfaceAnnotator
var platform_graph_navigator_annotator: PlatformGraphNavigatorAnnotator
var position_annotator: PositionAnnotator
var tile_annotator: TileAnnotator

func _init(player: Player) -> void:
    self.player = player
    player_surface_annotator = PlayerSurfaceAnnotator.new(player)
    platform_graph_navigator_annotator = \
            PlatformGraphNavigatorAnnotator.new(player.platform_graph_navigator)
    position_annotator = PositionAnnotator.new(player)
    tile_annotator = TileAnnotator.new(player)
    z_index = 2

func _enter_tree() -> void:
    add_child(player_surface_annotator)
    add_child(platform_graph_navigator_annotator)
    add_child(position_annotator)
    add_child(tile_annotator)

func check_for_update() -> void:
    player_surface_annotator.check_for_update()
    platform_graph_navigator_annotator.check_for_update()
    position_annotator.check_for_update()
    tile_annotator.check_for_update()
