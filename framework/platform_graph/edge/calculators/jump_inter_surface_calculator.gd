extends EdgeCalculator
class_name JumpInterSurfaceCalculator

const NAME := "JumpInterSurfaceCalculator"
const EDGE_TYPE := EdgeType.JUMP_INTER_SURFACE_EDGE
const IS_A_JUMP_CALCULATOR := true

# FIXME: LEFT OFF HERE: ------------------------------------------------------A
# FIXME: -----------------------------
# 
# - Add a default "selection description" message when nothing is selected:
#   - 
# - Support overriding the description to give more info on the attempted
#   level-click selection.
#   - 
#   - "No possible jump/land positions for that selection."
#   - "No jump/land positions passed broad-phase checks of edge calculation for
#     that selection."
#   - "A valid edge matches that selection."
#   - "A failed edge calculation matches that selection."
# 
# - Ensure all edge DrawUtil functions support rendering the start/end
#   indicators.
# 
# - Fix various edge-cases for debugging edges in inspector top-level edges
#   list:
#   - Other edge types show failed_before_creating_steps or UNKNOWN for
#     edge_result_metadata type.
#   - Some valid fall edges from top platform show error state of out of reach?
#   - Step through inspector and check other cases.
# 
# - Add support for navigating in the inspector directly to the debug edge
#   specified in global.DEBUG_STATE.
# 
# - Deselect and destroy the tree when panel closes.
# 
# - Pick non-random colors for single-annotation items.
# - Choose something other than red to indicate destination/end, since red is
#   used for fail.
# - Step through and consider whether I want to show any other annotations for
#   each item.
# - Step through and consider whether I want to show any other analytic
#   description children for each item.
# - Spend some time thinking through the actual timings of the various parts of
#   calculations (horizontal more than vertical, when possible).
# 
# - Create separate metadata classes for InspectorSearchType metadata.
# 
# - InspectorItemMetadata:
#   - Add new methods to PlatformGraphInspector:
#     - _on_tree_item_expansion_toggled
#     - find_or_create_canonical_surface_item
#     - find_or_create_canonical_edge_or_edge_attempt_item
#   - Refactor other PlatformGraphInspector logic to use these classes.
#   - For now, ignore/disable auto-step-switching timer.
#   - For now, auto-expand valid-edge/failed-edge item when selecting from
#     level clicks.
# 
# - Implement edge-step tree items text, selection, and creation.
# 
# - Add support for rendering annotations for the selected inspector item.
#   - draw_annotations
#   - Do I need to add back references to the corresponding params objects in
#     the result-metadata objects?
#   - And also maybe update DrawUtils and where constants are stored.
#   - And maybe update Colors?
# 
# - Add some additional description items under valid and failed edges with
#   more metadata for debugging.
# 
# - Auto expand UtilityPanel, and auto select the top-level edges item in the
#   PlatformGraphInspector.
# 
# - Add TODOs to use easing curves with all annotation animations.
# 
# - Create FailedEdgeAttempt results from other edge calculators.
# 
# - Refactor pre-existing annotator classes to use the new
#   AnnotationElementType system.
#   - At least remove ExtraAnnotator and replace it with the new
#     general-purpose annotator.
#   - And probably just remove some obsolete annotators.
# 
# - Refactor old color and const systems to use the new
#   AnnotationElementDefaults system.
#   - Colors class.
#   - Look for const values scattered throughout.
# 
# - Don't automatically expand an item when it is selected.
# 
# - Dynamically populate children items and calculate their detailed
#   debugging/annotation information when expanding a parent item.
# - Dynamically destroy children items and their detailed debugging/annotaiton
#   information when collapsing a parent item.
# 
# >- Refactor EdgeCalcResult to be re-used for failed calculations as
#    well.
#    - Remove edge_attempt_debug_results/step_attempt_debug_results from
#      EdgeCalcParams/EdgeStepCalcParams.
#    - Create EdgeCalcResult very early in the process, and plumb it
#      through as input.
#    - Decide what state to persist, and what state to re-calculate when
#      expanding the inspector.
#      - Re-calculate most everything for failed edges, with one small
#        exception:
#        - If we did get deep enough that we thought the jump/land pair might
#          be valid, but we failed at or after trying to calculate
#          EdgeCalcParams, then record a string or enum describing
#          why failure happened. We can think of that as passing the
#          broad-phase check but failing the narrow-phase check.
#        - Then it should be simple enough in the inspector to:
#          - Re-calculate jump/land position pairs.
#          - Then determine whether any of the pairs would have failed the
#            broad-phase check, and where.
#          - Then display a list of all jump/land position pairs for a pair of
#            surfaces, and why each failed (or succeeded).
#          - Allow the narrow-phase fail cases to be expandable, and re-run
#            narrow-phase calculation when expanding them.
#    - Stop using in_debug_mode?
# 
# - Refactor EdgeCalculationAnnotator to not be as tightly coupled to
#   PlatformGraphInspector.
# 
# - Ensure all selection events are connected correctly.
# 
# - Add support for configuring in the menu which edge-type calculator to use
#   with the inspector-selector.
# - And to configure which player to use.
# 
# - Add logic to render dots for the other possible jump/land positions when
#   clicking to select an edge to inspect.
# 
#  - Search for and rename the following:
#    - attempt
# 
# - Fix width issues in inspector.
#   - Should be able to see everything in row.
#   - Shouldn't need to make panel wider or use horizontal scrolling.
# 
# - Add a way to re-display the controls list.
# - Fix the padding in the controls list.
# 
# - Disable the player handling u/d/l/r keys when focus is in the utility
#   panel.
# 
# - Start adding the toggle support for annotations.
# 
# - Phone:
#   - Touch doesn't dismiss panel.
#   - Touch doesn't activate gear icon.
# 
# FIXME: double-check with final structure, then copy over to a comment in the
#        inspector file
# INSPECTOR STRUCTURE:
# - Platform graph [player_name]
#   - Edges [#]
#     - JUMP_INTER_SURFACE_EDGEs [#]
#       - [(x,y), (x,y)]
#         - <FIXME: Add step example items>
#       - ...
#     - ...
#   - Surfaces [#]
#     - Floors [#]
#       - [(x,y), (x,y)]
#         - _# valid outbound edges_
#         - _Destination surfaces:_
#         - FLOOR [(x,y), (x,y)]
#           - JUMP_INTER_SURFACE_EDGEs [#]
#             - [(x,y), (x,y)]
#               - <FIXME: Add step example items>
#             - ...
#             - Failed edge calculations
#               - REASON_FOR_FAILING [(x,y), (x,y)]
#                 - <FIXME: Add step example items>
#               - ...
#         - ...
#       - ...
#     - ...
#   - Global counts
#     - # total surfaces
#     - # total edges
#     - # JUMP_INTER_SURFACE_EDGEs
#     - ...
# 
# --------
# 
# - Analytics!
#   - Figure out how/where to store this.
#     - Don't just keep all step debug state--too much.
#     - In particular, don't keep any PositionAlongSurface references--would
#       break deduping in PlatformGraph.
#   - Log a bit of metadata and duration info on every calculated edge attempt,
#     such as:
#     - number of attempted steps,
#     - types of steps,
#     - number of collisions,
#     - number of backtracking attempts,
#   - Support multiple modes of displaying these analytics:
#     - Global
#     - For a single surface
#     - For a single edge
#     - For a single edge-step attempt?
#       - Should this be listed/nested under the edge mode somehow?
#         - FIXME
#     - Create some way(s) to drill into the non-global lists.
#       - Ctrl+click to select on level?
#         - How to distinguish surface and edge?
#           - FIXME
#         - How to distinguish exactly which edge?
#           - Can probably add a radio button somewhere that indicates at least
#             which _type_ of edge to consider when drilling into an edge.
#           - FIXME
#       - Could also display a list of all relevant drill-downs from the
#         current list's context:
#         - From global mode:
#           - List all surfaces.
#         - From surface mode:
#           - List all valid edges.
#           - List all edge attempts?
#             - FIXME
#           - List all neighbors
#         - From edge mode:
#           - List all step attempts?
#             - FIXME
#     - Dynamically populate (and tear-down) content within this giant tree.
#     - Also, dynamically calculate edge attempts, in order to capture deeper
#       debugging info, when expanding their tree items.
#     - When selecting something by clicking on the level, open the
#       corresponding path in the tree, rather than displaying something new
#       and out of context with the global tree.
#   - Single-surface data structure draft:
#     - 
#   - Single-edge data structure draft:
#     - 
#   - Then put together some interesting aggregations, such as:
#     - time spent calculating each edge,
#     - Avg time spent calculating each different type of edge,
#     - how many collisions on avg for jump/fall,
#     - ...
#   - Try to use these analytics to inform decisions around which calculations
#     are worth it.
#   - Maybe add a new configuration for max number of
#     collisions/intermediate-waypoints to allow in an edge calculation before
#     giving up (or, recursion depth (with and without backtracking))?
#   - Tweak movement_params.exceptional_jump_instruction_duration_increase, and
#     ensure that it is actually cutting down on the number of times we have to
#     backtrack.
# 
# - Re-implement/use DEBUG_MODE flag:
#   - Switch some MovementParam values when it's on:
#     - syncs_player_velocity_to_edge_trajectory
#     - ACTUALLY, maybe just implement another version of CatPlayer that only
#       has MovementParams as different, then it's easy to toggle.
#       - Would need to make it easy to re-use same animator logic though...
#   - Switch which annotations are used.
#   - Switch which level is used?
# 
# - When "backtracking" for height, re-use all previous waypoints, but reset
#   their times and maybe velocities.
#   - This should actually mean that we no longer "backtrack"/recurse
#     specially.
#   - Conditionally use this approach behind a movement_params flag. This
#     should improve efficiency and decrease accuracy.
#   - Then also add another flag for whether to run a final collision test over
#     the combined steps after calculating the result.
#     - This should be useful, since we'll want to ensure that such
#       calculations don't produce false positives.
# 
# - Debug performance with how many jump/land pairs get returned, and how
#   costly the new extra previous-jump/land-position-distance checks are.
# 
# - Debug all the new jump/land optimization logic.
# 
# - Finish logic to consume Waypoint.needs_extra_jump_duration.
#   - Started, but stopped partway through, with adding this usage in
#     _update_waypoint_velocity_and_time.
# 
# - Check on current behavior of
#   EdgeInstructionsUtils.JUMP_DURATION_INCREASE_EPSILON and 
#   EdgeInstructionsUtils.MOVE_SIDEWAYS_DURATION_INCREASE_EPSILON.
# 
# --- Debug ---
# 
# - Check whether the dynamic edge optimizations are too expensive.
# 
# - Things to debug:
#   - Jumping from floor of lower-small-block to floor of upper-small-black.
#     - Collision detection isn't correctly detecting the collision with the
#       right-side of the upper block.
#   - Jumping from floor of lower-small-block to far right-wall of
#     upper-small-black.
#   - Jumping from left-wall of upper-small-block to right-wall of
#     upper-small-block.
# 
# >>- Fix how things work when minimizes_velocity_change_when_jumping is true.
#   - [no] Find and move all movement-offset constants to one central location?
#     - EdgeInstructionsUtils
#     - WaypointUtils
#     - FrameCollisionCheckUtils
#     - EdgeCalcParams
#   >>>- Compare where instructions are pressed/released vs when I expect them.
#   - Step through movement along an edge?
#   >>- Should this be when I implement the logic to force the player's
#     position to match the expected edge positions (with a weighted avg)?
# 
# - Debug edges.
#   - Calculation: Check all edge-cases; look at all expected edge trajectories
#     in each level.
#   - Execution: Check that navigation actually follows paths and executes
#     trajectories as expected.
# 
# - Debug why this edge calculation generates 35 steps...
#   - test_level_long_rise
#   - from top-most floor to bottom-most (wide) floor, on the right side
# 
# - Fix frame collision detection...
#   - Seeing pre-existing collisions when jumping from walls.
#   - Fix collision-detection errors from logs.
#   - Go through levels and verify that all expected edges work.
# 
# - Fix issue where jumping around edge sometimes isn't going far enough; it's
#   clipping the corner.
# 
# - Re-visit GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
# 
# - Fix performance.
#   - Should I almost never be actually storing things in Pool arrays? It seems
#     like I mostly end up passing them around as arguments to functions, to
#     they get copied as values...
# 
# - Adjust cat_params to only allow subsets of EdgeCalculators, in
#   order to test the non-jump edges
# 
# - Test/debug FallMovementUtils.find_a_landing_trajectory (when clicking from
#   an air position).
# 
# --- EASIER BITS ---
# 
# - Figure out how to fix scaling/aliasing in Godot when adjusting to different
#   screen sizes and camera zoom.
# 
# - Update level images:
#   - Make background layers more faded
#   - Make foreground images more wood-like
# 
# - Implement the bits of utility-menu UI to toggle annotations.
#   - Also support adjusting how many previous player positions to render.
#   - Also list controls in the utility menu.
#   - Collision calculation annotator bits.
#   - Add a top-level button to utility menu to hide all annotations.
#     - (grid, clicks, player position, player recent movement, platform graph,
#       ...)
#   - Toggle whether the legend (and current selection description) is shown.
#   - Also, update the legend as annotations are toggled.
# 
# - Think up ways to make the debug annotations more
#   dynamic/intelligent/useful...
#   - Make jump/land positions (along with start v, and which pairs connect)
#     more discoverable when ctrl+clicking.
#   - A mode to dynamically show next edge debug state while navigating a path?
#     - Maybe the goal here should be to make all the the complexity of the
#       graph/waypoints/alternative-or-failed-branches somehow visible or
#       understandable to others with a quick viewing.
#   - Have a mode that hides all the other background, foreground, and player
#     images, so that we can just show the annotations.
# 
# - Include other items in the legend:
#   - Step items:
#     - Fake waypoint?
#     - Invalid waypoint?
#     - Collision boundary at moment of collision
#     - Collision debugging: previous frame, current frame, next frame boundaries
#     - Mid waypoints?
#   - Navigator path (current and previous)
#   - Recent movement
# 
# - In the README, list the types of MovementParams.
# 
# - Prepare a different, more interesting level for demo (some walls connecting
#   to floors too).
# 
# - Put together some illustrative screenshots with special one-off annotations
#   to explain the graph parsing steps in the README.
#   - Use global.DEBUG_PARAMS.extra_annotations
#   - Screenshots:
#     - A couple surfaces
#     - Show different tiles, to illustrate how surfaces get merged.
#     - All surfaces (different colors)
#     - A couple edges
#     - All edges
#     - 
# 
# - Update panel styling.
#   - Flat.
#   - Square corners.
#   - Probably should do this with Godot theming...
# 
# ---  ---
# 
# - Add squirrel assets and animation.
#   - Start by copying-over the Piskel squirrel animation art.
#   - Create squirrel parts art in Aseprite.
#   - Create squirrel animation key frames in Godot.
#     - Idle, standing
#     - Idle, climbing
#     - Crawl-walk-sniff
#     - Bounding walk
#     - Climbing up
#     - Climbing down (just run climbing-up in reverse? Probably want to bound
#       down, facing down, as opposed to cat. Will make transition weird, but
#       whatever?)
#     - 
# 
# ---  ---
# 
# - Loading screen
#   - While downloading, and while parsing level graph
#   - Hand-animated pixel art
#   - Simple GIF file
#   - Host/load/show separately from the rest of the JavaScript and assets
#   - Squirrels digging-up/eating tulips
# 
# - Welcome screen
#   - Hand-animated pixel art
#   x- Gratuitous whooshy sliding shine and a sparkle at the end
#   x- With squirrels running and climbing over the letters?
#   >- Approach:
#     - Start simple. Pick font. Render in Inkscape. Create a hand-pixel-drawn
#       copy in Aseprite.
#     - V1: Show "Squirrel Away" text. Animate squirrel running across, right
#           to left, in front of letters.
#     - V2: Have squirrel pause to the left of the S, with its tail overlapping
#           the S. Give a couple tail twitches. Then have squirrel leave.
#     
# ---  ---
# 
# - Add better annotation selection.
#   - Add shortcuts for toggling debugging annotations
#     - Add support for triggering the calc-step annotations based on a
#       shortcut.
#       - i
#       - also, require clicking on the start and end positions in order to
#         select which edge to debug.
#         - Use this _in addition to_ the current top-level configuration for
#           specifying which edge to calculate?
#       - also, then only actually calculate the edge debug state when using
#         this click-to-specify debug mode.
#     - also, add other shortcuts for toggling other annotations:
#       - whether all surfaces are highlighted
#       - whether the player's position+collision boundary are rendered
#       - whether the player's current surface is rendered
#       - whether all edges are rendered
#       - whether grid boundaries+indices are rendered
#       - whether the ruler is rendered
#       - whether the actual level tilemap is rendered
#       - whether the background is rendered
#       - whether the actual players are rendered
#     - create a collapsible dat.GUI-esque menu at the top-right that lists all
#       the possible annotation configuration options.
#       - set up a nice API for creating these, setting values, listening for
#         value changes, and defining keyboard shortcuts.
#   - Use InputMap to programatically add keybindings.
#     - This should enable our framework to setup all the shortcuts it cares
#       about, without consumers needing to ever redeclare anything in their
#       project settings.
#     - This should also enable better API design for configuring keybindings
#       and menu items from the same place.
#     - https://godot-es-docs.readthedocs.io/en/latest/classes/
#               class_inputmap.html#class-inputmap
# 
# - Finish remaining surface-closest-point-jump-off calculation cases.
#   - Also, maybe still not quite far enough with the offset?
# 
# - Implement fall-through/walk-through movement-type utils.
# 
# - Cleanup frame_collison_check_utils:
#   - Clean-up/break-apart/simplify current logic.
#   - Maybe add some old ideas for extra improvements to
#     check_frame_for_collision:
#     - [maybe?] Rather than just using closest_intersection_point, sort all
#       intersection_points, and try each of them in sequence when the first
#       one fails	
#     - [easy to add, might be nice for future] If that also fails, use a
#       completely separate new cheap-and-dirty check-for-collision-in-frame
#       method?	
#       - Check if intersection_points is not-empty.
#       - Sort them by closest in direction of motion (and ignoring behind
#         points).
#       - Iterate through points, trying to get tile index by a slight nudge
#         offset from each
#         intersection point in the direction of motion until one sticks.
#       - Choose surface side just from dominant motion component.
#     - Add a field on the collision class for the type of collision check
#       used.
#     - Add another field (or another option for the above field) to indicate
#       that none of the collision checks worked, and this collision is in an
#       error state.
#     - Use this error state to abort collision/step/edge calculations (rather
#       than the current approach of returning null, which is the same as with
#       not detecting any collisions at all).
#     - It might be worth adding a check before ray-tracing to check whether
#       the starting point is_far_enough_from_other_jump_land_positionslies
#       within a populated tile in the tilemap, and then trying the other
#       perpendicular offset direction if so. However, this would require
#       configuring a single global tile map that we expect collisions from,
#       and plumbing that tile map through to here.
# 
# - Look into themes, and what default/global theme state I should set up.
# - Look into what sort of anti-aliasing and scaling to do with GUI vs level vs
#   camera/window zoom...
# 
# - Fix the behavior that causes vertical movement along a wall to get sucked
#   slightly toward the wall after passing the end of the wall (assuming the
#   motion was actually touching the wall).
#   - This is not caused by my logic; it's a property of the underlying Godot
#     collision engine.
# 
# - Add a configurable method to the MovementParams API for defining arbitrary
#   weight calculation for each character type (it could do things like
#   strongly prefer certain edge types). 
# 
# - Check FIXMEs in CollisionCheckUtils. We should check on their accuracy now.
# 
# - Add some sort of warning message when the player's run-time velocity is too
#   far from what's expected?
# 
# - Switch to built-in Godot gradients for surface annotations.
# 
# - Create another annotator to indicate the current navigation destination
#   more boldly.
#   - After selecting the destination, animate the surface and position
#     indicator annotations downward (and inward) onto the surface, and then
#     have the position indicator stay there until navigation is done (pulsing
#     indicator with opacity and size (use sin wave) and pulsing overlapping
#     two/three repeating outward-growing surface ellipses).
#   - Use some sort of pulsing/growing elliptical gradient from the position
#     indicator along the nearby surface face.
#     - Will have to be a custom radial gradient:
#       - https://github.com/Maujoe/godot-custom-gradient-texture/blob/master/
#              assets/maujoe.custom_gradient_texture/custom_gradient_texture.gd
#     - Will probably want to create a texture out of this radial gradient, set
#       the texture to not repeat, render the texture offset within a
#       transparent rectangle, then just animate the UV coordinates.
# 
# - [or skip? (should be fixed when turning on v sync)] Fix a bug where jump
#   falls way short; from right-end of short-low floor to bottom-end of
#   short-high-right-side wall.
# 



