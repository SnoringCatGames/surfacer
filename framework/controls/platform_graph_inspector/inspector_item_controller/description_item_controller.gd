extends InspectorItemController
class_name DescriptionItemController

const TYPE := InspectorItemType.DESCRIPTION
const IS_LEAF := true
const STARTS_COLLAPSED := true

var text: String

func _init( \
        parent_item: TreeItem, \
        tree: Tree, \
        graph: PlatformGraph, \
        text: String) \
        .( \
        TYPE, \
        IS_LEAF, \
        STARTS_COLLAPSED, \
        parent_item, \
        tree, \
        graph) -> void:
    self.text = text
    _post_init()

func to_string() -> String:
    return "%s { text=%s }" % [ \
        InspectorItemType.get_type_string(type), \
        text, \
    ]

func get_text() -> String:
    return text

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> InspectorItemController:
    return null

func _create_children_inner() -> void:
    # Do nothing.
    pass

func _destroy_children_inner() -> void:
    # Do nothing.
    pass

func get_annotation_elements() -> Array:
    # Do nothing.
    return []
