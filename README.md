---------------------------------------------------------

# Squirrel Away

_A simple 2D-platformer with cats, squirrels, and nuts._

_This is a demo for the [Surfacer](https://github.com/levilindsey/surfacer) pathfinding framework._

_TODO: In development. Not ready for review._

TODO

---------------------------------------------------------

# Surfacer

_A 2D-platformer procedural pathfinding framework for Godot._

_"Surfacer": Like a platformer, but with walking and climbing on all surfaces!_

TODO: _For a demo app using this framework, checkout [Squirrel Away](https://github.com/levilindsey/squirrel-away)_

_TODO: In development. Not ready for review._

TODO

# Platformer AI

TODO

## Pre-parsing the world into a platform graph

In order for our AI to traverse our world, we first need to parse the world into a platform graph.

The nodes of this graph correspond to distinct surfaces. Since our players can both walk on floors and climb on walls, we store both floor and wall surfaces.

The edges of this graph correspond to a type of movement that the player could perform in order to move from one surface node to another.
- There could be multiple edges between a single pair of nodes, since there could be multiple types of movement that could get the player from the one platform to the other.
- These edges are directional, since the player may be able to move from A to B but not from B to A.
- These edges are specific to a given player type. If we need to consider a different player that has a different move set, then we need to calculate a separate set of edges for that player.

### Parsing a Godot `TileMap` into surfaces

The following algorithm assumes that the given `TileMap` only uses tiles with convex collision boundaries.

#### Parse individual tiles into their constituent surfaces

- Map each `TileMap` cell into a polyline that corresponds to the top-side/"floor" portion of its collision polygon.
    - Calculate whether the collision polygon's vertices are specified in a clockwise order.
        - Use this to determine the iteration step size.
            - `step_size = 1` if clockwise; `step_size = -1` if counter-clockwise.
        - Regardless of whether the vertices are specified in a clockwise order, we will iterate over them in clockwise order.
    - Find both the leftmost and rightmost vertices.
    - Start with the leftmost vertex.
        - If there is a wall segment on the left side of the polygon, then this vertex is part of it.
        - If there is no wall segment on the left side of the polygon, then this vertex must be the cusp between a preceding bottom-side/"ceiling" segment and a following top-side/"floor" segment (i.e., the previous segment is underneath the next segment).
    - Iterate over the following vertices until we find a non-wall segment (this could be the first segment, the one connecting to the leftmost vertex).
    - This non-wall segment must be the start of the top-side/"floor" polyline.
    - Iterate, adding segments to the result polyline, until we find either a wall segment or the rightmost vertex.
- Repeat the above `TileMap` parsing for the right-side and left-side surfaces.

#### Remove internal surfaces

This will only detect internal surface segments that are equivalent with another internal segment. But for grib-based tiling systems, this can often be enough.

- Check for pairs of floor+ceiling segments or left-wall+right-wall segments, such that both segments share the same vertices.
- Remove both segments in these pairs.

#### Merge any connecting surfaces

- Iterate across each floor surface A.
- Nested iterate across each other floor surface B.
    - Ideally, we should be using a spatial data structure that allows us to only consider nearby surfaces during this nested iteration.
- Check whether A and B form a "continuous" surface.
    - A and B are both polylines that only have two end points.
    - Just check whether either endpoint of A equals either endpoint of B.
        - Actually, our original `TileMap` parsing results in every surface polyline being stored in clockwise order, so we only need to compare the end of A with the start of B and the start of A with the end of B.
- If they do:
    - Merge B into A.
    - Optionally, remove any newly created redundant internal colinear points.
    - Remove B from the surface collection.
- Repeat the iteration until no merges were performed.

#### Record adjacent neighbor surfaces

- Every surface should have both adjacent clockwise and counter-clockwise neighbor surfaces.
- Use a similar process as above for finding surfaces with matching end positions.

### Calculating edges

TODO

The `Surfacer` framework uses a procedural approach to calculate trajectories and intstructions
for movement between surfaces. The algorithms used rely heavily on the classic [one-dimensional
equations of motion for constant acceleration](https://physics.info/motion-equations/).

A machine-learning-based approach would probably be a better way to solve this general problem.
However, one perk of a procedural approach is that it's relatively easy to understand how it works
and to modify it to perform better for any given edge-case.

#### The high-level steps

- Determine how high we need to jump in order to reach the destination.
- If the destination is out of reach, ignore it.
- If there is an intermediate Surface that the player would collide with, we need to try adjusting the jump trajectory to go around either side of the colliding Surface.
  - Recursively check whether the jump is valid to and from either side of the colliding Surface.
  - If we can't reach the destination when moving around the colliding Surface, then try backtracking and consider whether a higher jump height would get us there.

#### Miscellaneous info

- We treat horizontal and vertical motion as independent to each other. This greatly simplifies our
  calculations.
  - We calculate vertical motion up-front, and use this to determine times for each step and
    constraint of the motion. Knowing these times makes the horizontal min/max calculations easier.
- We have a broad-phase check to eliminate possible surfaces that are obviously out of reach.
  - TODO: describe it
- We record a set of all Surfaces that have been collided with during the overall edge-calculation traversal.
  - We know that a new recursive iteration can never collide with any of the Surfaces that any past
    iteration collided with. If it did, it would end up on a traversal branch that's identical to
    one we've already eliminated, which would lead to an infinite loop.
  - The one exception is with ceiling surfaces. If we hit a ceiling surface again, it must be because we have backtracked to consider a higher jump height, and the traversal branches after this collision can be different than those of a previously eliminated traversal.

#### TODO

- We consider three potential points as our jump-off and land positions along a Surface: the near end, the far end, and the closest point.
  - We check for valid edge movement instructions along each potential jump/land position pair between the two Surfaces, and we save any edges that are valid.
    - This means we could potentially save nine edges between each pair of Surfaces.
    - Having multiple edges between a given pair gives us more flexibility to choose a more natural and efficient path depending on where the player is coming from and going to.
  - We only consider the closest point if it is distint from near and far ends.
  - Also, we do allow degenerate Surfaces that consiste of only a single point, so we only consider the "far end" if it is not such a Surface.

#### Calculating the steps in an edge

- If we decide whether a surface could be within reach, we then check for possible collisions between the origin and destination.
  - To do this, we simulate frame-by-frame motion using the same physics timestep and the same movement-update function calls that would be used when running the game normally. We then check for any collisions between each frame.
- If we detect a collision, then we define two possible constraints--one for each end of the collided Surface.
  - In order to make it around this intermediate Surface, we know the player must pass around one of the sides of this Surface.
  - These constraints we calculate represent the minimum required deviation from the player's original path.
- We then recursively check whether the player could move to and from each of the constraints.
- If so, we concatenate and return the steps required to reach the constraint from the original starting position and the steps required to reach the original destination from the constraint.

#### Calculating the total jump duration

- At the start of each edge-calculation traversal, we calculate the minimum total time needed to
  reach the destination.
  - If the destination is above, this might be the time needed to rise that far in the jump.
  - If the destination is below, this might be the time needed to fall that far (still taking into
    account our initial upward jump-off velocity).
  - If the destination is far away horizontally, this might be the time needed to move that far
    horizontally (taking into account the horizontal movement acceleration and max speed).
  - The greatest of these three possibilities is the minimum required total duration of the jump.
- The minimum peak jump height can be determined from this total duration.
- All of this takes into account our variable-height jump mechanic and the difference in
  slow-ascent and fast-fall gravities.
  - With our variable-height jump mechanic, there is a greater acceleration of gravity when the
    player either is moving downward or has released the jump button.
  - If the player releases the jump button before reaching the maximum peak of the jump, then their
    current velocity will continue pushing them upward, but with the new stronger gravity.
  - To determine the duration to the jump peak height in this scenario, we first construct two
    instances of one of the basic equations of motion--one for the former part of the ascent, with
    the slow-ascent gravity, and one for the latter part of the ascent, with the fast-fall gravity.
    We then use algebra to substitute the equations and solve for the duration.

#### Backtracking to consider a higher max jump height

- Sometimes, a constraint may be out of reach, given our current step's starting position and velocity.
- However, maybe the constraint could be within reach, if we had originally jumped a little higher.
- To account for this, we backtrack to the start of the overall movement traversal and consider whether a higher jump could reach the constraint.
- If it could, then we use those new steps instead of our previously calculated steps, and we then recursively check whether we can reach the destination from the constraint.

#### Example jump-movement cases that aren't currently covered

- A single step that needs multiple different sideways-movement instructions:
  - E.g., backward acceleration in order to not overshoot the end position as well as forward
    acceleration to then have enough step-end x velocity in order to reach the following
	constraint for the next step.
- 

## Tests

_NOTE: The unit tests are currently broken. They worked early on, but they were not updated with later refactors._ 

Surfacer uses the [Gut tool](https://github.com/bitwes/Gut) for writing and running unit tests.

For convenience, this is checked in the with rest of the Surfacer framework.

# TODO: New things to mention...

- New, simpler mental model for how the recursion works with backtracking on height:
  - Any time we attempt backtracking for increased height, we just start the entire recursion over from the start, and return the complete result.
    - We no longer attempt to concatenate anything with recursive traversals with backtracking.
    - Instead, concatenation and recursion is only done in the non-backtracking part.
- The iteration...
  - Create the origin and destination constraints.
  - Create the vertical step (base some state off of origin and destination constraints).
    - Calculating the vertical step up-front, enables us to determine the times for each constraint and step in the movement. This in turn, makes horizontal calculations (especially relating to min/max velocity) easier.
  - Try to calculate a movement trajectory from the start constraint to the end constraint.
  - If the end constraint is out of reach, return null.
  - If the movement constraint did not collide with any intermediate surfaces, return the valid movement.
  - Else, if there was a collision:
    - Calculate new intermediate constraints along either edge of the collided surface.
    - For each of these new constraints:
      - Calculate the time for passing through the constraint (using vertical step state).
      - Calculate the direction of movement through the constraint (according to the direction of travel from the previous constraint or according to the direction of the surface).
      - Calculate the min and max possible x-velocity when the movement passes through this constraint (this is based off of the min and max x-velocity from the next constraint, as well as the time and distance from the current constraint to the next constraint).
      - Calculate the actual x-velocity for movement through the constraint (aka, the step-start x-velocity for the corresponding movement step).
- When backtracking on jump height:
  - The destination constraint is first updated to support a new jump height that would allow for a previously-out-of-reach intermediate constraint to also be reached.
  - Then all steps are re-calculated from the start of the movement, while considering the new destination state.
- Updating min/max velocities in response to new intermediate constraints:
  - The introduction of a new intermediate constraint can change the min/max x-velocity values for both its previous and following neighbor constraints.
  - Because of this, we update neighbor constraints when adding a new constraint.
  - However, there are a couple limitations of these updates:
    - It is possible that the creation of a new intermediate constraint could also invalidate the actual x-velocity for the previous constraint(s).
      - A fix for this would be to first recalculate the min/max x velocities for all previous constraints in backward order, and then recalculate the actual x velocity for all previous constraints in forward order.
      - This still is not completely sufficient though, since changing the actual x-velocity could change the trajectory and introduce/remove constraints.
    - Additionally, the creation of constraints from in-progress recursion could introduce/remove neighbor constraints.
    - FIXME: Check whether I need to add any of the following expensive updates... HOWEVER, this might still work for most cases? Let's try it. If it works, let's just document well what types of things fail. We can't solve this efficiently for all cases, so we have to pick reasonable heuristics at some point.
- Mention, in general, why accelerating at the start vs end of the interval changes things.
- Describe skipping constraints:
  - Sometimes we should be able to skip a constraint and go straight from the earlier one to the later one.
  - Example scenario:
    - Origin is constraint #0, Destination is constraint #3
    - Assume we are jumping from low-left platform to high-right platform, and there
      is an intermediate block in the way.
    - Our first step attempt hits the underside of the block, so we try constraints on
      either side.
    - After trying the left-hand constraint (#1), we then hit the left side of the
      block. So we then try a top-side constraint (#2). (bottom-side fails the
      surface-already-encountered check).
    - After going through this new left-side (right-wall), top-side constraint, we can
      successfully reach the destination.
    - Problem 1: With the resulting path, we still have to go through both of the
      constraints. We should should be able to skip the first constraint and go
      straight from the origin to the second constraint.
    - Problem 2: With the current plan-of-attack with this design, we would be forced
      to be going leftward when we pass through the first constraint.

#### How horizontal instructions are calculated

- Start by calculating origin and destination constraints.
- Origin min, max, and actual x-velocity are all zero.
- Destination min and max are assigned according to how acceleration can be applied during the step (e.g., at the start or at the end of the interval).
- Then, during step calculation traversal, when a new constraint is created, its min and max x-velocity are assigned according to both the min and max x-velocity of the following constraint and the actual displacement and duration of the step from the new constraint to the next constraint.
- Constraints are calculated with pre-order tree traversal.
  - This poses a small problem:
    - The calculation of a constraint depends on the accuracy of the min/max x-velocity of it's next constraint.
    - However, the min/max x-velocity of the next constraint could need to be updated if it in turn has a new next constraint later on.
    - Additionally, a new constraint could be created later on that would become the new next constraint instead of the old next constraint.
    - To ameliorate this problem, everytime a new constraint is created, we update its immediate neighbor constraints.
    - These updates do not solve all cases, since we may in turn need to update the min/max x-velocities and movement sign for all other constraints. And these updates could then result in the addition/removal of other intermediate constraints. But we have found that these two updates are enough for most cases.
- Then, when a new step is calculated, the actual x-velocity of the end constraint is assigned to have the minimum-possible speed that is reachable from the min/max x-velocity of the start constraint.
- Steps are calculated with in-order tree traversal (i.e., in the same order they'd be executed when moving from origin to destination).

#### Fake constraints

- When calcuting steps to navigate around a collision with a ceiling or floor surface, sometimes one of the two possible constraints is what we call "fake".
- A fake constraint corresponds to the left side of the floor/ceiling surface when movement from the previous constraint is rightward (or to the right side when movement is leftward).
- In this case, movement will need to go around both the floor/ceiling as well as its adjacent wall surface.
- The final movement trajectory should not end-up moving through the fake constraint.
- The actual constraint that the final movement should move through, is instead the "real" constraint that cooresponds to the far edge of this adjacent wall surface.
- So, when we find a fake constraint, we immediately replace it with its adjacent real constraint.
