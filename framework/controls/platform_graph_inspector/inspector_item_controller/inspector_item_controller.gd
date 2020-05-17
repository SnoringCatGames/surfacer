extends Reference
class_name InspectorItemController

const EDGE_TYPES_TO_SKIP := [ \
    EdgeType.AIR_TO_AIR_EDGE, \
    EdgeType.AIR_TO_SURFACE_EDGE, \
    EdgeType.INTRA_SURFACE_EDGE, \
    EdgeType.JUMP_FROM_SURFACE_TO_AIR_EDGE, \
    EdgeType.UNKNOWN, \
]

var type: int = InspectorItemType.UNKNOWN
var parent_item: TreeItem
var tree_item: TreeItem
var tree: Tree
var are_children_ready := false

func _init( \
        type: int, \
        starts_collapsed: bool, \
        parent_item: TreeItem, \
        tree: Tree) -> void:
    self.type = type
    self.parent_item = parent_item
    self.tree = tree
    
    self.tree_item = tree.create_item(parent_item)
    tree_item.set_metadata( \
            0, \
            self)
    tree_item.collapsed = starts_collapsed

func destroy() -> void:
    tree_item.set_metadata( \
            0, \
            null)
    parent_item.remove_child(tree_item)
    tree_item = null
    parent_item = null
    _destroy_children()
    are_children_ready = false

func on_item_selected() -> void:
    _draw_annotations()

func on_item_expanded() -> void:
    if !are_children_ready:
        _create_children()
    are_children_ready = true

func on_item_collapsed() -> void:
    _destroy_children()
    are_children_ready = false

func expand() -> void:
    tree_item.collapsed = false
    on_item_expanded()

func collapse() -> void:
    tree_item.collapsed = true
    on_item_collapsed()

func select() -> void:
    tree_item.select(0)

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> InspectorItemController:
    Utils.error("Abstract InspectorItemController.find_and_expand_controller is not implemented")
    return null

func get_text() -> String:
    Utils.error("Abstract InspectorItemController.get_text is not implemented")
    return ""

func to_string() -> String:
    return "%s {}" % InspectorItemType.get_type_string(type)

func _create_children() -> void:
    Utils.error("Abstract InspectorItemController._create_children is not implemented")

func _destroy_children() -> void:
    Utils.error("Abstract InspectorItemController._destroy_children is not implemented")

func _draw_annotations() -> void:
    Utils.error("Abstract InspectorItemController._draw_annotations is not implemented")

func _update_text() -> void:
    tree_item.set_text( \
            0, \
            get_text())
