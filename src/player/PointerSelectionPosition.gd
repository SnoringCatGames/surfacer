class_name PointerSelectionPosition
extends Reference

var _player
var _surface_to_air_jump_distance_squared_threshold: float
var _pointer_to_surface_distance_squared_threshold: float

# The position of the click/tap.
var pointer_position := Vector2.INF

# The nearest position along a surface, or null if no surface is close enough.
var nearby_position_along_surface: PositionAlongSurface

# The navigation-destination position. This could be along the surface, in-air,
# or null depending on how far the selection was from the surface.
var navigation_destination: PositionAlongSurface

func _init(player) -> void:
    self._player = player
    var surface_to_air_jump_distance_threshold: float = \
            player.movement_params.max_upward_jump_distance * \
            Navigator.SURFACE_TO_AIR_THRESHOLD_MAX_JUMP_RATIO
    self._surface_to_air_jump_distance_squared_threshold = \
            surface_to_air_jump_distance_threshold * \
            surface_to_air_jump_distance_threshold
    self._pointer_to_surface_distance_squared_threshold = \
            Navigator.POINTER_TO_SURFACE_SELECTION_THRESHOLD * \
            Navigator.POINTER_TO_SURFACE_SELECTION_THRESHOLD

func update_pointer_position(pointer_position: Vector2) -> void:
    self.pointer_position = pointer_position
    
    if pointer_position != Vector2.INF:
        self.nearby_position_along_surface = \
                SurfaceParser.find_closest_position_on_a_surface(
                        pointer_position,
                        _player,
                        _surface_to_air_jump_distance_squared_threshold)
    else:
        self.nearby_position_along_surface = null
    
    if self.nearby_position_along_surface != null:
        if pointer_position.distance_squared_to(
                nearby_position_along_surface.target_point) < \
                _pointer_to_surface_distance_squared_threshold:
            # The selection is close enough to a surface, so we navigate to a
            # target along the surface.
            self.navigation_destination = \
                    PositionAlongSurface.new(nearby_position_along_surface)
        else:
            # The selection is too far from the surface, so we navigate to an
            # in-air target.
            self.navigation_destination = PositionAlongSurfaceFactory \
                    .create_position_without_surface(pointer_position)
    else:
        # The selection was too far from any surface. It's likely that there is
        # no jump-off point that could reach the selection.
        self.navigation_destination = null

func get_has_selection() -> bool:
    return self.pointer_position != Vector2.INF

func get_is_selection_navigatable() -> bool:
    return self.nearby_position_along_surface != null

func clear() -> void:
    self.pointer_position = Vector2.INF
    self.nearby_position_along_surface = null
    self.navigation_destination = null

func copy(other) -> void:
    self.pointer_position = other.pointer_position
    self.nearby_position_along_surface = other.nearby_position_along_surface
    self.navigation_destination = other.navigation_destination
