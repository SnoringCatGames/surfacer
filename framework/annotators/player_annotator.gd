extends Node2D
class_name PlayerAnnotator

const PlayerSurfaceAnnotator := preload("res://framework/annotators/player_surface_annotator.gd")
const NavigatorAnnotator := preload("res://framework/annotators/navigator_annotator.gd")
const PositionAnnotator := preload("res://framework/annotators/position_annotator.gd")
const TileAnnotator := preload("res://framework/annotators/tile_annotator.gd")

var player: Player
var player_surface_annotator: PlayerSurfaceAnnotator
var position_annotator: PositionAnnotator
var tile_annotator: TileAnnotator
var navigator_annotator: NavigatorAnnotator

func _init(player: Player, renders_navigator := false) -> void:
    self.player = player
    player_surface_annotator = PlayerSurfaceAnnotator.new(player)
    position_annotator = PositionAnnotator.new(player)
    tile_annotator = TileAnnotator.new(player)
    if renders_navigator:
        navigator_annotator = \
                NavigatorAnnotator.new(player.navigator)
    z_index = 2

func _enter_tree() -> void:
    add_child(player_surface_annotator)
    add_child(position_annotator)
    add_child(tile_annotator)
    if navigator_annotator != null:
        add_child(navigator_annotator)

func check_for_update() -> void:
    player_surface_annotator.check_for_update()
    position_annotator.check_for_update()
    tile_annotator.check_for_update()
    if navigator_annotator != null:
        navigator_annotator.check_for_update()
