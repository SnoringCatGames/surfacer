extends Node
class_name Main

###############################################################################
### MAIN TODO LIST: ###
# 
# - Add somewhat general support for custom computed/assigned metrics in
#   top-level Profiler.
#   - Will want to be able to show either single value or
#     avg/min/max/count/total.
#   - Things to show:
#     - Avg/min/max number of jump/land destination surfaces from an origin
#       surface.
#       - Probably want support to cut off occluded lower surfaces at some
#         point?
#     - Avg/min/max number of some "events" from individual edge calcs.
#       - collisions, recursions, ...
#     - 
#     -
# 
# - Profiler!
#   - Step through and consider whether I want to show any other analytic
#     description children for each item.
#   - Try to use these analytics to inform decisions around which calculations
#     are worth it.
#     - Figure out exactly which part of collision calculations is most
#       expensive, and determine whether we can cut down on it.
#       - Any particular Godot API that's expensive?
#       - Or are we just running too many collision calls in general?
#       - In check_continuous_horizontal_step_for_collision, can we maybe only
#         run collision checks on every nth frame (while still recording
#         position/velocity per-frame), and just approximating collision checks
#         with the cumulative displacement across those n frames?
#         - We'd probably then need some way of fixing/ignoring/undoing
#           unexpected collisions with the level at run time, and forcing state
#           to match what's expected from the approximations?
#         - This sounds like a hairy approach...
#     - Maybe add a new configuration for max number of
#       collisions/intermediate-waypoints to allow in an edge calculation
#       before giving up (or, recursion depth (with and without backtracking))?
#     - Tweak movement_params.exceptional_jump_instruction_duration_increase,
#       and ensure that it is actually cutting down on the number of times we
#       have to backtrack.
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
# - Think up ways to make some debug annotations more
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
# - In the README, list the types of MovementParams.
# 
# - Prepare a different, more interesting level for demo (some walls connecting
#   to floors too).
# 
# - Put together some illustrative screenshots with special one-off annotations
#   to explain the graph parsing steps in the README.
#   - Use Config.DEBUG_PARAMS.extra_annotations
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
# >- A* search should abandon search of it gets to far out of the way (rather
#   than exhaustively searching the whole level)
#   - I think this could work with an allowed max distance/weight threshold
#     that is a ratio of the straight distance between origin and destination.
#   - As soon as current frontier surpasses the threshold, give up.
# 
# >- HUGE runtime optimization:
#   - We know after parsing the platform graph at build time exactly what the
#     trajectories should always look like.
#   - In the event of unexpected runtime results that disagree with the
#     build-time results, we essentially want to always ignore the runtime
#     results and force state to match what is expected from the build-time
#     calculations.
#   - Therefore, we shouldn't ever even execute runtime calculations.
#   - We should instead just force state to match the precalculated
#     trajectories.
#   - We wouldn't be able to disable the normal Godot collision system if we
#     still want the Player to be imperatively human-controlled though.
# 
# ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---
# 
# - Add a movement_param for edge fall distance threshold.
# - Add a movement_param for ignoring vertically occluded surfaces when
#   calculating fall range surfaces.
#   - Don't consider "jump-up" range surfaces as occluding though, since that
#     could yield gals negatives.
#     - But that should be easy, since that geometry is considered later
#       anyway.
#   - This should be simple enough to do, by keeping track of x-dimension
#     ranges that are already consumed, and just making sure that any new
#     surface being considered intersects with one of the remaining valid
#     ranges.
# 
# - Improve annotation configuration.
#   - Implement the bits of utility-menu UI to toggle annotations.
#     - Add support for configuring in the menu which edge-type calculator to
#       use with the inspector-selector.
#     - And to configure which player to use.
#     - Add a way to re-display the controls list.
#     - Also support adjusting how many previous player positions to render.
#     - Also list controls in the utility menu.
#     - Collision calculation annotator bits.
#     - Add a top-level button to utility menu to hide all annotations.
#       - (grid, clicks, player position, player recent movement, platform
#         graph, ...)
#     - Toggle whether the legend (and current selection description) is shown.
#     - Also, update the legend as annotations are toggled.
#   - Include other items in the legend:
#     - Step items:
#       - Fake waypoint?
#       - Invalid waypoint?
#       - Collision boundary at moment of collision
#       - Collision debugging: previous frame, current frame, next frame
#         boundaries
#       - Mid waypoints?
#     - Navigator path (current and previous)
#     - Recent movement
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
# - Add TODOs to use easing curves with all annotation animations.
# 