func _init().( \
        NAME, \
        EDGE_TYPE, \
        IS_A_JUMP_CALCULATOR) -> void:
    pass

func get_can_traverse_from_surface(surface: Surface) -> bool:
    return surface != null

func get_all_inter_surface_edges_from_surface( \
        edges_result: Array, \
        failed_edge_attempts_result: Array, \
        collision_params: CollisionCalcParams, \
        surfaces_in_fall_range_set: Dictionary, \
        surfaces_in_jump_range_set: Dictionary, \
        origin_surface: Surface) -> void:
    var movement_params := collision_params.movement_params
    var debug_params := collision_params.debug_params
    
    var jump_land_position_results_for_destination_surface := []
    var jump_land_positions_to_consider: Array
    var edge_result_metadata: EdgeCalcResultMetadata
    var failed_attempt: FailedEdgeAttempt
    var edge: JumpInterSurfaceEdge
    
    for destination_surface in surfaces_in_jump_range_set:
        # This makes the assumption that traversing through any
        # fall-through/walk-through surface would be better handled by some
        # other Movement type, so we don't handle those cases here.
        
        #######################################################################
        # Allow for debug mode to limit the scope of what's calculated.
        if EdgeCalculator.should_skip_edge_calculation( \
                debug_params, \
                origin_surface, \
                destination_surface):
            continue
        #######################################################################
        
        if origin_surface == destination_surface:
            # We don't need to calculate edges for the degenerate case.
            continue
        
        jump_land_position_results_for_destination_surface.clear()
        
        jump_land_positions_to_consider = JumpLandPositionsUtils \
                .calculate_jump_land_positions_for_surface_pair( \
                        movement_params, \
                        origin_surface, \
                        destination_surface, \
                        self.is_a_jump_calculator)
        
        for jump_land_positions in jump_land_positions_to_consider:
            ###################################################################
            # Allow for debug mode to limit the scope of what's calculated.
            if EdgeCalculator.should_skip_edge_calculation( \
                    debug_params, \
                    jump_land_positions.jump_position, \
                    jump_land_positions.land_position):
                continue
            
            # Record some extra debug state when we're limiting calculations to
            # a single edge (which must be this edge).
            var record_calc_details: bool = \
                    debug_params.has("limit_parsing") and \
                    debug_params.limit_parsing.has("edge") and \
                    debug_params.limit_parsing.edge.has("origin") and \
                    debug_params.limit_parsing.edge.origin.has( \
                            "position") and \
                    debug_params.limit_parsing.edge.has("destination") and \
                    debug_params.limit_parsing.edge.destination.has("position")
            ###################################################################
            
            if jump_land_positions.less_likely_to_be_valid and \
                    movement_params.skips_less_likely_jump_land_positions:
                continue
            
            if !jump_land_positions.is_far_enough_from_others( \
                    movement_params, \
                    jump_land_position_results_for_destination_surface, \
                    true, \
                    true):
                # We've already found a valid edge with a land position that's
                # close enough to this land position.
                continue
            
            edge_result_metadata = \
                    EdgeCalcResultMetadata.new(record_calc_details)
            
            edge = calculate_edge( \
                    edge_result_metadata, \
                    collision_params, \
                    jump_land_positions.jump_position, \
                    jump_land_positions.land_position, \
                    jump_land_positions.velocity_start, \
                    jump_land_positions.needs_extra_jump_duration, \
                    jump_land_positions.needs_extra_wall_land_horizontal_speed)
            
            if edge != null:
                # Can reach land position from jump position.
                edges_result.push_back(edge)
                edge = null
                jump_land_position_results_for_destination_surface.push_back( \
                        jump_land_positions)
            else:
                failed_attempt = FailedEdgeAttempt.new( \
                        origin_surface, \
                        destination_surface, \
                        jump_land_positions.jump_position.target_point, \
                        jump_land_positions.land_position.target_point, \
                        jump_land_positions.velocity_start, \
                        edge_type, \
                        edge_result_metadata.edge_calc_result_type, \
                        edge_result_metadata.waypoint_validity, \
                        jump_land_positions.needs_extra_jump_duration, \
                        jump_land_positions.needs_extra_wall_land_horizontal_speed, \
                        self)
                failed_edge_attempts_result.push_back(failed_attempt)

