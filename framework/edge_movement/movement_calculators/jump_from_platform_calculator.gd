extends EdgeMovementCalculator
class_name JumpFromPlatformCalculator

const MovementCalcOverallParams := preload("res://framework/edge_movement/models/movement_calculation_overall_params.gd")

const NAME := 'JumpFromPlatformCalculator'

# FIXME: LEFT OFF HERE: ---------------------------------------------------------A
# FIXME: -----------------------------
# 
# - Refine broad-phase filter in PlatformGraph:
#   - Split apart into three separate sets:
#     - Within fall range (down, not over or up)
#     - Within fall range + jump distance (over and down, not up)
#     - Within jump range (up and over, not down)
#   - Use the only the appropriate sets depending on the specific movement_calculator (pass all three to each though).
#   - Update find_surfaces_in_fall_range to be more intelligent about how it defines the polygon.
# 
# - Test/debug FallMovementUtils.find_a_landing_trajectory.
# 
# - Update trajectory annotator to not print enum in label, and to just skip to the first line
#   - And to remove one of the spaces from the other indented lines?
#   - Don't render the before/at/previous collision frame boxes if we don't actually have a
#     real/complete collision.
# 
# - Implement FallFromWallCalculator.
# 
# ?- Create new Edge sub-classes for the new EdgeMovementCalculator sub-classes?
#   - e.g., ClimbDownWallToFloor is a combination of two separate intra-surface edges?
#   - Think-out how I want the Navigator to work with the Edge system and the new
#     EdgeMovementCalculator sub-classes...
#     - Right now, the Navigator has embedded business logic for calculating just_reached_intra_surface_destination.
#     - I might need to take that out into something more scalable for each different EdgeMovementCalculator?
#   >>>- For now, just hard-code logic into Navigator. Clean it up afterward.
# - Implement new EdgeMovementCalculator subclasses.
#   - FallFromWall
#     - Instructions playback:
#       - Can be very simple: a single frame with a single instruction. Guaranteed to work.
#   - FallFromFloor
#     - Instructions playback:
#       - Walk until leaving floor surface (or "enter air").
#   - ClimbOverWallToFloor
#     - Instructions playback:
#       - Climb up until leaving wall surface (or "enter air").
#       - Then press sideways until hitting floor surface.
#     - Annotator:
#       - Render quarter circle with ends aligned coaxially with corner.
#   - ClimbDownWallToFloor
#     - Instructions playback:
#       - Climb down until surface_state.is_touching_floor.
#     - Annotator:
#       - Render 90-degree connected line segments? Where are the end points?
#   - ClimbUpWallFromFloor
#     - Instructions playback:
#       - Walk over until surface_state.is_touching_(left|right)wall.
#     - Annotator:
#       - Render 90-degree connected line segments? Where are the end points?
#   - Clean-up how Navigator handles edge-end detection logic, to be more scalable with new classes?
# 
# - Adjust cat_params to only allow subsets of EdgeMovementCalculators, in order to test the non-jump edges
# 
# - Fix any remaining Navigator movement issues.
# - Fix performance.
#   - Should I almost never be actually storing things in Pool arrays? It seems like I mostly end
#     up passing them around as arguments to functions, to they get copied as values...
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
# - Fix issue where jumping around edge sometimes isn't going far enough; it's clipping the corner.
# 
# ---  ---
# 
# - Start with debug menu closed. Open when rendering edge-calc annotator.
# - Create a temporary toast message.
#   - Shown at top-mid.
#   - Disappears after clicking anywhere.
#   - Explains controls and click-to-focus.
#     - Squirrel Away!
#     - _Click anywhere on window to give focus (Levi will fix that eventually...)._
#     - Controls:
#       - Use mouse to direct cat to move automatically.
#       - Use keyboard to control cat manually (UDLR, X, Z)
#       - Ctrl+click to debug how an edge was calculated (click on both ends where the edge should have gone).
# - Add a top-level button to debug menu to hide all annotations.
#   - (grid, clicks, player position, player recent movement, platform graph, ...)
# 
# - Prepare a different, more interesting level for demo (some walls connecting to floors too).
# 
# - Make each background layer more faded. Only interactable foreground should pop so much.
# 
# ---  ---
# 
# - Put together some illustrative screenshots with special one-off annotations to explain the
#   graph parsing steps.
#   - A couple surfaces
#   - Show different tiles, to illustrate how surfaces get merged.
#   - All surfaces (different colors)
#   - A couple edges
#   - All edges
#   - 
# 
# - Update README.
# 
# ---  ---
# 
# - Update navigation to do some additional on-the-fly edge calculations.
#   - Only limit this to a few additional potential edges along the path.
#   - The idea is that the edges tend to produce very unnatural composite trajectories (similar to
#     using perpendicular Manhatten distance routes instead of more diagonal routes).
#   >- Basically, try jumping from earlier on any given surface.
#     - It may be hard to know exactly where along a surface to try jumping from though...
#     - Should probably just use some simple heuristic and just give up when they fail with
#       false-positive rates.
#   >- Also, update velocity_start for these on-the-fly edges to be more intelligent.
# 
# - Update navigator to force player state to match expected edge start state.
#   - Configurable.
#   - Both position and velocity.
# - Add support for forcing state during edge movement to match what is expected from the original edge calculations.
#   - Configurable.
#   - Apply this to both position and velocity.
#   - Also, allow for this to use a weighted average of the expected state vs the actual state from normal run-time.
#   - Also, add a warning message when the player is too far from what's expected.
# 
# - Update edge-calculations to support variable velocity_start_x values.
#   - Allow for up-front edge calculation to use any desired velocity_start_x between
#     -max_horizontal_speed_default and max_horizontal_speed_default.
#   - This is probably a decent approximation, since we can usually assume that the ramp-up
#     distance to get from 0 to max-x-speed on the floor is small enough that we can ignore it.
#   - We could probably actually do an even better job by limiting the range for velocity_start_x
#     for floor-surface-end-jump-off-points to be between either -max_horizontal_speed_default and
#     0 or 0 and max_horizontal_speed_default.
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
#     - Climbing down (just run climbing-up in reverse? Probably want to bound down, facing down,
#       as opposed to cat. Will make transition weird, but whatever?)
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
#     - Start simple. Pick font. Render in Inkscape. Create a hand-pixel-drawn copy in Aseprite.
#     - V1: Show "Squirrel Away" text. Animate squirrel running across, right to left, in front of letters.
#     - V2: Have squirrel pause to the left of the S, with its tail overlapping the S. Give a couple tail twitches. Then have squirrel leave.
#     
# --- Expected cut-off for demo date ---
# 
# - Add some extra improvements to check_frame_for_collision:
#   - [maybe?] Rather than just using closest_intersection_point, sort all intersection_points, and
#     try each of them in sequence when the first one fails	
#   - [easy to add, might be nice for future] If that also fails, use a completely separate new
#     cheap-and-dirty check-for-collision-in-frame method?	
#     - Check if intersection_points is not-empty.
#     - Sort them by closest in direction of motion (and ignoring behind points).
#     - Iterate through points, trying to get tile index by a slight nudge offset from each
#       intersection point in the direction of motion until one sticks.
#     - Choose surface side just from dominant motion component.
#   - Add a field on the collision class for the type of collision check used
#   - Add another field (or another option for the above field) to indicate that none of the
#     collision checks worked, and this collision is in an error state
#   - Use this error state to abort collision/step/edge calculations (rather than the current
#     approach of returning null, which is the same as with not detecting any collisions at all).
# 
# - Add better annotation selection.
#   - Add shorcuts for toggling debugging annotations
#     - Add support for triggering the calc-step annotations based on a shortcut.
#       - i
#       - also, require clicking on the start and end positions in order to select which edge to
#         debug
#         - Use this _in addition to_ the current top-level configuration for specifying which edge
#           to calculate?
#       - also, then only actually calculate the edge debug state when using this click-to-specify
#         debug mode
#     - also, add other shortcuts for toggling other annotations:
#       - whether all surfaces are highlighted
#       - whether the player's position+collision boundary are rendered
#       - whether the player's current surface is rendered
#       - whether all edges are rendered
#       - whether grid boundaries+indices are rendered
#     - create a collapsible dat.GUI-esque menu at the top-right that lists all the possible
#       annotation configuration options
#       - set up a nice API for creating these, setting values, listening for value changes, and
#         defining keyboard shortcuts.
#   - Use InputMap to programatically add keybindings.
#     - This should enable our framework to setup all the shortcuts it cares about, without
#       consumers needing to ever redeclare anything in their project settings.
#     - This should also enable better API design for configuring keybindings and menu items from
#       the same place.
#     - https://godot-es-docs.readthedocs.io/en/latest/classes/class_inputmap.html#class-inputmap
# 
# - Finish remaining surface-closest-point-jump-off calculation cases.
#   - Also, maybe still not quite far enough with the offset?
# 
# - Implement fall-through/walk-through movement-type utils.
# 
# >- Commit message:
# 




