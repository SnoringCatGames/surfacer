extends Reference
class_name PlatformGraphEdges

# FIXME: LEFT OFF HERE:
# 
# - Add logic to the Player to detect unexpected interruptions:
#   - Hit a surface (inform the navigator; navigator returns false if unexpected; player starts a new navigation)
#   - Hit by anything else (figure out response depending on collider; at least cancel previous navigation)
# - Add logic to initiate next walk/climb on surface once we've landed on the desired surface.
# - Add logic to initiate next jump when we've reached the target PositionAlongSurface when moving within node.
# - Add logic to walk/climb to target PositionAlongSurface.
# - Add logic to detect when we've reached the target PositionAlongSurface when moving within node.
# - Add logic to inform the player when we've reached the final goal position.
# - Add a check when current position/movement/state is further than our tolerance away from the expected state for the current path.
#   - Throw an error.
# - Add logic to automatically self-correct to the expected position/movement/state sometimes...
#   - When? Each frame? Only when we're further away than our tolerance allows?
# 
# - Implement get_movement_instructions for jumping.
# - Add support for creating PlatformGraphEdge.
# - Add support for executing PlatformGraphEdge.
# - Add annotations for the actual trajectories that are defined by PlatformGraphEdge
# - Add annotations that draw the recent path that the player actually moved
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
# - Add support for actually considering the discrete physics time steps rather than assuming
#   continuous integration?
#   - OR, add support for fudging it?
#     - I could calculate and emulate all of this as previously planned to be realistic and use
#       the same rules as a HumanPlayer; BUT, then actually adjust the movement to matchup with
#       the expected pre-calculated result (so, actually, not really run the instructions set at
#       all?)
#     - It's probably at least worth adding an optional mode that does this and comparing the
#       performance.
# - Add support for including walls in our navigation.
# - Add support for other EdgeMovement sub-classes:
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
# - 

func _init(nodes: PlatformGraphNodes, player_info: Dictionary) -> void:
    # TODO
    pass
