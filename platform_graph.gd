extends Reference

# TODO:
# - Update this list to use latest Trello notes
# - pre-parsing:
#   - parse_tilemap: parse TileMap to calculate platform nodes
#   - find_nearby_nodes: within radius or intersecting AABB
#   - node state:
#     - AABB
#     - reference to cells from TileMap
#     - collection of connecting edges / adjacent nodes
#   - edge state:
#     - movement type
#     - DON'T store instructions; dynamically calculate those when starting a given edge traversal
# - traversal:
#   - calculate current node for a given "state" (position, whether player is in-air, whether a wall-grab is active)
#   - implement modified A*:
#     - will need to also give weight to nodes, since we need to walk/climb within a node in order
#       to get to the position where we can start an edge traversal.
#   - Dynamically calculate instructions for the next edge when approaching a new edge traversal.
#   - 

#
# Assumptions:
# - The given TileMap only uses collidable tiles. Use a separate TileMap to paint any non-collidable tiles.
# - 
func parse_tile_map(tile_map):
    var tile_set = tile_map.tile_set
    var cell_size = tile_map.cell_size
    
    for position in tile_map.get_used_cells():
        var tile_set_index = tile_map.get_cellv(position)
        # ConvexPolygonShape2D
        var info = tile_set.tile_get_shapes(tile_set_index)[0]
        var shape = info.shape
        var shape_transform = info.shape_transform
        
        print("*******************************************")
        print("tile_map.cell_size: (%s, %s)" % [cell_size.x, cell_size.y])
        print("position: %s" % position)
        print("info: %s" % info)
        print("shape.points: %s" % shape.points)
        
        for point in shape.points:
            var point_world_coords = shape_transform.xform(point) + position * cell_size
            print("point_world_coords: %s" % point_world_coords)