###############################################################################













###############################################################################

# TODO: Older master list (was in platform_graph.gd):
#
# - Finish everything in JumpInterSurfaceCalculator (edge calculations,
#   including movement waypoints from interfering surfaces).
# - Finish/polish fallable surfaces calculations (and remove old obsolete
#   functions).
#
# - Use max_horizontal_jump_distance and max_upward_jump_distance.
# 
# - Fix some aggregate return types to be Array instead of Vector2.
#
# - Add annotations that draw the recent path that the player actually moved.
# - Add annotations for rendering some basic navigation mode info for the CP:
#   - Mode name
#   - Current "input" (UP, LEFT, etc.)?
#   - The entirety of the current instruction-set being run?
#
# - Add logic to consider a minimum movement distance, since jumping from
#   floors or walls gives a set minimum displacement.
#
# - Add logic to test execution of TestPlayer movement over _every_ edge in a
#   complex, hand-made test level.
#   - Make sure that the player hits the correct destination surface without
#     hitting any other surface on-route.
#   - Also test that the player lands on the destination within a threshold of
#     the expected position.
#   - Will need to figure out how to emulate/manipulate time deltas for the
#     test environment...
#
# - Add logic to automatically self-correct to the expected
#   position/movement/state sometimes...
#   - When? Each frame? Only when we're further away than our tolerance allows?
#
# - Add support for actually considering the discrete physics time steps rather
#   than assuming continuous integration?
#   - OR, add support for fudging it?
#     - I could calculate and emulate all of this as previously planned to be
#       realistic and use the same rules as a HumanPlayer; BUT, then actually
#       adjust the movement to matchup with the expected pre-calculated result
#       (so, actually, not really run the instructions set at all?)
#     - It's probably at least worth adding an optional mode that does this and
#       comparing the performance.
#     - Or would something like a
#       GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION (~0.9985?) param
#       fix things enough?
#
# - Add integration tests:
#   - These should be much easier to write and maintain than the unit tests.
#   - These should start with:
#     - One player type (other types shouldn't be instantiated or considered by
#       any logic at all)
#     - A level that could be either simple or complicated.
#     - We should be able to configure from the test the specific starting and
#       ending surface and position to check.
#       - This should then cause the PlatformGraph parsing and
#         get_all_inter_surface_edges_from_surface parsing to skip all other
#         surfaces and jump/land positions.
#     - We should use the above configuration to target specific interesting
#       edge use-cases.
#       - Skipping waypoints
#       - Left/right/ceiling/floor intermediate surfaces
#         - And then passing on min/max side of those surfaces
#       - Zigzagging between a couple consecutive intermediate surfaces
#         - While moving upward, downward, leftward, rightward
#       - Jumping up around side of block to top
#       - Jumping down around top of block to side
#       - Jumping when a non-minimum step-end x velocity is needed
#       - Needing vertical backtracking
#       - Needing to press side-movement input in opposite direction of
#         movement in order to slow velocity along the step.
#       - Falling a long vertical distance, to test the fallable surfaces logic
#       - Jumping a long horizontal distance, to test the reachable surfaces
#         logic
#       - Surface-to-surface
#       - Surface-to-air
#       - Air-to-surface
#       - wall to wall
#       - floor to wall
#       - wall to floor
#       - Starting on convex and concave corners between adjacent surfaces, so
#         that the collision margin considers the other surfaces as already
#         colliding beforehand.
#
# - Refactor Movement classes, so that whether the start and end posiition is
#   on a platform or in the air is configuration that
#   JumpInterSurfaceCalculator handles directly, rather than relying on a
#   separate FallFromAir class?
# - Add support for including walls in our navigation.
# - Add support for other jump aspects:
#   - Fast fall
#   - Variable jump height
#   - Double jump
#   - Horizontal acceleration?
#
# - Update the pre-configured Input Map in Project Settings to use more
#   semantic keys instead of just up/down/etc.
# - Document in a separate markdown file exactly which Input Map keys this
#   framework depends on.
#
# - Make get_surfaces_in_jump_and_fall_range more efficient? (force run it
#   every frame to ensure no lag)
#   - Scrap previous function; just use bounding box intersection (since I'm
#     going to need to use better logic for determining movement patterns
#     anyway...)
#   - Actually, maybe don't worry too much, because this is actually only run
#     at the start.
#
# - Add logic to Player when calculating touched edges to check that the
#   collider is a stationary TileMap object.
#
# - Figure out how to configure input names/mappings (or just add docs
#   specifying that the consumer must use these input names?).
# - Start adding networking support.
# - Finish adding tests.
#
# - Add an early-cutoff mechanism to A* for paths that deviate too far from
#   straight-line. Otherwise, it will check every connecected surface before
#   knowing that a destination cannot be reached.
#   - Or look at number of surfaces visited instead of straight-line deviation?
#   - Cons:
#     - Can miss valid paths if they deviate too far.
# - OR, use djikstra's algorithm, and always store every path to/from every
#   other surface?
#   - Cons:
#     - Takes more space (maybe ok?).
#     - Too expensive if the map ever changes dynamically.
#       - Unless I have a way of localizing changes.
# 
# - Update things to support falling from the center of fall-through surfaces
#   (consider the whole surface, rather than just the ends).
# 
# - Refactor the movement/navigation system to support more custom behaviors
#   (e.g., some classic video game movements, like walking to the edge and then
#   turning around, circling the entire circumference, bouncing forward, etc.).