func _init().(NAME) -> void:
    pass

func get_can_traverse_from_surface(surface: Surface) -> bool:
    return surface != null

func get_all_edges_from_surface(debug_state: Dictionary, space_state: Physics2DDirectSpaceState, \
        movement_params: MovementParams, surface_parser: SurfaceParser, edges_result: Array, \
        surfaces_in_fall_range_set: Dictionary, surfaces_in_jump_range_set: Dictionary, \
        origin_surface: Surface) -> void:
    var jump_positions: Array
    var land_positions: Array
    var terminals: Array
    var instructions: MovementInstructions
    var edge: InterSurfaceEdge
    var overall_calc_params: MovementCalcOverallParams
    
    # FIXME: B: REMOVE
    movement_params.gravity_fast_fall *= \
            MovementInstructionsUtils.GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    movement_params.gravity_slow_rise *= \
            MovementInstructionsUtils.GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    
    var constraint_offset = MovementCalcOverallParams.calculate_constraint_offset(movement_params)
    
    for destination_surface in surfaces_in_jump_range_set:
        # This makes the assumption that traversing through any fall-through/walk-through surface
        # would be better handled by some other Movement type, so we don't handle those
        # cases here.
        
        if origin_surface == destination_surface:
            # We don't need to calculate edges for the degenerate case.
            continue
        
        # FIXME: D:
        # - Do a cheap bounding-box distance check here, before calculating any possible jump/land
        #   points.
        # - Don't forget to also allow for fallable surfaces (more expensive).
        # - This is still cheaper than considering all 9 jump/land pair instructions, right?
        
        jump_positions = MovementUtils.get_all_jump_positions_from_surface( \
                movement_params, origin_surface, destination_surface.vertices, \
                destination_surface.bounding_box, destination_surface.side)
        land_positions = MovementUtils.get_all_jump_positions_from_surface( \
                movement_params, destination_surface, origin_surface.vertices, \
                origin_surface.bounding_box, origin_surface.side)
        
        for jump_position in jump_positions:
            for land_position in land_positions:
                ###################################################################################
                # Allow for debug mode to limit the scope of what's calculated.
                if debug_state.in_debug_mode and debug_state.has('limit_parsing') and \
                        debug_state.limit_parsing.has('edge'):
                    var debug_origin: Dictionary = debug_state.limit_parsing.edge.origin
                    var debug_destination: Dictionary = \
                            debug_state.limit_parsing.edge.destination
                    
                    if origin_surface.side != debug_origin.surface_side or \
                            destination_surface.side != debug_destination.surface_side or \
                            origin_surface.first_point != debug_origin.surface_start_vertex or \
                            origin_surface.last_point != debug_origin.surface_end_vertex or \
                            destination_surface.first_point != \
                                    debug_destination.surface_start_vertex or \
                            destination_surface.last_point != debug_destination.surface_end_vertex:
                        # Ignore anything except the origin and destination surface that we're
                        # debugging.
                        continue
                    
                    # Calculate the expected jumping position for debugging.
                    var debug_jump_position: PositionAlongSurface
                    match debug_origin.near_far_close_position:
                        "near":
                            debug_jump_position = jump_positions[0]
                        "far":
                            assert(jump_positions.size() > 1)
                            debug_jump_position = jump_positions[1]
                        "close":
                            assert(jump_positions.size() > 2)
                            debug_jump_position = jump_positions[2]
                        _:
                            Utils.error()
                    
                    # Calculate the expected landing position for debugging.
                    var debug_land_position: PositionAlongSurface
                    match debug_destination.near_far_close_position:
                        "near":
                            debug_land_position = land_positions[0]
                        "far":
                            assert(land_positions.size() > 1)
                            debug_land_position = land_positions[1]
                        "close":
                            assert(land_positions.size() > 2)
                            debug_land_position = land_positions[2]
                        _:
                            Utils.error()
                    
                    if jump_position != debug_jump_position or \
                            land_position != debug_land_position:
                        # Ignore anything except the jump and land positions that we're debugging.
                        continue
                ###################################################################################
                
                terminals = MovementConstraintUtils.create_terminal_constraints(origin_surface, \
                        jump_position.target_point, destination_surface, land_position.target_point, \
                        movement_params, true)
                if terminals.empty():
                    continue
                
                overall_calc_params = MovementCalcOverallParams.new(movement_params, space_state, \
                        surface_parser, terminals[0], terminals[1])
                
                ###################################################################################
                # Record some extra debug state when we're limiting calculations to a single edge.
                if debug_state.in_debug_mode and debug_state.has('limit_parsing') and \
                        debug_state.limit_parsing.has('edge') != null:
                    overall_calc_params.in_debug_mode = true
                ###################################################################################
                
                instructions = calculate_jump_instructions(overall_calc_params)
                if instructions != null:
                    # Can reach land position from jump position.
                    edge = InterSurfaceEdge.new(jump_position, land_position, instructions)
                    edges_result.push_back(edge)
                    # For efficiency, only compute one edge per surface pair.
                    break
            
            if edge != null:
                # For efficiency, only compute one edge per surface pair.
                edge = null
                break
    
    # FIXME: B: REMOVE
    movement_params.gravity_fast_fall /= \
            MovementInstructionsUtils.GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    movement_params.gravity_slow_rise /= \
            MovementInstructionsUtils.GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION

