extends IntegrationTestBed

# FIXME: LEFT OFF HERE: -------------------------------------------------A: Tests!
# - Big list of all cases to test:
#   >- calculate_jump_land_positions_for_surface_pair:
#     - Add a bunch of very simple test levels, with just two platforms each, and the two in
#       various alignments from each other.
#       - Cover all of the different jump/land surface type/spatial-arrangement combinations that
#         are considered for jump/land position calculations.
#     - Right numbers and combinations of jump-land pair results.
#   - Jump/land optimization logic.
#   - Edge calculation logic.
#   - Things under platform_graph/edge/edge_calculators
#   - Things under platform_graph/edge/edges
#   - Things under platform_graph/edge/utils
#   - Things under platform_graph/surface
#   - Navigator
#   - PlatformGraph
#   - Player
#   - Things under player/action
#   - Things under player/action/action_handlers
#   - Everything under utils/
# - Don't be brittle, with specific numbers; test simple high-level/relative things like:
#   - One edge from here to here
#   - Edge was long enough
#   - Had right number of waypoints
#   - Had at least the right height
#   - PlatformGraph chose a path of the correct edges
#   - Jump/land position calculations return the right positions
#   - Which other helper/utility functions to unit test in isolation...
# - While adding tests, also debug.
# - Plan what sort of helpers and testbed infrastructure we'll need.
# - Adapt/discard the earlier, brittle, implementation-specific tests.

func test_foo() -> void:
    # FIXME
    assert_eq(true, true)
