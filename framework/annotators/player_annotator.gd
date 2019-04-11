extends Node2D
class_name PlayerAnnotator

const PlayerSurfaceAnnotator = preload("res://framework/annotators/player_surface_annotator.gd")
const TileAnnotator = preload("res://framework/annotators/tile_annotator.gd")
const PositionAnnotator = preload("res://framework/annotators/position_annotator.gd")

var graplayerph: Player
var player_surface_annotator: PlayerSurfaceAnnotator
var tile_annotator: TileAnnotator
var position_annotator: PositionAnnotator

# FIXME: LEFT OFF HERE: Hook up the PlayerAnnotator, implement its sub-annotators, update it on changes

func _init(player: Player) -> void:
    self.player = player
    player_surface_annotator = PlayerSurfaceAnnotator.new(player)
    tile_annotator = TileAnnotator.new(player)
    position_annotator = PositionAnnotator.new(player)

func _enter_tree() -> void:
    add_child(platform_graph_surface_annotator)
    add_child(tile_annotator)
    add_child(position_annotator)