func get_instructions_to_air(space_state: Physics2DDirectSpaceState, \
        movement_params: MovementParams, surface_parser: SurfaceParser, \
        position_start: PositionAlongSurface, position_end: Vector2) -> MovementInstructions:
    var constraint_offset := MovementCalcOverallParams.calculate_constraint_offset(movement_params)
    
    var terminals := MovementConstraintUtils.create_terminal_constraints(position_start.surface, \
            position_start.target_point, null, position_end, movement_params, true)
    if terminals.empty():
        null
    
    var overall_calc_params := MovementCalcOverallParams.new(movement_params, space_state, surface_parser, \
            terminals[0], terminals[1])
    
    return calculate_jump_instructions(overall_calc_params)

# Calculates instructions that would move the player from the given start position to the given end
# position.
# 
# This considers interference from intermediate surfaces, and will only return instructions that
# would produce valid movement without intermediate collisions.
static func calculate_jump_instructions( \
        overall_calc_params: MovementCalcOverallParams) -> MovementInstructions:
    var calc_results := MovementStepUtils.calculate_steps_with_new_jump_height( \
            overall_calc_params, null, null)
    
    if calc_results == null:
        return null
    
    var instructions: MovementInstructions = \
            MovementInstructionsUtils.convert_calculation_steps_to_movement_instructions( \
                    overall_calc_params.origin_constraint.position, \
                    overall_calc_params.destination_constraint.position, calc_results, true, \
                    overall_calc_params.destination_constraint.surface.side)
    
    if Utils.IN_DEV_MODE:
        MovementInstructionsUtils.test_instructions(instructions, overall_calc_params, calc_results)
    
    return instructions
