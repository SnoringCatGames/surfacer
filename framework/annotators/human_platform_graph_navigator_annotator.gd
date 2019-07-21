extends Node2D
class_name HumanNavigatorAnnotator

var NEARBY_SURFACE_COLOR := Color.from_hsv(0.5, 0.8, 0.99, 0.5)
var SURFACE_CLOSE_DISTANCE_THRESHOLD_COLOR := Color.from_hsv(0.5, 0.8, 0.99, 0.5)
var SURFACE_CLOSE_DISTANCE_THRESHOLD_BORDER_WIDTH := 4.0
var SURFACE_CLOSE_DISTANCE_THRESHOLD_ARC_WIDTH := 16.0

var navigator: Navigator

func _init(navigator: Navigator) -> void:
    self.navigator = navigator

func _draw() -> void:
    if navigator.player.surface_state.is_grabbing_a_surface:
        pass
#        _draw_surface_close_distance_threshold()
#        _draw_nearby_surfaces()

func check_for_update() -> void:
    if navigator.player.surface_state.just_changed_surface:
        update()

func _draw_surface_close_distance_threshold() -> void:
    var vertices = navigator.player.surface_state.grabbed_surface.vertices
    
    # For now, just draw a circle approximately centered on the surface. Ideally, this should be 
    # updated to draw a consistent circular margin around the entire polyline.
    var center: Vector2
    if vertices.size() % 2 == 1:
        # Odd: Choose the middle.
        center = vertices[ceil(vertices.size() / 2)]
    else:
        # Even: Choose halfway between the two middle vertices.
        var a = vertices[vertices.size() / 2 - 1]
        var b = vertices[vertices.size() / 2]
        center = a + (b - a) / 2
        
    DrawUtils.draw_empty_circle(self, center, \
            PlayerMovement.SURFACE_CLOSE_DISTANCE_THRESHOLD, \
            SURFACE_CLOSE_DISTANCE_THRESHOLD_COLOR, \
            SURFACE_CLOSE_DISTANCE_THRESHOLD_BORDER_WIDTH, \
            SURFACE_CLOSE_DISTANCE_THRESHOLD_ARC_WIDTH)

func _draw_nearby_surfaces() -> void:
    for surface in navigator.nearby_surfaces:
        DrawUtils.draw_surface(self, surface, NEARBY_SURFACE_COLOR)