# TODO: (old notes from jump_from_platform_movement) SUB-MASTER LIST *********
# 
# - Add support for specifying a required min/max end-x-velocity.
#   - More notes in the backtracking method.
# - Test support for specifying a required min/max end-x-velocity.
# 
# - LEFT OFF HERE: Resolve/debug all left-off commented-out places.
# - LEFT OFF HERE: Check for other obvious false negative edges.
# 
# - LEFT OFF HERE: Implement/test edge-traversal movement:
#   - Test the logic for moving along a path.
#   - Add support for sending the CPU to a click target (configured in the
#     specific level).
#   - Add support for picking random surfaces or points-in-space to move the
#     CPU to; resetting to a new point after the CPU reaches the old point.
#     - Implement this as an alternative to ClickToNavigate (actually, support
#       both running at the same time).
#     - It will need to listen for when the navigator has reached the
#       destination though (make sure that signal is emitted).
# - LEFT OFF HERE: Create a demo level to showcase lots of interesting edges.
# - LEFT OFF HERE: Check for other obvious false negative edges.
# - LEFT OFF HERE: Debug why discrete movement trajectories are incorrect.
#   - Discrete trajectories are definitely peaking higher; should we cut the
#     jump button sooner?
#   - Not considering continous max vertical velocity might contribute to
#     discrete vertical movement stopping short.
# - LEFT OFF HERE: Debug/stress-test intermediate collision scenarios.
#   - After fixing max vertical velocity, is there anything else I can boost?
# - LEFT OFF HERE: Debug why check_instructions_for_collision fails with
#   collisions (render better annotations?).
# - LEFT OFF HERE: Add squirrel animation.
# 
# - Debugging:
#   - Would it help to add some quick and easy annotation helpers for temp
#     debugging that I can access on global (or wherever) and just tell to
#     render dots/lines/circles?
#   - Then I could use that to render all sorts of temp calculation stuff from
#     this file.
#   - Add an annotation for tracing the players recent center positions.
#   - Try rendering a path for trajectory that's closer to the calculations for
#     parabolic motion instead of the resulting instruction positions?
#     - Might help to see the significance of the difference.
#     - Might be able to do this with smaller step sizes?
# 
# - Problem: What if we hit a ceiling surface (still moving upwards)?
#   - We'll set a waypoint to either side.
#   - Then we'll likely need to backtrack to use a bigger jump height.
#   - On the backtracking traversal, we'll hit the same surface again.
#     - Solution: We should always be allowed to hit ceiling surfaces again.
#       - Which surfaces _aren't_ we allowed to hit again?
#         - floor, left_wall, right_wall
#       - Important: Double-check that if collision clips a static-collidable
#         corner, that the correct surface is returned
# - Problem: If we allow hitting a ceiling surface repeatedly, what happens if
#   a jump rise cannot get around it (cannot move horizontally far enough
#   during the rise)?
#   - Solution: Afer calculating waypoints for a surface collision, if it's a
#     ceiling surface, check whether the time to move horizontally exceeds the
#     time to move upward for either waypoint. If so, abandon that traversal
#     (remove the waypoint from the array before calling the sub function).
# - Optimization: We should never consider increased-height backtracking from
#   hitting a ceiling surface.
# 
# - Create a pause menu and a level switcher.
# - Create some sort of configuration for specifying a level as well as the set
#   of annotations to use.
#   - Actually use this from the menu's level switcher.
#   - Or should the level itself specify which annotations to use?
# - Adapt one of the levels to just render a human player and then the
#   annotations for all edges that our algorithm thinks the human player can
#   traverse.
#   - Try to render all of the interesting edge pairs that I think I should
#     test for.
# 
# - Step through and double-check each return value parameter individually
#   through the recursion, and each input parameter.
# 
# - Optimize a bit for collisions with vertical surfaces:
#   - For the top waypoint, change the waypoint position to instead use the far
#     side of the adjacent top-side/floor surface.
#   - This probably means I should store adjacent Surfaces when originally
#     parsing the Surfaces.
# - Step through all parts and re-check for correctness.
# - Account for half-width/height offset needed to clear the edge of B (if
#   possible).
# - Also, account for the half-width/height offset needed to not fall onto A.
# - Include a margin around waypoints and land position.
# - Allow for the player to bump into walls/ceiling if they could still reach
#   the land point afterward (will need to update logic to not include margin
#   when accounting for these hits).
# - Update the instructions calculations to consider actual discrete timesteps
#   rather than using continuous algorithms.
# - Share per-frame state updates logic between the instruction calculations
#   and actual Player movements.
# - Problem: We need to make sure that we still have enough momementum left
#   once we hit the target position to actually cause us to grab on to the
#   target surface.
#   - Solution: Add support for ensuring a minimum normal-direction speed at
#     the end of the jump.
#     - Faster is probably always better, since efficient/quick movements are
#       better.
# 
# - Problem: All of the edge calculations will allow the slow-rise gravity to
#   also be used for the downward portion of the jump.
#   - Either update Player controllers to also allow that,
#   - or update all relevant edge calculation logic.
# 
# - Make some diagrams in InkScape with surfaces, trajectories, and waypoints
#   to demonstrate algorithm traversal
#   - Label/color-code parts to demonstrate separate traversal steps
# - Make the 144-cell diagram in InkScape and add to docs.
# - Storing possibly 9 edges from A to B.
# 
# FIXME: C:
# - Set the destination_waypoint min_velocity_x and max_velocity_x at the
#   start, in order to latch onto the target surface.
#   - Also add support for specifying min/max y velocities for this?
# 
# FIXME: B:
# - Should we more explicity re-use all horizontal steps from before the jump
#   button was released?
#   - It might simplify the logic for checking for previously collided
#     surfaces, and make things more efficient.
# 
# FIXME: B: Check if we need to update following waypoints when creating a new
#   one:
# - Unfortunately, it is possible that the creation of a new intermediate
#   waypoint could invalidate the actual_velocity_x for the following
#   waypoint(s). A fix for this would be to first recalculate the min/max x
#   velocities for all following waypoints in forward order, and then
#   recalculate the actual x velocity for all following waypoints in reverse
#   order.
# 
# FIXME: B: 
# - Make edge-calc annotations usable at run time, by clicking on the start and
#   end positions to check.
# 




