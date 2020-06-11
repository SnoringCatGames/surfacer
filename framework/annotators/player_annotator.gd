extends Node2D
class_name PlayerAnnotator

var player: Player
var previous_position: Vector2
var navigator_annotator: NavigatorAnnotator
var recent_movement_annotator: PlayerRecentMovementAnnotator
var surface_annotator: PlayerSurfaceAnnotator
var position_annotator: PlayerPositionAnnotator
var tile_annotator: PlayerTileAnnotator
var surface_selection_annotator: SurfaceSelectionAnnotator
var surface_preselection_annotator: SurfacePreselectionAnnotator

func _init( \
        player: Player, \
        renders_navigator := false) -> void:
    self.player = player
    recent_movement_annotator = PlayerRecentMovementAnnotator.new(player)
    surface_annotator = PlayerSurfaceAnnotator.new(player)
    position_annotator = PlayerPositionAnnotator.new(player)
    tile_annotator = PlayerTileAnnotator.new(player)
    surface_selection_annotator = SurfaceSelectionAnnotator.new(player)
    surface_preselection_annotator = SurfacePreselectionAnnotator.new(player)
    if renders_navigator:
        navigator_annotator = NavigatorAnnotator.new(player.navigator)
    z_index = 2

func _enter_tree() -> void:
    add_child(recent_movement_annotator)
    add_child(surface_annotator)
    add_child(position_annotator)
    add_child(tile_annotator)
    add_child(surface_selection_annotator)
    add_child(surface_preselection_annotator)
    if navigator_annotator != null:
        add_child(navigator_annotator)

func _physics_process(delta: float) -> void:
    if !Geometry.are_points_equal_with_epsilon( \
            player.position, \
            previous_position, \
            0.01):
        previous_position = player.position
        
        recent_movement_annotator.check_for_update()
        surface_annotator.check_for_update()
        position_annotator.check_for_update()
        tile_annotator.check_for_update()
    
    if navigator_annotator != null:
        navigator_annotator.check_for_update()
