extends Reference
class_name PlatformGraphEdges

# FIXME: LEFT OFF HERE:
# 
# - Implement and use FallFromAirMovement
# - Add logic to use path.start_instructions when we start a navigation while the player isn't on a surface.
# - Add logic to use path.end_instructions when the destination is far enough from the surface AND an optional
#     should_jump_to_reach_destination parameter is provided.
# 
# - Implement get_instructions_for_edge for jumping.
# - Add support for creating PlatformGraphEdge.
# - Add support for executing PlatformGraphEdge.
# - Add annotations for the actual trajectories that are defined by PlatformGraphEdge.
# - Add annotations that draw the recent path that the player actually moved.
# - Add annotations for rendering some basic navigation mode info for the CP:
#   - Mode name
#   - Current "input" (UP, LEFT, etc.)?
#   - The entirety of the current instruction-set being run?
# - Add support for actually parsing out the whole edge set (for our current simple jump, and ignoring walls).
# - Add support for actually navigating end-to-end to a given target point.
# - Add annotations for the whole edge set.
# - Add annotations for just the path that the navigator is currently using.
# - Test out the accuracy of edge traversal actually matching up to our pre-calculated trajectories.
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
# - Use get_max_upward_movement and get_max_horizontal_movement to get a bounding box and use that
#   in Navigator.get_nearby_surfaces.
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
# - 

var player_name: String

func _init(nodes: PlatformGraphNodes, player_info: Dictionary) -> void:
    player_name = player_info.name
    # TODO: player_info.movement_types
    pass