# TODO: 
# 
# #########
# 
# - Try adding other edges now:
#   - 
# 
# - Add some sort of heuristic to choose when to go with smaller or larger velocity end during
#   horizontal step calc.
#   - The alternative, is to once again flip the order we calculate steps, so that we base all
#     steps off of minimizing the x velocity at the destination.
#     - :/ We might want to do that anyway though, to give us more flexibility later when we want
#       to be able to specify a given non-zero target end velocity.
# 
# - Should I move some of the horizontal movement functions from waypoint_utils to
#   horizontal_movement_utils?
# 
# - Can I render something in the annotations (or in the console output) like the waypoint
#   position or the surface end positions, in order to make it easier to quickly set a breakpoint
#   to match the corresponding step?
# 
# - Debug, debug, debug...
# 
# - Additional_high_waypoint_position breakpoint is happening three times??
#   - Should I move the fail-because-we've-been-here-before logic from looking at
#     steps+surfaces+heights to here?
# 
# - Should we somehow ensure that jump height is always bumped up at least enough to cover the
#   extra distance of waypoint offsets? 
#   - Since jumping up to a destination, around the other edge of the platform (which has the
#     waypoint offset), seems like a common use-case, this would probably be a useful optimization.
#   - [This is important, since the first attempt at getting to the top-right waypoint always
#     fails, since it requires a _slightly_ higher jump, and we want it to instead succeed.]
# 
# - There is a problem with my approach for using time_to_get_to_destination_from_waypoint.
#   time-to-get-to-intermediate-waypoint-from-waypoint could matter a lot too. But maybe this
#   is infrequent enough that I don't care? At least document this limitation (in code and README).
# 
# - Add logic to ignore a waypoint when the horizontal steps leading up to it would have found
#   another collision.
#   - Because changing trajectory for the earlier collision is likely to invalidate the later
#     collision.
#   - In this case, the recursive call that found the additional, earlier collision will need to
#     also then calculate all steps from this collision to the end?
# 
# - Fix pixel-perfect scaling/aliasing when enlarging screen and doing camera zoom.
#   - Only support whole-number multiples somehow?
# 
# - When backtracking, re-use all steps that finish before releasing the jump button.
# 
# - Add a translation to the on-wall cat animations, so that they are all a bit lower; the cat's
#   head should be about the same position as the corresponding horizontal pose that collided, and
#   the bottom should fall from there.
# 
# - Add support for detecting invalid origin/destination positions (due to pre-existing collisions
#   with nearby surfaces).
#   - Shouldn't matter for convex neighbor surfaces though.
#   - And then add support for correcting the origin/destination position to avoid the collision.
#     - When a pre-existing collision is detected, look at the surface side direction.
#     - If parallel to the origin/destination surface, give up.
#     - If perpendicular, then offset the position to where the player would rest against the
#       surface, and check whether that position is still valid along the origin/destination
#       surface.
# 
# - Render a legend:
#   - x: point of collision
#   - outline: player boundary at point of collision
#   - open circles: start or end waypoints
#   - plus: left/right button start
#   - minus: left/right button end
#   - asterisk: jump button end
#   - diamond: 
#   - BT: 
#   - RF: 
# 
# - Polish description of approach in the README.
#   - In general, a guiding heuristic in these calculations is to minimize movement. So, through
#     each waypoint (step-end), we try to minimize the horizontal speed of the movement at that
#     point.
# 
# - Try to fix DrawUtils dashed polylines.
# 
# - Think through and maybe fix the function in waypoint utils for accounting for max-speed vs
#   min/max for valid next step?
# 
# - After having a finished demo for v1.0, abandon HTML exports for v2.0.
#   - Unless HTML will get support for GDNative
#     (https://github.com/godotengine/godot/issues/12243).
#   - Port most of the graph and collision logic to GDNative.
#   - Add an R-Tree for representing the surfaces and nodes.
#   - Use a TCP-based networking API for more efficient networking.
# 
# - Interesting idea for being able to traverse bumpy floors and walls (assuming small tile size
#   relative to player size).
#   - During graph surface parsing stage, look at neighbor surfaces.
#   - If there is a sequence of short edges that form a zig-zag, or a brief small bump, we can
#     ignore the small surface deviations and lump the whole thing into the same surface type as
#     the predominant neighbor surface.
#     - If there is a floor on both sides, then call the bump a floor.
#     - If there is a wall on both sides, then call the bump a wall.
#     - If there is a floor on one side and a wall on the other, then call the bump a floor.
#     - PROBLEM: How to handle falling down a wall and wanting to land on the small bump ledge?
#       - Maybe only translate the bump ceiling component into a wall component, and leave the
#         floor component as a floor component?
#       - Maybe have the tolerable floor merge bump size be different (and less permissive) than
#         the ceiling size.
#   - Make the tolerable bump deviation size configurable (not necessarily tied to the size of a
#     single tile).
# 
# - Update on-the-fly edge optimizations to get stored back onto the PlatformGraph?
# 
# - Tests!
#   - Big list of all cases to test:
#     - Jump/land optimization logic.
#     - Edge calculation logic.
#     - Things under platform_graph/edge/edge_calculators
#     - Things under platform_graph/edge/edges
#     - Things under platform_graph/edge/utils
#     - Things under platform_graph/surface
#     - Navigator
#     - PlatformGraph
#     - Player
#     - Things under player/action
#     - Things under player/action/action_handlers
#     - Everything under utils/
#   - Don't be brittle, with specific numbers; test simple high-level/relative things; skip other
#     logic that's not worth it:
#     - One edge from here to here
#     - Edge was long enough
#     - Had right number of waypoints
#     - Had at least the right height
#     - PlatformGraph chose a path of the correct edges
#     - Jump/land position calculations return the right positions
#     - Which other helper/utility functions to unit test in isolation...
#   - While adding tests, also debug.
#   - Plan what sort of helpers and testbed infrastructure we'll need.
#   - Adapt/discard the earlier, brittle, implementation-specific tests.
# 
# - Add support for friction to the navigation/movement logic.
#   - Will mostly need to update duration calculations for a few edges:
#     - IntraSurfaceEdge
#     - FallFromFloorEdge
#     - WalkToAscendWallFromFloorEdge
#     - Probably should add friction support to climbing on walls:
#       - ClimbDownWallToFloorEdge
#       - ClimbOverWallToFloorEdge
# 
# - Add suport for variable friction across a surface.
#   - It seems like different frictions will need to come from different TileMaps? Or, actually, I
#     could probably get the tile ID from a cell index and map that to my own custom friction
#     concept.
#   - Regardless, I don't have a way of distinguishing parts of a surface in the current setup.
#   - Two options:
#     - Use two separate Surface objects that are colinear, and prevent them from being
#       concatenated together into one.
#       - Might get weird with some assumptions from my graph logic?
#     - Use one Surface object, and keep track of an internal representation of regions with
#       different friction values.
#       - It would then be easy enough to query the region for a given PositionAlongSurface.
# 
# - Add multi-threading for surface parsing.
# 
###############################################################################



