# climber
TODO: In development

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

### Calculating edges

TODO
