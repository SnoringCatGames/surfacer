class_name PointerSelectionPosition
extends Reference

const SURFACE_TO_AIR_THRESHOLD_MAX_JUMP_RATIO := 0.8
const POINTER_TO_SURFACE_SELECTION_THRESHOLD := 144.0

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

var path: PlatformGraphPath

func _init(player) -> void:
    self._player = player
    var surface_to_air_jump_distance_threshold: float = \
            player.movement_params.max_upward_jump_distance * \
            SURFACE_TO_AIR_THRESHOLD_MAX_JUMP_RATIO
    self._surface_to_air_jump_distance_squared_threshold = \
            surface_to_air_jump_distance_threshold * \
            surface_to_air_jump_distance_threshold
    self._pointer_to_surface_distance_squared_threshold = \
            POINTER_TO_SURFACE_SELECTION_THRESHOLD * \
            POINTER_TO_SURFACE_SELECTION_THRESHOLD

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
    
    if nearby_position_along_surface != null:
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
    
    if navigation_destination != null:
        if navigation_destination.surface != null:
            self.path = _player.navigator.find_path(navigation_destination)
        else:
            _update_path_for_in_air_destination()
    else:
        self.path = null

func _update_path_for_in_air_destination() -> void:
    var next_path: PlatformGraphPath = _player.navigator.find_path(
            navigation_destination,
            nearby_position_along_surface)
    if next_path != null:
        self.path = next_path
        return
    
    # Check the nearest positions along surfaces of different sides, if the
    # absolute closest surface didn't work.
    var sides_to_check := [
        SurfaceSide.FLOOR,
        SurfaceSide.LEFT_WALL,
        SurfaceSide.RIGHT_WALL,
        SurfaceSide.CEILING,
    ]
    for side in sides_to_check:
        if side == nearby_position_along_surface.side:
            # Don't re-consider the original failing surface.
            continue
        
        # Get the surfaces of the given side.
        var surfaces_to_check: Array
        if side == SurfaceSide.FLOOR:
            if !_player.movement_params.can_grab_floors:
                continue
            else:
                surfaces_to_check = \
                        Surfacer.graph_parser.surface_parser.floors
        elif side == SurfaceSide.LEFT_WALL:
            if !_player.movement_params.can_grab_walls:
                continue
            else:
                surfaces_to_check = \
                        Surfacer.graph_parser.surface_parser.left_walls
        elif side == SurfaceSide.RIGHT_WALL:
            if !_player.movement_params.can_grab_walls:
                continue
            else:
                surfaces_to_check = \
                        Surfacer.graph_parser.surface_parser.right_walls
        elif side == SurfaceSide.CEILING:
            if !_player.movement_params.can_grab_ceilings:
                continue
            else:
                surfaces_to_check = \
                        Surfacer.graph_parser.surface_parser.ceilings
        else:
            Utils.error()
        
        var next_nearby_position := \
                SurfaceParser.find_closest_position_on_a_surface(
                        pointer_position,
                        _player,
                        _surface_to_air_jump_distance_squared_threshold,
                        surfaces_to_check)
        if next_nearby_position == null:
            continue
        
        next_path = _player.navigator.find_path(
                navigation_destination,
                next_nearby_position)
        if next_path != null:
            self.nearby_position_along_surface = next_nearby_position
            self.path = next_path
            return
    
    # We weren't able to find any valid navigation to the destination
    # position.
    self.nearby_position_along_surface = null
    self.path = null

func get_has_selection() -> bool:
    return pointer_position != Vector2.INF

func get_is_selection_navigatable() -> bool:
    return path != null

func clear() -> void:
    self.pointer_position = Vector2.INF
    self.nearby_position_along_surface = null
    self.navigation_destination = null
    self.path = null

func copy(other) -> void:
    self.pointer_position = other.pointer_position
    self.nearby_position_along_surface = other.nearby_position_along_surface
    self.navigation_destination = other.navigation_destination
    self.path = other.path
