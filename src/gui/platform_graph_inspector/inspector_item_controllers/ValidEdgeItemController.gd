class_name ValidEdgeItemController
extends EdgeAttemptItemController

const TYPE := InspectorItemType.VALID_EDGE

var edge: Edge

func _init(
        parent_item: TreeItem,
        tree: Tree,
        graph: PlatformGraph,
        edge: Edge) \
        .(
        TYPE,
        parent_item,
        tree,
        graph,
        edge) -> void:
    assert(edge != null)
    self.edge = edge
    _post_init()

func to_string() -> String:
    return "%s { %s [%s, %s] }" % [
        InspectorItemType.get_string(type),
        EdgeType.get_string(edge.edge_type),
        str(edge.get_start()),
        str(edge.get_end()),
    ]

func get_text() -> String:
    return "[%s, %s]" % [
        str(edge.get_start()),
        str(edge.get_end()),
    ]

func get_description() -> String:
    return ("This %s consists of %s horizontal instructions.") % [
        EdgeType.get_string(edge.edge_type),
        edge.trajectory.horizontal_instructions.size() if \
        edge.trajectory != null else \
        1,
    ]

func get_annotation_elements() -> Array:
    var element := EdgeAnnotationElement.new(
            edge,
            true,
            true,
            true,
            true)
    return [element]