func calculate_edge( \
        edge_result_metadata: EdgeCalcResultMetadata, \
        collision_params: CollisionCalcParams, \
        position_start: PositionAlongSurface, \
        position_end: PositionAlongSurface, \
        velocity_start := Vector2.INF, \
        needs_extra_jump_duration := false, \
        needs_extra_wall_land_horizontal_speed := false) -> Edge:
    edge_result_metadata = \
            edge_result_metadata if \
            edge_result_metadata != null else \
            EdgeCalcResultMetadata.new(false)
    
    var edge_calc_params := \
            EdgeCalculator.create_edge_calc_params( \
                    edge_result_metadata, \
                    collision_params, \
                    position_start, \
                    position_end, \
                    true, \
                    velocity_start, \
                    needs_extra_jump_duration, \
                    needs_extra_wall_land_horizontal_speed)
    if edge_calc_params == null:
        # Cannot reach destination from origin.
        return null
    
    return create_edge_from_edge_calc_params( \
            edge_result_metadata, \
            edge_calc_params)

func optimize_edge_jump_position_for_path( \
        collision_params: CollisionCalcParams, \
        path: PlatformGraphPath, \
        edge_index: int, \
        previous_velocity_end_x: float, \
        previous_edge: IntraSurfaceEdge, \
        edge: Edge) -> void:
    assert(edge is JumpInterSurfaceEdge)
    
    EdgeCalculator.optimize_edge_jump_position_for_path_helper( \
            collision_params, \
            path, \
            edge_index, \
            previous_velocity_end_x, \
            previous_edge, \
            edge, \
            self)

