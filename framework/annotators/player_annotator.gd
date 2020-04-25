extends Node2D
class_name PlayerAnnotator

var player: Player
var previous_position: Vector2
var navigator_annotator: NavigatorAnnotator
var player_recent_movement_annotator: PlayerRecentMovementAnnotator
var player_surface_annotator: PlayerSurfaceAnnotator
var position_annotator: PositionAnnotator
var tile_annotator: TileAnnotator
var surface_selection_annotator: SurfaceSelectionAnnotator

func _init( \
        player: Player, \
        renders_navigator := false) -> void:
    self.player = player
    player_recent_movement_annotator = PlayerRecentMovementAnnotator.new(player)
    player_surface_annotator = PlayerSurfaceAnnotator.new(player)
    position_annotator = PositionAnnotator.new(player)
    tile_annotator = TileAnnotator.new(player)
    surface_selection_annotator = SurfaceSelectionAnnotator.new(player)
    if renders_navigator:
        navigator_annotator = NavigatorAnnotator.new(player.navigator)
    z_index = 2

func _enter_tree() -> void:
    add_child(player_recent_movement_annotator)
    add_child(player_surface_annotator)
    add_child(position_annotator)
    add_child(tile_annotator)
    add_child(surface_selection_annotator)
    if navigator_annotator != null:
        add_child(navigator_annotator)

func check_for_update() -> void:
    if !Geometry.are_points_equal_with_epsilon( \
            player.position, \
            previous_position, \
            0.01):
        previous_position = player.position
        
        player_recent_movement_annotator.check_for_update()
        player_surface_annotator.check_for_update()
        position_annotator.check_for_update()
        tile_annotator.check_for_update()
    
    if navigator_annotator != null:
        navigator_annotator.check_for_update()
