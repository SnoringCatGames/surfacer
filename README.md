# Surfacer

_A procedural pathfinding 2D-platformer framework for Godot._

_"Surfacer": Like a platformer, but with walking, climbing, and jumping on all surfaces!_

TODO: Once v1.0 of this framework is done, split this apart into two repos: one for the underlying framework, and one for the demo game ("Squirrel Away").

TODO: Link to demo app.

**tl;dr**: Surfacer works by **pre-parsing** a level into a **"platform graph"**. The **nodes** are represented by points along the different surfaces in the level (floors, walls, and ceilings). The **edges** are represented by possible movement trajectories between points along surfaces. There are different types of edges for different types of movement (e.g., jumping from a floor to a floor, falling from a wall, walking along a floor). At run time, **[A* search](https://en.wikipedia.org/wiki/A*_search_algorithm)** is used to calculate a path to a given destination.

Some features include:
-   Walking on floors, climbing on walls, climbing on ceilings, jumping and falling from anywhere.
-   [Variable-height jump and fast-fall](https://kotaku.com/the-mechanics-behind-satisfying-2d-jumping-1761940693).
-   Adjusting movement trajectories around intermediate surfaces (such as jumping over a wall or under an overhang).
-   Configurable movement parameters on a per-player basis (e.g., horizontal acceleration, jump power, gravity, collision boundary shape and size, which types of edge movement are allowed).
-   Level creation using Godot's standard pattern with a [TileMap in the 2D scene editor](https://docs.godotengine.org/en/3.2/tutorials/2d/using_tilemaps.html).
-   Preparsing the level into a platform graph, and using A* search for efficient path-finding at runtime.

## Buy why?

Because there aren't many other good tools out there for intelligent pathfinding in a platformer.

The vast majority of platformers use pretty simple computer-player AI for movement--for example:
-   Walk to edge, turn around, repeat.
-   Jump continuously, moving forward.
-   Move with a regular bounce or surface-following pattern.
-   Move horizontally toward the human player, "floating" vertically as needed in order to move around obstacles and platforms.

Most examples of more sophisticated AI pathfinding behavior are usually still pretty limited. One common technique uses machine-learning and is trained by hundreds to thousands of human-generated jumps on an explicit pre-fabricated level. This makes level-generation difficult and is not flexible to dynamic platform creation/movement.

There are two key reasons why good path-finding AI isn't really used in platformers:
1.  It's hard to implement right; there is a lot of math involved, and there are a lot of different edge cases to account for.
2.  Dumb AI is usually plenty effective on its own to create compelling gameplay. The user often doesn't really notice or care how simple the behavior is.

But there are use-cases for which we really benefit from an AI that can accurately immitate the same movement mechanics of the player. One example is if we want to have a flexible game mode in which a computer player can swap in for a human player depending on how many humans are present.

## Platformer AI

### The platform graph: Pre-parsing the world

Surfacer depends on the level being represented as a [`TileMap`](https://docs.godotengine.org/en/3.2/classes/class_tilemap.html#class-tilemap).

In order for our AI to traverse our world, we first need to parse the world into a platform graph. We do this up-front, when the level is loaded, so that we can efficiently search the graph at run time. Dynamic updates to the graph can be performed at runtime, but these could be expensive if not done with care.

The nodes of this graph correspond to positions along distinct surfaces. Since our players can walk on floors, climb on walls, and climb on ceilings, we store floor, wall, and ceiling surfaces.

The edges of this graph correspond to a type of movement that the player could perform in order to move from one position on a surface node to another.
-   These edges are directional, since the player may be able to move from A to B but not from B to A.
-   The ends of an edge could be along the same surface or on different surfaces (e.g., for climbing up a wall vs jumping from a floor).
-   There could be multiple edges between a single pair of nodes, since there could be multiple types of movement that could get the player from the one to the other.
-   These edges are specific to a given player type. If we need to consider a different player that has different movement parameters, then we need to calculate a separate platform graph for that player.

TODO: diagrams:
- show a screenshot with just surfaces highlighted and cell indices rendered
- show a screenshot with just edge trajectories rendered

### Nodes: Parsing a Godot `TileMap` into surfaces

**NOTE**: The following algorithm assumes that the given `TileMap` only uses tiles with convex collision boundaries.

#### Parse individual tiles into their constituent surfaces

-   Map each `TileMap` cell into a polyline that corresponds to the top-side/floor portion of its collision polygon.
    -   Calculate whether the collision polygon's vertices are specified in a clockwise order.
        -   Use this to determine the iteration step size.
            -   `step_size = 1` if clockwise; `step_size = -1` if counter-clockwise.
        -   Regardless of whether the vertices are specified in a clockwise order, we will iterate over them in clockwise order.
    -   Find both the leftmost and rightmost vertices.
    -   Start with the leftmost vertex.
        -   If there is a wall segment on the left side of the polygon, then this vertex is part of it.
        -   If there is no wall segment on the left side of the polygon, then this vertex must be the cusp between a preceding bottom-side/ceiling segment and a following top-side/floor segment (i.e., the previous segment is underneath the next segment).
            -   Even if there is no segment along one side, we store a surface for that side; this surface is only represented by a single point.
    -   Iterate over the following vertices until we find a non-wall segment (this could be the first segment, the one connecting to the leftmost vertex).
        -   Wall segments are distinguished from floor/ceiling segments according to their angle. This is configurable, but typically, a segment up to 45-degrees is a floor/ceiling and a segment steeper than 45-degrees is a wall.
    -   This non-wall segment must be the start of the top-side/floor polyline.
    -   Iterate, adding segments to the result polyline, until we find either a wall segment or the rightmost vertex.
    -   We then also save a mapping from a `TileMap` cell index to each of the different surfaces we've calculated as existing in that cell.
-   Repeat the above process for the right-side, left-side, and bottom-side surfaces.

TODO: diagrams:
- showing surfaces with cell indices

#### Remove internal surfaces

**NOTE**: This will only detect internal surface segments that are equivalent with another internal segment. But for grid-based tiling systems, this can often be enough.

-   Check for pairs of floor+ceiling segments or left-wall+right-wall segments, such that both segments share the same vertices.
-   Remove both segments in these pairs.

TODO: diagrams:
- eliminating internal surfaces

#### Merge any connecting surfaces

-   Iterate across each floor surface A.
-   Nested iterate across each other floor surface B.
    -   Ideally, we should be using a spatial data structure that allows us to only consider nearby surfaces during this nested iteration (such as an R-Tree).
-   Check whether A and B form a "continuous" surface.
    -   A and B are both polylines that only have two end points.
    -   Just check whether either endpoint of A equals either endpoint of B.
        -   Actually, our original `TileMap` parsing results in every surface polyline being stored in clockwise order, so we only need to compare the end of A with the start of B and the start of A with the end of B.
-   If they do:
    -   Merge B into A.
    -   Optionally, remove any newly created redundant internal colinear points.
    -   Remove B from the surface collection.
-   Repeat the iteration until no merges were performed.

TODO: diagrams:
- merging connected surfaces

#### Record adjacent neighbor surfaces

-   Every surface should have both adjacent clockwise and counter-clockwise neighbor surfaces.
-   Use a similar process as above for finding surfaces with matching end positions.

TODO: diagrams:
- detecting neighbor surfaces

### Edges: Calculating jump movement trajectories

**tl;dr**: The Surfacer framework uses a procedural approach to calculate trajectories for movement between surfaces. The algorithms used rely heavily on the classic [one-dimensional equations of motion for constant acceleration](https://physics.info/motion-equations/). These trajectories are calculated to match to the same abilities and limitations that are exhibited by corresponding human-controlled movement. After the trajectory for an edge is calculated, it is translated into a simple instruction/input-key start/end sequence that should reproduce the calculated trajectory.

**NOTE**: A machine-learning-based approach would probably be a good alternate way to solve this general problem. However, one perk of a procedural approach is that it's relatively easy to understand how it works and to modify it to perform better for any given edge-case (and there are a _ton_ of edge-cases).

#### The high-level steps

-   Determine how high we need to jump in order to reach the destination.
-   If the destination is out of reach (vertically or horizontally), ignore it.
-   Calculate how long it will take for vertical motion to reach the destination from the origin.
-   We will define the movement trajectory as a combination of two independent components: a "vertical step" and a "horizontal step". The vertical step is based primarily on on the jump duration calculated above.
-   Calculate the horizontal step that would reach the destination displacement over the given duration.
-   Check for any unexpected collisions along the trajectory represented by the vertical and horizontal steps.
    -   If there is an intermediate surface that the player would collide with, we need to try adjusting the jump trajectory to go around either side of the colliding surface.
        -   We call these points that movement must go through in order to avoid collisions, "constraints".
        -   Recursively check whether the jump is valid to and from either side of the colliding surface.
        -   If we can't reach the destination when moving around the colliding surface, then try backtracking and consider whether a higher jump height from the start would get us there.
    -   If there is no intermediate collision, then we can calculate the ultimate edge movement instructions for playback based on the vertical and horizontal steps we've calculated.

#### Some important aspects

-   We treat horizontal and vertical motion as independent to each other. This greatly simplifies our calculations.
    -   We calculate the necessary jump duration--and from that the vertical component of motion--up-front, and use this to determine times for each potential step and constraint of the motion. Knowing these times up-front makes the horizontal min/max calculations easier.
-   We have a broad-phase check to quickly eliminate possible surfaces that are obviously out of reach.
    -   This primarily looks at the horizontal and vertical distance from the origin to the destination.

TODO: Include a screenshot of a collision that clips the corner of the wall when trying to jump to the above floor--a very common scenario.

#### Calculating "good" jump and land positions

Deciding which jump and land positions to base an edge calculation off of is non-trivial. We could just try calculating edges for a bunch of different jump/land positions for a given pair of surfaces. But edge calculations aren't cheap, and executing too many of them impacts performance. So it's important that we carefully choose "good" jump/land positions that have a relatively high likelihood of producing a valid and efficient edge.

-   Some interesting jump/land positions for a surface include the following:
    -   Either end of the surface.
    -   The closest position along the surface to either end of the other surface.
        -   This closest position, but with a slight offset to account for the width of the player.
        -   This closest position, but with an additional offset to account for horizontal movement with minimum jump time and maximum horizontal velocity.
    -   The closest interior position along the surface to the closest interior position along the other surface.
-   We try to minimize the number of jump/land positions returned, since having more of these greatly increases the overall time to parse the platform graph.
-   We usually consider surface-interior points before surface-end points (which usually puts shortest distances first).
-   We also decide start velocity when we decide the jump/land positions.
    -   We only ever consider start velocities with zero or max speed.
-   Additionally, we often quit early as soon as we've calculated the first valid edge for a given pair of surfaces.
    -   In order to decide whether to skip an edge calculation for a given jump/land position pair, we look at how far away it is from any other jump/land position pair that we already found a valid edge for, on the same surface, for the same surface pair. If it's too close, we skip it.
    -   This is another important performance optimization.

TODO: Include SVG diagrams illustrating the different conditions to consider with all the different surface-pair alignment possibilities.

#### Calculating the start velocity for a jump

-   In the general case, we can't know at build-time what direction along a surface the player will
    be moving from when they need to start a jump.
-   Unfortunately, using start velocity x values of zero for all jump edges tends to produce very
    unnatural composite trajectories (similar to using perpendicular Manhatten distance routes
    instead of more diagonal routes).
-   So, we can assume that for surface-end jump-off positions, we'll be approaching the jump-off
    point from the center of the edge.
-   And for most edges we should have enough run-up distance in order to hit max horizontal speed
    before reaching the jump-off point--since horizontal acceleration is relatively quick.
-   Also, we only ever consider velocity-start values of zero or max horizontal speed. Since the
    horizontal acceleration is quick, most jumps at run time shouldn't need some medium-speed. And
    even if they did, we force the initial velocity of the jump to match expected velocity, so the
    jump trajectory should proceed as expected, and any sudden change in velocity at the jump start
    should be acceptably small.

#### Calculating the total jump duration (and the vertical step for the edge)

-   At the start of each edge-calculation traversal, we calculate the minimum total time needed to reach the destination.
    -   If the destination is above, this might be the time needed to rise that far in the jump.
    -   If the destination is below, this might be the time needed to fall that far (still taking into account any initial upward jump-off velocity).
    -   If the destination is far away horizontally, this might be the time needed to move that far horizontally (taking into account the horizontal movement acceleration and max speed).
    -   The greatest of these three possibilities is the minimum required total duration of the jump.
-   The minimum peak jump height can be determined from this total duration.
-   All of this takes into account our variable-height jump mechanic and the difference in slow-ascent and fast-fall gravities.
    -   With our variable-height jump mechanic, there is a greater acceleration of gravity when the player either is moving downward or has released the jump button.
    -   If the player releases the jump button before reaching the maximum peak of the jump, then their current velocity will continue pushing them upward, but with the new stronger gravity.
    -   To determine the duration to the jump peak height in this scenario, we first construct two instances of one of the basic equations of motion--one for the former part of the ascent, with the slow-ascent gravity, and one for the latter part of the ascent, with the fast-fall gravity. We then use algebra to substitute the equations and solve for the duration.

#### Calculating the horizontal steps in an edge

-   If we decide whether a surface could be within reach, we then check for possible collisions between the origin and destination.
    -   To do this, we simulate frame-by-frame motion using the same physics timestep and the same movement-update function calls that would be used when running the game normally. We then check for any collisions between each frame.
-   If we detect a collision, then we define two possible "constraints"--one for each end of the collided surface.
    -   In order to make it around this intermediate surface, we know the player must pass around one of the ends of this surface.
    -   These constraints we calculate represent the minimum required deviation from the player's original path.
-   We then recursively check whether the player could move to and from each of the constraints.
    -   We keep the original vertical step and overall duration the same.
    -   We can use that to calculate the time and vertical state that must be used for the constraint.
    -   Then we only really consider whether the horizontal movement could be valid within the the given time limit.
-   If so, we concatenate and return the horizontal steps required to reach the constraint from the original starting position and the horizontal steps required to reach the original destination from the constraint.

#### Backtracking to consider a higher max jump height

-   Sometimes, a constraint may be out of reach, when we're calculating horizontal steps, given the current step's starting position and velocity.
-   However, maybe the constraint could be within reach, if we had originally jumped a little higher.
-   To account for this, we backtrack to the start of the overall movement traversal and consider whether a higher jump could reach the constraint.
    -   The destination constraint is first updated to support a new jump height that would allow for a previously-out-of-reach intermediate constraint to also be reached.
    -   Then all steps are re-calculated from the start of the movement, while considering the new destination state.
-   If it could, we return that result instead.

#### Constraint calculations

-   We calculate constraints before steps.
    -   We calculate a lot of state to store on them, and then depend on this state during step calculation.
    -   Some of this state includes:
        -   The time for passing through the constraint (corresponding to the overall jump height and edge duration).
        -   The horizontal direction of movement through the constraint (according to the direction of travel from the previous constraint or according to the direction of the surface).
        -   The min and max possible x-velocity when the movement passes through this constraint.
            -   With a higher speed through a constraint, we could reach further for the next constraint, or we could be stuck overshooting the next constraint. So it's useful to calculate the range of possible horizontal velocities through a constraint.
        -   The actual x-velocity for movement through the constraint is calculated later when calculating the cooresponding movement step.
            -   We typically try to use an x-velocity that will minimize speed through the constraint, while still satisfying the horizontal step displacement and the constraint's min/max limitations.
-   Here's the sequence of events for constraint calculations:
    -   Start by calculating origin and destination constraints.
        -   For the origin constraint, min, max, and actual x-velocity are all zero.
        -   For the destination constraint, min and max are assigned according to how acceleration can be applied during the step (e.g., at the start or at the end of the interval).
    -   Then, during step calculation traversal, when a new intermediate constraint is created, its min and max x-velocity are assigned according to both the min and max x-velocity of the following constraint and the actual displacement and duration of the step from the new constraint to the next constraint.
    -   Intermediate constraints are calculated with pre-order tree traversal.
      -   This poses a small problem:
        -   The calculation of a constraint depends on the accuracy of the min/max x-velocity of it's next constraint.
        -   However, the min/max x-velocity of the next constraint could need to be updated if it in turn has a new next constraint later on.
        -   Additionally, a new constraint could be created later on that would become the new next constraint instead of the old next constraint.
        -   To ameliorate this problem, everytime a new constraint is created, we update its immediate neighbor constraints.
        -   These updates do not solve all cases, since we may in turn need to update the min/max x-velocities and movement sign for all other constraints. And these updates could then result in the addition/removal of other intermediate constraints. But we have found that these two updates are enough for most cases. If we detect that a neigbor constraint would be invalidated during an update, we abandon the edge calculation, which could result in a false-negative result.
    -   Steps are calculated with in-order tree traversal (i.e., in the same order they'd be executed when moving from origin to destination).

#### Fake constraints

-   When calcuting steps to navigate around a collision with a ceiling or floor surface, sometimes one of the two possible constraints is what we call "fake".
-   A fake constraint corresponds to the left side of the floor/ceiling surface when movement from the previous constraint is rightward (or to the right side when movement is leftward).
-   In this case, movement will need to go around both the floor/ceiling as well as its adjacent wall surface.
-   The final movement trajectory should not end-up moving through the fake constraint.
-   The actual constraint that the final movement should move through, is instead the "real" constraint that cooresponds to the far edge of this adjacent wall surface.
-   So, when we find a fake constraint, we immediately replace it with its adjacent real constraint.
-   Example scenario:
  -   Origin is constraint #0, Destination is constraint #3
  -   Assume we are jumping from a low-left platform to a high-right platform, and there is an intermediate block in the way.
  -   Our first step attempt hits the underside of the block, so we try constraints on either side.
  -   After trying the left-hand constraint (#1), we then hit the left side of the block. So we then try a top-side constraint (#2).
      -   (Bottom-side fails the surface-already-encountered check).
  -   After going through this new left-side (right-wall), top-side constraint (#2), we can successfully reach the destination.
  -   With the resulting scenario, we shouldn't actually move through both of the intermediate constraints (#1 and #2). We should should instead skip the first intermediate constraint (#1) and go straight from the origin to the second intermediate constraint (#2).

TODO: screenshot of example scenario

#### Example jump-movement cases that aren't currently covered

-   A single horizontal step that needs multiple different sideways-movement instructions (i.e., accelerating to both one side and then the other in the same jump):
    -   For example, backward acceleration in order to not overshoot the end position as well as forward acceleration to then have enough step-end x velocity in order to reach the following constraint for the next step.

#### Collision calculation madness

**tl;dr**: Godot's collision-detection engine is very broken. We try to make it work for our
pathfinding, but there are still many false negatives and rough edges.

Here's a direct quote from a comment in Godot's underlying collision-calculation logic:

> give me back regular physics engine logic
> this is madness
> and most people using this function will think
> what it does is simpler than using physics
> this took about a week to get right..
> but is it right? who knows at this point..

(https://github.com/godotengine/godot/blob/a7f49ac9a107820a62677ee3fb49d38982a25165/servers/physics_2d/space_2d_sw.cpp#L692)

Some known limitations and rough edges include:
-   TODO

### Navigator: Using the platform graph to move from A to B

Once the platform graph has been parsed, finding and moving along a path through the graph is relatively straight-forward. The sequence of events looks like the following:

-   Given a target point to navigate towards and the player's current position.
-   Find the closest point along the closest surface to the target point.
-   Use A* search to find a path through the graph from the origin to the destination.
    -   We can use distance or duration as the edge weights.
-   Execute playback of the instruction set for each edge of the path, in sequence.

#### Dynamic edge optimization according to runtime approach

At runtime, after finding a path through build-time-calculated edges, we try to optimize the jump-off points of the edges to better account for the direction that the player will be approaching the edge from. This produces more efficient and natural movement. The build-time-calculated edge state would only use surface end-points or closest points. We also take this opportunity to update start velocities to exactly match what is allowed from the ramp-up distance along the edge, rather than either the fixed zero or max-speed value used for the build-time-calculated edge state.

#### Edge instructions playback

When we create the edges, we represent the movement trajectories according to the sequence of instructions that would produce the trajectory. Each instruction is simply represented by an ID for the relevant input key, whether the key is being pressed or released, and the time. The player movement system can then handle these input key events in the same way as actual human-triggered input key events.

#### Correcting for runtime vs buildtime trajectory discrepancies

When executing edge instructions, the resulting run-time trajectory is usually slightly off from the expected trajectory that was pre-calculated when creating the edge. This variance is usually pretty minor, but, just in case, a given player can be configured to use the exact pre-calculated edge trajectory rather than the run-time version.

Theoretically, this discrepancy shouldn't exist, and we should be able to eliminate it at some point.

## Annotators

We include a large collection of annotators that are useful for visually debugging calculation of the platform graph. Some of the more note-worthy annotators include:
-   `CollisionCalculationAnnotator`: 
-   `EdgeCalculationAnnotator`: 
-   `EdgeCalculationTreeViewAnnotator`: 
-   `InterSurfaceEdgesAnnotator`: 
    -   When viewing edge calculation trajectories, each edge is shown with two trajectories:
        -   The darker trajectory represents positions as calculated from _continuous equations of motion_.
        -   The lighter trajectory represents positions as calculated from _simulating movement over distrete time steps_.
-   `NavigatorAnnotator`: 
-   `PlayerAnnotator`: 
-   `PlayerRecentMovementAnnotator`: 
-   `RulerAnnotator`: 
-   `SurfacesAnnotator`: 
TODO: Include a brief description of each annotator.
