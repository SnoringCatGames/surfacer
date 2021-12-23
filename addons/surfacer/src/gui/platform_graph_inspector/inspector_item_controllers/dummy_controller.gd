class_name DummyItemController
extends InspectorItemController
# -   For some reason, the Tree widget seems to auto squash the first item into
#     the root.
# -   So this item exists to get squashed.
# -   Otherwise, we'd never see the first platform-graph item, and we'd instead
#     only see its children.

const TYPE := InspectorItemType.UNKNOWN
const IS_LEAF := true
const STARTS_COLLAPSED := false


func _init(
        parent_item: TreeItem,
        tree: Tree,
        graph: PlatformGraph) \
        .(
        TYPE,
        IS_LEAF,
        STARTS_COLLAPSED,
        parent_item,
        tree,
        graph) -> void:
    _post_init()


func get_text() -> String:
    return "Dummy controller"


func get_description() -> String:
    return "Dummy controller"


func to_string() -> String:
    return "Dummy controller"
