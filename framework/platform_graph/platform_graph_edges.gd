extends Reference
class_name PlatformGraphEdges

# FIXME: LEFT OFF HERE:
# - Add logic to translate player Node2D center position to the center position along the edge of
#   the surface (in world coordinates)
# - Add logic to translate that position to PositionAlongSurface.
# - Add logic in navigator to determine/store what "NavigationMode" we are in:
#   - Within a node, moving to target PositionAlongSurface (either walking or climbing)
#   - Within a node, resting
#   - Moving along a planned edge
#   - In the air, not on a planned edge
#   - On a surface, not on a planned node
# - Add logic to walk to target PositionAlongSurface when in the corresponding mode.
# - Add logic to detect when we've reached the target PositionAlongSurface when moving within node.
# - Add logic to detect when the mode changes.
# - Add logic for each mode (during mode change) to plan the next action according to the current
#   state and target.
# 
# - Define a collection of available movement types.
# - Define an interface for them.
# - Use get_max_upward_movement and get_max_horizontal_movement to get a bounding box and use that
#   in Navigator.get_nearby_surfaces.
# - Have each movement class register itself with Global
# 
# - Implement get_movement_instructions for jumping.
# - Add support for creating EdgeInstructions.
# - Add support for executing EdgeInstructions.
# - Add annotations for the actual trajectories that are defined by EdgeInstructions
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

func _init(nodes: PlatformGraphNodes, player_info: Dictionary) -> void:
    # TODO
    pass
