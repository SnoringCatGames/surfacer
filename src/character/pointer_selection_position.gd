class_name PointerSelectionPosition
extends Reference


const SURFACE_TO_AIR_THRESHOLD_MAX_JUMP_RATIO := 0.85
const POINTER_TO_SURFACE_SELECTION_THRESHOLD := 84.0
const NEARBY_POSITIONS_TO_CALCULATE_COUNT := 7

var _character
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
var path_beats_time_start := INF
# Array<PathBeatPrediction>
var path_beats: Array


func _init(character) -> void:
    self._character = character
    var surface_to_air_jump_distance_threshold: float = \
            character.movement_params.max_upward_jump_distance * \
            SURFACE_TO_AIR_THRESHOLD_MAX_JUMP_RATIO
    self._surface_to_air_jump_distance_squared_threshold = \
            surface_to_air_jump_distance_threshold * \
            surface_to_air_jump_distance_threshold
    self._pointer_to_surface_distance_squared_threshold = \
            POINTER_TO_SURFACE_SELECTION_THRESHOLD * \
            POINTER_TO_SURFACE_SELECTION_THRESHOLD


func update_pointer_position(pointer_position: Vector2) -> void:
    self.pointer_position = pointer_position
    
    var nearby_positions_along_surface := []
    if pointer_position != Vector2.INF:
        nearby_positions_along_surface = \
                SurfaceFinder.find_closest_positions_on_surfaces(
                        pointer_position,
                        _character,
                        NEARBY_POSITIONS_TO_CALCULATE_COUNT,
                        _surface_to_air_jump_distance_squared_threshold)
    
    if !nearby_positions_along_surface.empty():
        JumpLandPositionsUtils \
                .ensure_position_is_not_too_close_to_concave_neighbor(
                        _character.movement_params,
                        nearby_positions_along_surface[0])
        
        if pointer_position.distance_squared_to(
                nearby_positions_along_surface[0].target_point) < \
                _pointer_to_surface_distance_squared_threshold:
            # The selection is close enough to a surface, so we navigate to a
            # target along the surface.
            self.navigation_destination = nearby_positions_along_surface[0]
        elif _character.movement_params.can_target_in_air_destinations:
            # The selection is too far from the surface, so we navigate to an
            # in-air target.
            self.navigation_destination = PositionAlongSurfaceFactory \
                    .create_position_without_surface(pointer_position)
        else:
            # The character cannot target in-air destinations.
            self.navigation_destination = null
    else:
        # The selection was too far from any surface. It's likely that there is
        # no jump-off point that could reach the selection.
        self.navigation_destination = null
    
    if navigation_destination != null:
        if navigation_destination.surface != null:
            self.path = _character.navigator.find_path(
                    navigation_destination,
                    false)
            if path != null:
                if _character.is_bouncy:
                    _character.navigator.bouncify_path(path)
                self.path_beats_time_start = Sc.time.get_scaled_play_time()
                self.path_beats = \
                        Sc.beats.calculate_path_beat_hashes_for_current_mode(
                                path,
                                path_beats_time_start)
            else:
                self.path_beats_time_start = INF
                self.path_beats = []
            self.nearby_position_along_surface = navigation_destination
        else:
            _update_path_for_in_air_destination(nearby_positions_along_surface)
    else:
        self.path = null
        self.path_beats_time_start = INF
        self.path_beats = []
        self.nearby_position_along_surface = null


func _update_path_for_in_air_destination(
        nearby_positions_along_surface: Array) -> void:
    for nearby_position_along_surface in nearby_positions_along_surface:
        JumpLandPositionsUtils \
                .ensure_position_is_not_too_close_to_concave_neighbor(
                        _character.movement_params,
                        nearby_position_along_surface)
        
        var path: PlatformGraphPath = _character.navigator.find_path(
                navigation_destination,
                false,
                nearby_position_along_surface)
        if path != null:
            if _character.is_bouncy:
                _character.navigator.bouncify_path(path)
            self.path = path
            self.path_beats_time_start = Sc.time.get_scaled_play_time()
            self.path_beats = \
                    Sc.beats.calculate_path_beat_hashes_for_current_mode(
                            path,
                            path_beats_time_start)
            self.nearby_position_along_surface = nearby_position_along_surface
            return
    
    # We weren't able to find any valid navigation to the destination
    # position.
    self.path = null
    self.path_beats_time_start = INF
    self.path_beats = []
    self.nearby_position_along_surface = null


func get_has_selection() -> bool:
    return pointer_position != Vector2.INF


func get_is_selection_navigable() -> bool:
    return path != null


func update_beats() -> void:
    if path != null:
        self.path_beats_time_start = Sc.time.get_scaled_play_time()
        self.path_beats = \
                Sc.beats.calculate_path_beat_hashes_for_current_mode(
                        path,
                        path_beats_time_start)


func clear() -> void:
    self.pointer_position = Vector2.INF
    self.navigation_destination = null
    self.path = null
    self.path_beats_time_start = INF
    self.path_beats = []
    self.nearby_position_along_surface = null


func copy(other) -> void:
    self.pointer_position = other.pointer_position
    self.navigation_destination = other.navigation_destination
    self.path = other.path
    self.path_beats_time_start = INF
    self.path_beats = other.path_beats
    self.nearby_position_along_surface = other.nearby_position_along_surface