func optimize_edge_land_position_for_path( \
        collision_params: CollisionCalcParams, \
        path: PlatformGraphPath, \
        edge_index: int, \
        edge: Edge, \
        next_edge: IntraSurfaceEdge) -> void:
    assert(edge is JumpInterSurfaceEdge)
    
    EdgeCalculator.optimize_edge_land_position_for_path_helper( \
            collision_params, \
            path, \
            edge_index, \
            edge, \
            next_edge, \
            self)

func create_edge_from_edge_calc_params( \
        edge_result_metadata: EdgeCalcResultMetadata, \
        edge_calc_params: EdgeCalcParams) -> \
        JumpInterSurfaceEdge:
    var calc_result := \
            EdgeStepUtils.calculate_steps_with_new_jump_height( \
                    edge_result_metadata, \
                    edge_calc_params, \
                    null, \
                    null)
    if calc_result == null:
        # Unable to calculate a valid edge.
        return null
    
    var instructions := EdgeInstructionsUtils \
            .convert_calculation_steps_to_movement_instructions( \
                    calc_result, \
                    true, \
                    edge_calc_params.destination_position.surface.side)
    var trajectory := EdgeTrajectoryUtils \
            .calculate_trajectory_from_calculation_steps( \
                    calc_result, \
                    instructions)
    
    var velocity_end: Vector2 = \
            calc_result.horizontal_steps.back().velocity_step_end
    
    var edge := JumpInterSurfaceEdge.new( \
            self, \
            edge_calc_params.origin_position, \
            edge_calc_params.destination_position, \
            edge_calc_params.velocity_start, \
            velocity_end, \
            edge_calc_params.needs_extra_jump_duration, \
            edge_calc_params.needs_extra_wall_land_horizontal_speed, \
            edge_calc_params.movement_params, \
            instructions, \
            trajectory)
    
    return edge
