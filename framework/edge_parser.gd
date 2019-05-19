extends Reference
class_name EdgeParser

# FIXME: LEFT OFF HERE:
# 
# - Finish everything in JumpFromPlatformMovement (edge calculations, including movement constraints from interfering surfaces)
# - Finish/polish fallable surfaces calculations (and remove old obsolete functions)
# 
# - Use FallFromAirMovement
# - Use PlayerMovement.get_max_upward_distance and PlayerMovement.get_max_horizontal_distance
# - Add logic to use path.start_instructions when we start a navigation while the player isn't on a surface.
# - Add logic to use path.end_instructions when the destination is far enough from the surface AND an optional
#     should_jump_to_reach_destination parameter is provided.
# 
# - Add support for creating PlatformGraphEdge.
# - Add support for executing PlatformGraphEdge.
# - Add annotations for the whole edge set.
# 
# - Implement get_all_edges_from_surface for jumping.
# - Add annotations for the actual trajectories that are defined by PlatformGraphEdge.
#   - These will be stored on PlayerInstructions.
#   - Also render annotations for the constraints that were used (also stored on PlayerInstructions).
# - Add annotations that draw the recent path that the player actually moved.
# - Add annotations for rendering some basic navigation mode info for the CP:
#   - Mode name
#   - Current "input" (UP, LEFT, etc.)?
#   - The entirety of the current instruction-set being run?
# - A*-search: Add support for actually navigating end-to-end to a given target point.
#   - Will need to consider the "weight" for moving along a surface from a previous edge's land to
#     the potential next edge's jump.
# - Add annotations for just the path that the navigator is currently using.
# - Test out the accuracy of edge traversal actually matching up to our pre-calculated trajectories.
# 
# - Add logic to check for obvious surfaces that interfere with an edge trajectory (prefer false
#   negatives over false positives).
# 
# - Add logic to emulate/test/ray-trace a Player's movement across an edge. This should help with
#   annotations (both path and boundaries) and precise detection for interfering surfaces.
# 
# - Add logic to consider a minimum movement distance, since jumping from floors or walls gives a
#   set minimum displacement. 
# 
# - Add logic to start edge traversal from the earliest possible PositionAlongSurface (given the
#   previous/inital/landing PositionAlongSurface), rather than from whatever pre-calculated
#   PositionAlongSurface was used to determine whether the edge is possible.
# 
# - Add logic to automatically self-correct to the expected position/movement/state sometimes...
#   - When? Each frame? Only when we're further away than our tolerance allows?
# 
# - Add support for actually considering the discrete physics time steps rather than assuming
#   continuous integration?
#   - OR, add support for fudging it?
#     - I could calculate and emulate all of this as previously planned to be realistic and use
#       the same rules as a HumanPlayer; BUT, then actually adjust the movement to matchup with
#       the expected pre-calculated result (so, actually, not really run the instructions set at
#       all?)
#     - It's probably at least worth adding an optional mode that does this and comparing the
#       performance.
# 
# - Refactor PlayerMovement classes, so that whether the start and end posiition is on a platform
#   or in the air is configuration that JumpFromPlatformMovement handles directly, rather than
#   relying on a separate FallFromAir class?
# - Add support for including walls in our navigation.
# - Add support for other PlayerMovement sub-classes:
#   - JumpFromWallMovement
#   - FallFromPlatformMovement
#   - FallFromWallMovement
# - Add support for other jump aspects:
#   - Fast fall
#   - Variable jump height
#   - Double jump
#   - Horizontal acceleration?
# 
# - Update the pre-configured Input Map in Project Settings to use more semantic keys instead of just up/down/etc.
# - Document in a separate markdown file exactly which Input Map keys this framework depends on.
# 
# - MAKE get_nearby_surfaces MORE EFFICIENT? (force run it everyframe to ensure no lag)
#   - Scrap previous function; just use bounding box intersection (since I'm going to need to use
#     better logic for determining movement patterns anyway...)
#   - Actually, maybe don't worry too much, because this is actually only run at the start.
# 
# - Add logic to Player when calculating touched edges to check that the collider is a stationary TileMap object
# 
# - Figure out how to configure input names/mappings (or just add docs specifying that the
#   consumer must use these input names?)
# - Test exporting to HTML5.
# - Start adding networking support.

# Returns a mapping from Surfaces to their adjacent Edges.
static func calculate_edges(space_state: Physics2DDirectSpaceState, surfaces: Array, \
        player_info: PlayerTypeConfiguration) -> Dictionary:
    var edges := {}
    
    for surface in surfaces:
        edges[surface] = []
    
    for movement_type in player_info.movement_types:
        if movement_type.can_traverse_edge:
            for surface in surfaces:
                edges[surface].push_back( \
                        movement_type.get_all_edges_from_surface(space_state, surface))
    
    return edges
