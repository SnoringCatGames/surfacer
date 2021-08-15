# Notable limitations

-   Our build-time graph calculations take a long time, especially for a level with lots of surfaces (such as a big level, or a level with a small cell size).
    -   To ameliorate this, you can precompute graphs and save them to JSON files, which can be loaded much more quickly at play time.
    -   Use the `precompute_platform_graph_for_levels` property in your app manifest to precompute graphs.
-   There is slight discrepancy between discrete and continuous trajectories. The former is what we see from movement produced by the frame-by-frame application of gravity and input actions on the character. The latter is what we see from our precise numerical analysis of algebraic equations when pre-calculating the platform graph. We support a few different techniques for reconciling this:
    -   `MovementParameters.syncs_character_velocity_to_edge_trajectory`: When this flag is enabled, the character's run-time _velocity_ will be forced to match the expected pre-calculated (continuous) velocity for the current frame in the currently executing platform graph edge.
    -   `MovementParameters.syncs_character_position_to_edge_trajectory`: When this flag is enabled, the character's run-time _position_ will be forced to match the expected pre-calculated (continuous) velocity for the current frame in the currently executing platform graph edge.
    -   `MovementParameters.retries_navigation_when_interrupted`: When this flag is enabled, the navigator will re-attempt navigation to the original destination from the current position whenever it detects that the character has hit an unexpected surface, which is what can happen when the run-time discrete trajectories don't match build-time continuous trajectories.
-   When two surfaces face each other and are too close for thte character to fit between (plus a margin of a handful of extra pixels), our graph calculations can produce some false positives.
-   Surfacer doesn't currently fully support surfaces that consist of one point.
-   Our platform graph calculations produce false negatives for some types of jump edge scenarios:
    -   An jump edge that needs to displace the jump position in order to make it around an intermediate waypoint with enough horizontal velocity to then reach the destination.
        -   For example, if the character is jumping from the bottom of a set of stair-like surfaces, the jump position ideally wouldn't be as close as possible to the first rise of the first step (because they can't start accelerating horizontally until vertically clearing the top of the rise). Instead, if the character jumps from a slight offset from the rise, then they can pass over the rise with more speed, which lets them travel further during the jump.
    -   A single horizontal step that needs multiple different sideways-movement instructions (i.e., accelerating to both one side and then the other in the same jump):
        -   For example, backward acceleration in order to not overshoot the end position as well as forward acceleration to then have enough step-end x velocity in order to reach the following waypoint for the next step.
-   Surfacer is opinionated. It requires that you structure your app using TileMaps, specific node groups, and by subclassing certain framework classes in order to create characters.
    -   You need to define a set of input actions with the following names (via Project Settings > Input Map):
        -   jump
        -   move_up
        -   move_down
        -   move_left
        -   move_right
        -   dash
        -   zoom_in
        -   zoom_out
        -   pan_up
        -   pan_down
        -   pan_left
        -   pan_right
        -   face_left
        -   face_right
        -   grab_wall
    -   Your level collidable foreground tiles must be defined in a _single_ TileMap that belongs to the "surfaces" node group.
    -   Surfacer uses a very specific set of movement mechanics.
        -   Fortunately, this set includes most features commonly used in platforms and is able to provide pretty sophisticated movement.
        -   But the procedural path-finding doesn't know about complex platformer mechanics like special in-air friction or coyote time.
    -   The Surfacer framework isn't yet decoupled from the Squirrel Away demo app logic.

> **NOTE:** All collidable tiles in a level must be defined in a _single_ TileMap.
