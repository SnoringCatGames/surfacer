# TODO


### Next

- Figure out how to set up the Surfacer manifest.
  - This should be accessible from C++.
  - So does this need to be _defined_ from C++?
  - This will be separate from the Scaffolder manifest, which is a plain .tres file.
- Review Godot's default Navigation APIs. And other engine APIs.
- Finish thinking about the high-level API design from the user's perspective.
- Review Surfacer v1 logic.
- Finish thinking about the high-level algorithm design, and what parts to preserve and change from Surfacer v1.
- Address some of the FIXMEs from porting over the current Scaffolder logic.
- Set up annotations system.
- Set up surface parsing.
  - Just use vanilla tilemaps for now.
  - BUT, make sure I'll be able to support custom level geometry later (with custom vertices, marching squares, and destructible terrain!).
  - Use threading.
- Set up basic jump-trajectory calculations between surfaces.
  - Use threading.
- And fall-trajectory calculations.
- Implement template calculations.
  - Use threading.
- Implement pre-calculation of templates based on movement-parameters.
- Implement saving and loading of templates.
- Implement change-detection of pre-calculated templates with latest movement-parameters, and re-calculation and saving of templates as needed, at app-start time.
  - Use checksums? Or some custom equality checks, with recorded movement-parameters metadata associated with the template?
- Ensure templates are included in git and included in exported builds.
- Implement pathfinding.
- Implement path traversal.
- Implement surface-state tracking.
- Implement a new choreographer system.
  - Auto-play this in a simple test level.


### High-level

- Survey other current options for platformer navigation.
- Decide on the ideal API. Try to be consistent with Godot's default top-down 2D navigation APIs.
- Then, create the C++ files to match that ideal API.
- Then, implement the functionality!


### API design

- Configure movement parameters globally, removed from character definitions.
  - Encourage a limited set of movement parameters.
  - Have the user provide a Resource that extends our parent MovementParameters.
  - Have the user pass this Resource to Su.set_up, among other things!
  - Define SurfacerCharacter (extends CharacterBody2D). The user extends this for any node that use Surfacer navigation.
  - Similar to Surfacer v1, try to apply movement and position state using the underlying vanilla Godot APIs (actually set velocity, position, move_and_slide (or whatever it is now), record collisions, etc.). So users should be able to rely on all the usual tools they're familiar with.
  - 
- Use multi-threading.
- Include whatever weird deps I want in the demo/ app.
  - These won't be included in the resulting compiled GDExtension.
  - So it should be safe to include external Surfacer and Behavior tree plugins from there.
- LEFT OFF HERE


### Pathfinding algorithm

- What to keep and port-over from Surfacer v1.
  - 
- What to get rid of from Surfacer v1.
  - Behaviors
- Support cheap run-time jump calculations.
  - No more storing static, pre-calculated platform graphs.
  - _Maybe_ cache recently calculated jumps, for quick lookups later.
  - Support more fudging of accurate trajectories.
    - Forcing characters to reach expected positions at expected times.
- LEFT OFF HERE


### OLD NOTES: Jump-range templates per-player in place of a platform graph

- Consider an alternative possibility of doing the pathfinding completely differently:
- This should be able to have no up-front run-time graph-parsing cost.
  - There would instead only be a relatively small cost at build-time for calculating jump-range templates for each player movement type.
    - This would be saved/loaded with a separate file, rather than dynamically calculated.
- Approach:
  - With just local /nearby navigation.
  - Without any graph.
  - Just using knowledge of all possible jump trajectories for each cell within reach for a given players movement params.
  - That is, precalculate for the player a grid, and record a jump trajectory and instructions for each cell.
  - E.g. (-1,-2) would jump up/left briefly
  - Could then also precalculate for each cell/trajectory an additional grid that defines the collision cells for that trajectory.
  - Pros:
    - Better for levels with small grid cell size (more dense surface counts).
    - Better for large levels.
    - Better for procedurally generated levels that can't be precomputed before given to the user.
    - Better for levels that change at run time (e.g. destructible terrain).
    - Either better initial load times or build times.
    - The dynamic edge optimization of the earlier A* approach adds extra run time cost that this avoids.
  - Cons:
    - Less efficient navigation, potentially more so for distant destinations.
    - Worse performance with many players.
      - Need to do multiple sub navigation decisions for each navigation.
      - Each sub navigation requires checking the player's jump trajectory grid against their current location in the level.
        - Possibly, this could be reasonably efficient?
    - Unable to precompute some types of move-around trajectories.
      - Enumerate the scenarios that out would some with, and the ones that don't matter. Make fine, probably?
        - Move to higher floor, around ledge of floor, from an origin outward from ledge.
          - Should be precomputable, since ledge depth doesn't matter.
        - Move to higher floor, around ledge of floor, from an origin underneath ledge.
          - A problem, since depth of ledge makes a difference.
        - Move down around and past an intermediate floor.
          - Not something that can be precomputed, but also, not something we probably care about, since we could probably just land on the intermediate floor.
            - Not true though for damaging or not land-safe floors, if the mechanics of the specific platformer support that.
        - Walls: will be similar issues moving around floor ledges depending on depth of collision area.
          - But will be similarly fine for most cases, since should be able to land on floors instead of having to go around them, most of the time (depending on game mechanics).
    - Similarly, is limited to only land on very ends of floor ledges or tops/bottoms of walls.
    - Same limitation of depending on the specific start velocity.
      - Can just calculate three versions: v0=0, v0=+max, v0=-max.
      - But, wouldn't be able to handle dynamic, in-air land trajectories.
    - Only able to handle a limited distance for surfaces-in-fall-range.
      - Needing to handle surfaces in fall range also means that the precomputed takes grid will need to be a trapezoidal shape.
- Solution to the jump up around overhang problem for the alternative navigation approach
  - determine whether we need to move around left or right side of target cell floor.
  - then just apply horizontal component to trajectory as early as possible.
  - record the intersected trajectory cells as normal.
  - should be able to check trajectory collision mask easily as normal.
- Questions:
  - How to evaluate current nearby level space in order to pick best location to move to?
  - How to modify jump trajectory calculation to account for going around the ledge of the floor, instead of cutting it to close and clipping the corner on the way past (and similar problem for tops/bottoms of walls)?
    - One option would be to handle all horizontal acceleration as late and strong as possible, but that produces slightly less natural movement.
    - Another option would be to do some complicated min/max x velocity waypoint calculations, as we did for the earlier navigation approach.
- Other problems:
  - Will need to precompute trajectories from three sides of each cell to three sides of each other cell in grid (a LOT of space).
  - Can probably fix this by downsampling.
    - Would need to then add more logic to adjust horizontal/vertical movement at run time.
  - Given an origin and destination cell, consider the higher cell:
    - Which side of this cell should the trajectory pass by in order to reach to/from the lower cell?
    - We could need to use either, depending on the level shape at run time.
    - That means we probably need to precompute trajectories for both cases.
- Additional notes:
  - Keep two versions of level up to date and in sync:
    - TileMap
    - Custom 2D array
  - Implement custom collision detection using 2D array.
    - Can take advantage of the fact that all level geometries will be axially-aligned squares.
      - Makes collision detection much cheaper.
  - Spend some time researching Oct or R trees or whatever to have a good understanding of how to access and check for collisions hierarchically.
