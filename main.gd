extends Node
class_name Main

###############################################################################
### MAIN TODO LIST: ###
# 
# ### TODO: Now (before end of July) ###
# 
# - Render an arrow to indicate the direction/magnitude of start velocity.
#   - And legend item.
# - Finish adding/polishing inspector step calculation
#   items/descriptions/annotations/legends.
#   - Use origin/destination indicator shapes.
#   - ...
# 
# - Fix player to not sometimes face backwards against the direction of motion
#   when jumping (I think the current "face_left"/"face_right" input
#   instructions are only being used when landing on a wall).
#   - Maybe just make the player always face the direction of horizontal motion
#     when in the air?
#     - Maybe add a movement_params flag to enable that.
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
# - Add percentage-based progress bar to loading screen for graph parsing.
#   - Should I somehow break apart the platform graph parsing to happen over
#     different event loops? Use call_deferred?
# 
# - Update initial load to happen on a separate thread, so that main and
#   loading_screen are not locked.
#   - Update level loading to use ResourceLoader interactive mode?
# 
# - Fix threads to work with the new collision test logic.
# 
# - Add some legend items for the persistent annotations:
#   - Previous movement
#   - Previous navigation
# 
# - Use Profiler for player _process_physics.
#   - Log avg/min/max every five seconds or so.
# 
# - Try to debug run-time jitteriness.
# 
# - Handle cat-squirrel collisions:
#   - Add a simple animation (copy the click animation at first).
#   - Move the squirrel to a random new position in the level.
#     - Maybe re-use the same logic to pick a destination spot that's far from
#       the cat.
# 
# - Add a second squirrel to the level.
# 
# - Decouple squirrel-specific logic from the rest of the framework.
# 
# ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  --
# ### TODO: Eventually (probably before end of 2020). ###
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
# - Check on current behavior of
#   EdgeInstructionsUtils.JUMP_DURATION_INCREASE_EPSILON and
#   EdgeInstructionsUtils.MOVE_SIDEWAYS_DURATION_INCREASE_EPSILON.
#   - Check with position and velocity syncing turned off.
# 
# - Finish logic to consume Waypoint.needs_extra_jump_duration.
#   - Started, but stopped partway through, with adding this usage in
#     _update_waypoint_velocity_and_time.
# 
# - Finish calculate_steps_between_waypoints_with_increasing_jump_height:
#   - Debug the current function. It seems to lose some valid edges that the
#     other function would yield.
#   - Conditionally use this approach behind a movement_params flag. This
#     should improve efficiency and decrease accuracy.
# 
# - Fix how things work when minimizes_velocity_change_when_jumping is true.
#   - [no] Find and move all movement-offset constants to one central location?
#     - EdgeInstructionsUtils
#     - WaypointUtils
#     - FrameCollisionCheckUtils
#     - EdgeCalcParams
#   >>- Compare where instructions are pressed/released vs when I expect them.
#   - Step through movement along an edge?
#   >- Should this be when I implement the logic to force the player's
#     position to match the expected edge positions (with a weighted avg)?
# 
# - Should we somehow consolidate collision logic between
#   FrameCollisionCheckUtils and Player?
# 
# - Use Profiler analytics to inform decisions around which calculations are
#   worth it.
#   - Maybe add a new configuration for max number of
#     collisions/intermediate-waypoints to allow in an edge calculation
#     before giving up (or, recursion depth (with and without backtracking))?
#   - Tweak movement_params.exceptional_jump_instruction_duration_increase, and
#     ensure that it is actually cutting down on the number of times we have to
#     backtrack.
#   - Should I almost never be actually storing things in Pool arrays? It seems
#     like I mostly end up passing them around as arguments to functions, to
#     they get copied as values...
#     - Does this affect performance?
# 
# - Add some analytics for load times of different parts of load screen in HTML
#   page.
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
# - Implement fall-through/walk-through movement-type utils.
# 
# - Switch to built-in Godot gradients for surface annotations.
# 
# - Refactor pre-existing annotator classes to use the new
#   AnnotationElementType system.
#   - At least remove ExtraAnnotator and replace it with the new
#     general-purpose annotator.
#   - And probably just remove some obsolete annotators.
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
# - Add TODOs to use easing curves with all annotation animations.
# 
# - Create a pause menu and a level switcher.
# 
# - Consolidate/reuse per-frame state updates logic between the instruction
#   calculations and actual Player movements?
# 
# - Maybe add a more intelligent proximity-avoidance search for the squirrel's
#   navigation behavior.
#   - Do a* to find most likely path from predator to prey.
#   - Then given a target destination somewhere, presumably away from predator.
#   - Then calculate a special path using a different sort of edge weight.
#   - Edge weight will be based off nearest node in predators a* path.
#   - Then, maybe also calculate at which node the predator will be closest to
#     our prey path, and time the preyst traversal to avoid being near there at
#     that time?
# 
# 
# 
# ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  --
# 
# - Remaining waypoint logic polish:
#   
#   - Additional_high_waypoint_position breakpoint is happening three times??
#     - Should I move the fail-because-we've-been-here-before logic from
#       looking at steps+surfaces+heights to here?
#   
#   - Should we somehow ensure that jump height is always bumped up at least
#     enough to cover the extra distance of waypoint offsets?
#     - Since jumping up to a destination, around the other edge of the
#       platform (which has the waypoint offset), seems like a common use-case,
#       this would probably be a useful optimization.
#     - [This is important, since the first attempt at getting to the top-right
#       waypoint always fails, since it requires a _slightly_ higher jump, and
#       we want it to instead succeed.]
#   
#   - There is a problem with my approach for using
#     time_to_get_to_destination_from_waypoint.
#     time-to-get-to-intermediate-waypoint-from-waypoint could matter a lot
#     too. But maybe this is infrequent enough that I don't care? At least
#     document this limitation (in code and README).
#   
#   - Add logic to ignore a waypoint when the horizontal steps leading up to it
#     would have found another collision.
#     - Because changing trajectory for the earlier collision is likely to
#       invalidate the later collision.
#     - In this case, the recursive call that found the additional, earlier
#       collision will need to also then calculate all steps from this
#       collision to the end?
# 
# - Add a translation to the on-wall cat animations, so that they are all a bit
#   lower; the cat's head should be about the same position as the
#   corresponding horizontal pose that collided, and the bottom should fall
#   from there.
# 
# - After having a finished demo for v1.0, abandon HTML exports for v2.0.
#   - Unless HTML will get support for GDNative
#     (https://github.com/godotengine/godot/issues/12243).
#   - Port most of the graph and collision logic to GDNative.
#   - Add an R-Tree for representing the surfaces and nodes.
#   - Use a TCP-based networking API for more efficient networking.
# 
# - Interesting idea for being able to traverse bumpy floors and walls
#   (assuming small tile size relative to player size).
#   - During graph surface parsing stage, look at neighbor surfaces.
#   - If there is a sequence of short edges that form a zig-zag, or a brief
#     small bump, we can ignore the small surface deviations and lump the whole
#     thing into the same surface type as the predominant neighbor surface.
#     - If there is a floor on both sides, then call the bump a floor.
#     - If there is a wall on both sides, then call the bump a wall.
#     - If there is a floor on one side and a wall on the other, then call the
#       bump a floor.
#     - PROBLEM: How to handle falling down a wall and wanting to land on the
#       small bump ledge?
#       - Maybe only translate the bump ceiling component into a wall
#         component, and leave the floor component as a floor component?
#       - Maybe have the tolerable floor merge bump size be different (and less
#         permissive) than the ceiling size.
#   - Make the tolerable bump deviation size configurable (not necessarily tied
#     to the size of a single tile).
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
#   - It seems like different frictions will need to come from different
#     TileMaps? Or, actually, I could probably get the tile ID from a cell
#     index and map that to my own custom friction concept.
#   - Regardless, I don't have a way of distinguishing parts of a surface in
#     the current setup.
#   - Two options:
#     - Use two separate Surface objects that are colinear, and prevent them
#       from being concatenated together into one.
#       - Might get weird with some assumptions from my graph logic?
#     - Use one Surface object, and keep track of an internal representation of
#       regions with different friction values.
#       - It would then be easy enough to query the region for a given
#         PositionAlongSurface.
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
###############################################################################