const LOADING_SCREEN_PATH := "res://loading_screen.tscn"

const PLAYER_ACTION_CLASSES := [
    preload("res://framework/player/action/action_handlers/air_dash_action.gd"),
    preload("res://framework/player/action/action_handlers/air_default_action.gd"),
    preload("res://framework/player/action/action_handlers/air_jump_action.gd"),
    preload("res://framework/player/action/action_handlers/all_default_action.gd"),
    preload("res://framework/player/action/action_handlers/cap_velocity_action.gd"),
    preload("res://framework/player/action/action_handlers/floor_dash_action.gd"),
    preload("res://framework/player/action/action_handlers/floor_default_action.gd"),
    preload("res://framework/player/action/action_handlers/floor_fall_through_action.gd"),
    preload("res://framework/player/action/action_handlers/floor_friction_action.gd"),
    preload("res://framework/player/action/action_handlers/floor_jump_action.gd"),
    preload("res://framework/player/action/action_handlers/floor_walk_action.gd"),
    preload("res://framework/player/action/action_handlers/match_expected_edge_trajectory_action.gd"),
    preload("res://framework/player/action/action_handlers/wall_climb_action.gd"),
    preload("res://framework/player/action/action_handlers/wall_dash_action.gd"),
    preload("res://framework/player/action/action_handlers/wall_default_action.gd"),
    preload("res://framework/player/action/action_handlers/wall_fall_action.gd"),
    preload("res://framework/player/action/action_handlers/wall_jump_action.gd"),
    preload("res://framework/player/action/action_handlers/wall_walk_action.gd"),
]

