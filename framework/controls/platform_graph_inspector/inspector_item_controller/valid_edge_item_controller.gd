extends InspectorItemController
class_name ValidEdgeItemController

const TYPE := InspectorItemType.VALID_EDGE
const IS_LEAF := false
const STARTS_COLLAPSED := true

var edge: Edge

func _init( \
        tree_item: TreeItem, \
        tree: Tree, \
        edge: Edge) \
        .( \
        TYPE, \
        IS_LEAF, \
        STARTS_COLLAPSED, \
        tree_item, \
        tree) -> void:
    self.edge = edge
    _post_init()

func to_string() -> String:
    return "%s { %s [%s, %s] }" % [ \
        InspectorItemType.get_type_string(type), \
        EdgeType.get_type_string(edge.type), \
        str(edge.start), \
        str(edge.end), \
    ]

func get_text() -> String:
    return "[%s, %s]" % [ \
        str(edge.start), \
        str(edge.end), \
    ]

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> InspectorItemController:
    assert(search_type == InspectorSearchType.EDGE)
    if Geometry.are_points_equal_with_epsilon( \
                    edge.start, \
                    metadata.start, \
                    0.01) and \
            Geometry.are_points_equal_with_epsilon( \
                    edge.end, \
                    metadata.end, \
                    0.01):
        expand()
        select()
        return self
    return null

func _create_children_inner() -> void:
    # FIXME: ----------------------------
    pass

func _destroy_children_inner() -> void:
    # FIXME: ---------------------------
    pass

func _draw_annotations() -> void:
    # FIXME: -----------------
    pass