var loading_screen: Node
var camera_controller: CameraController
var canvas_layers: CanvasLayers
var level: Level
var is_loading_screen_shown := true

func _enter_tree() -> void:
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
                    Config.LOADING_SCREEN_PATH)

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
                true, \
                false)
    
    elif is_loading_screen_shown and \
            Global.is_level_ready and \
            Time.elapsed_play_time_sec > 0.5:
        is_loading_screen_shown = false
        level.visible = true
        
        # Hide the loading screen.
        if loading_screen != null:
            canvas_layers.screen_layer.remove_child(loading_screen)
            loading_screen.queue_free()
            loading_screen = null
        
        # FIXME: Move this player creation (and readiness recording) back into
        #        Level.
        # Add the player after removing the loading screen, since the camera
        # will track the player, which makes the loading screen look offset.
        var position := \
                Vector2(160.0, 0.0) if \
                Config.STARTING_LEVEL_RESOURCE_PATH.find("test_") >= 0 else \
                Vector2.ZERO
        level.add_player( \
                Global.player_params[Config.DEFAULT_PLAYER_NAME] \
                        .movement_params.player_resource_path, \
                position, \
                true, \
                false)
        var starting_squirrel_positions := [
            Vector2(192.0, -192.0),
#            Vector2(-192.0, 192.0),
        ]
        for squirrel_position in starting_squirrel_positions:
            level.add_player( \
                    Global.player_params["squirrel"].movement_params \
                            .player_resource_path, \
                    squirrel_position, \
                    false, \
                    false)
        Global.canvas_layers.on_level_ready()
        
        if OS.get_name() == "HTML5":
            JavaScript.eval("window.onLevelReady()")