const EDGE_MOVEMENT_CLASSES := [
    preload("res://framework/platform_graph/edge/calculators/air_to_surface_calculator.gd"),
    preload("res://framework/platform_graph/edge/calculators/climb_down_wall_to_floor_calculator.gd"),
    preload("res://framework/platform_graph/edge/calculators/climb_over_wall_to_floor_calculator.gd"),
    preload("res://framework/platform_graph/edge/calculators/fall_from_floor_calculator.gd"),
    preload("res://framework/platform_graph/edge/calculators/fall_from_wall_calculator.gd"),
    preload("res://framework/platform_graph/edge/calculators/jump_inter_surface_calculator.gd"),
    preload("res://framework/platform_graph/edge/calculators/jump_from_surface_to_air_calculator.gd"),
    preload("res://framework/platform_graph/edge/calculators/walk_to_ascend_wall_from_floor_calculator.gd"),
]

const PLAYER_PARAM_CLASSES := [
    preload("res://players/cat_params.gd"),
    preload("res://players/squirrel_params.gd"),
    preload("res://test/data/test_player_params.gd"),
]

var loading_screen: Node
var camera_controller: CameraController
var canvas_layers: CanvasLayers
var level: Level
var is_level_ready := false

func _enter_tree() -> void:
    Global.register_player_actions(PLAYER_ACTION_CLASSES)
    Global.register_edge_movements(EDGE_MOVEMENT_CLASSES)
    Global.register_player_params(PLAYER_PARAM_CLASSES)
    
    if Config.IN_TEST_MODE:
        var scene_path := Config.TEST_RUNNER_SCENE_RESOURCE_PATH
        var test_scene = Utils.add_scene( \
                self, \
                scene_path)
    else:
        camera_controller = CameraController.new()
        add_child(camera_controller)
        
        canvas_layers = CanvasLayers.new()
        add_child(canvas_layers)
        
        if OS.get_name() == "HTML5":
            # For HTML, don't use the Godot loading screen, and instead use an
            # HTML screen, which will be more consistent with the other screens
            # shown before.
            JavaScript.eval("window.onLoadingScreenReady()")
        else:
            # For non-HTML platforms, show a loading screen in Godot.
            loading_screen = Utils.add_scene( \
                    canvas_layers.screen_layer, \
                    LOADING_SCREEN_PATH)

func _process(delta_sec: float) -> void:
    # FIXME: Figure out a better way of loading/parsing the level without
    #        blocking the main thread?
    
    if !Config.IN_TEST_MODE and \
            level == null and \
            Time.elapsed_play_time_sec > 0.25:
        # Start loading the level and calculating the platform graphs.
        level = Utils.add_scene( \
                self, \
                Config.STARTING_LEVEL_RESOURCE_PATH, \
                false)
    
    elif !is_level_ready and \
            Time.elapsed_play_time_sec > 0.5:
        is_level_ready = true
        level.visible = true
        
        # Hide the loading screen.
        if loading_screen != null:
            canvas_layers.screen_layer.remove_child(loading_screen)
            loading_screen.queue_free()
            loading_screen = null
        
        # Add the player after removing the loading screen, since the camera
        # will track the player, which makes the loading screen look offset.
        var position := \
                Vector2(160.0, 0.0) if \
                Config.STARTING_LEVEL_RESOURCE_PATH.find("test_") >= 0 else \
                Vector2.ZERO
        level.add_player( \
                Config.PLAYER_RESOURCE_PATH, \
                false, \
                position)
        
        if OS.get_name() == "HTML5":
            JavaScript.eval("window.onLevelReady()")
