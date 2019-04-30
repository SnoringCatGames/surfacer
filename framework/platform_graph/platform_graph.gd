extends Reference
class_name PlatformGraph

var surface_parser: SurfaceParser
# Array<Surface>
var nodes: Array
# Array<Edge>
var edges: Array

func _init(surface_parser: SurfaceParser, player_info: PlayerTypeConfiguration) -> void:
    self.surface_parser = surface_parser
    
    # Store the subset of surfaces that this player type can interact with.
    self.nodes = surface_parser.get_subset_of_surfaces( \
            player_info.movement_params.can_grab_walls, \
            player_info.movement_params.can_grab_ceilings, \
            player_info.movement_params.can_grab_floors)
    
    # Calculate and store the edges between surface nodes that this player type can traverse.
    self.edges = EdgeParser.calculate_edges(nodes, player_info)
