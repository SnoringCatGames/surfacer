class_name InspectorItemController
extends Reference

const EDGE_TYPES_TO_SKIP := [ \
    EdgeType.AIR_TO_AIR_EDGE, \
    EdgeType.AIR_TO_SURFACE_EDGE, \
    EdgeType.INTRA_SURFACE_EDGE, \
    EdgeType.JUMP_FROM_SURFACE_TO_AIR_EDGE, \
    EdgeType.UNKNOWN, \
]

var type: int = InspectorItemType.UNKNOWN
var is_leaf: bool
var starts_collapsed: bool
var parent_item: TreeItem
var tree_item: TreeItem
var placeholder_item: TreeItem
var tree: Tree
var graph: PlatformGraph
var are_children_ready: bool

func _init( \
        type: int, \
        is_leaf: bool, \
        starts_collapsed: bool, \
        parent_item: TreeItem, \
        tree: Tree, \
        graph: PlatformGraph) -> void:
    self.type = type
    self.is_leaf = is_leaf
    self.starts_collapsed = starts_collapsed
    self.parent_item = parent_item
    self.tree = tree
    self.graph = graph
    
    self.tree_item = tree.create_item(parent_item)
    self.tree_item.set_metadata( \
            0, \
            self)
    self.tree_item.collapsed = starts_collapsed
    
    self.are_children_ready = false

func _post_init() -> void:
    _update_text()
    
    if get_has_children():
        _create_placeholder_item()
        if !starts_collapsed:
            self.call_deferred("_create_children_if_needed")

func destroy() -> void:
    if !is_instance_valid(tree_item):
        # Already destroyed.
        return
    _destroy_children_if_needed()
    if get_has_children():
        _destroy_placeholder_item()
    tree_item.set_metadata( \
            0, \
            null)
    if is_instance_valid(parent_item):
        parent_item.remove_child(tree_item)
    tree_item = null
    parent_item = null

func on_item_selected() -> void:
    if Surfacer.get_is_inspector_panel_open() and \
            !tree.get_is_find_and_expand_in_progress():
        print_msg("Inspector item selected: %s", to_string())

func on_item_expanded() -> void:
    _create_children_if_needed()
    if Surfacer.get_is_inspector_panel_open() and \
            !tree.get_is_find_and_expand_in_progress():
        print_msg("Inspector item expanded: %s", to_string())

func on_item_collapsed() -> void:
    _destroy_children_if_needed()
    if Surfacer.get_is_inspector_panel_open() and \
            !tree.get_is_find_and_expand_in_progress() and \
            get_has_children():
        print_msg("Inspector item collapsed: %s", to_string())

func expand() -> void:
    var was_collapsed := tree_item.collapsed
    tree_item.collapsed = false
    if was_collapsed:
        on_item_expanded()

func collapse() -> void:
    if !is_instance_valid(tree_item):
        return
    var was_collapsed := tree_item.collapsed
    tree_item.collapsed = true
    if !was_collapsed:
        on_item_collapsed()

func select() -> void:
    tree_item.select(0)
    
    # Scroll to the correct spot.
    var before_scroll := tree.get_scroll()
    tree.ensure_cursor_is_visible()
    var after_scroll := tree.get_scroll()
    # Godot's default logic doesn't always scroll quite enough to make the
    # selected item visible, so we add a little extra scroll.
    var scrolled_down := after_scroll > before_scroll
    # TODO: Godot doesn't seem to expose any way to assign the scroll position.

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> bool:
    Gs.utils.error( \
            "Abstract InspectorItemController" + \
            ".find_and_expand_controller is not implemented")
    return false

func _trigger_find_and_expand_controller_recursive( \
        search_type: int, \
        metadata: Dictionary) -> void:
    tree._increment_find_and_expand_controller_recursive_count()
    call_deferred( \
            "_find_and_expand_controller_recursive_wrapper", \
            search_type, \
            metadata)

func _find_and_expand_controller_recursive_wrapper( \
        search_type: int, \
        metadata: Dictionary) -> void:
    _find_and_expand_controller_recursive( \
            search_type, \
            metadata)
    tree.call_deferred("_decrement_find_and_expand_controller_recursive_count")

func _find_and_expand_controller_recursive( \
        search_type: int, \
        metadata: Dictionary) -> void:
    Gs.utils.error( \
            "Abstract InspectorItemController" + \
            "._find_and_expand_controller_recursive is not implemented")

func get_text() -> String:
    Gs.utils.error("Abstract InspectorItemController.get_text is not implemented")
    return ""

func get_description() -> String:
    Gs.utils.error( \
            "Abstract InspectorItemController.get_description is not " + \
            "implemented")
    return ""

func to_string() -> String:
    return "%s {}" % InspectorItemType.get_string(type)

func get_has_children() -> bool:
    return !is_leaf

func _create_children_if_needed() -> void:
    if !are_children_ready:
        _create_children_inner()
        if get_has_children():
            _destroy_placeholder_item()
    are_children_ready = true

func _destroy_children_if_needed() -> void:
    if are_children_ready:
        var child := tree_item.get_children()
        while child != null:
            var metadata: InspectorItemController = child.get_metadata(0)
            if is_instance_valid(metadata):
                metadata.destroy()
            child = child.get_next()
        
        _destroy_children_inner()
        
        if get_has_children():
            _create_placeholder_item()
    
    are_children_ready = false

func _create_placeholder_item() -> void:
    placeholder_item = tree.create_item(tree_item)

func _destroy_placeholder_item() -> void:
    if placeholder_item == null:
        # Already destroyed.
        return
    tree_item.remove_child(placeholder_item)
    placeholder_item = null

func _update_text() -> void:
    tree_item.set_text( \
            0, \
            get_text())

func _create_children_inner() -> void:
    Gs.utils.error("Abstract InspectorItemController._create_children_inner is not implemented")

func _destroy_children_inner() -> void:
    Gs.utils.error("Abstract InspectorItemController._destroy_children_inner is not implemented")

func get_annotation_elements() -> Array:
    Gs.utils.error("Abstract InspectorItemController.get_annotation_elements is not implemented")
    return []

# Conditionally prints the given message, depending on the Player's
# configuration.
func print_msg( \
        message_template: String, \
        message_args = null) -> void:
    if Surfacer.is_surfacer_logging and \
            graph.movement_params.logs_inspector_events:
        if message_args != null:
            Gs.utils.print(message_template % message_args)
        else:
            Gs.utils.print(message_template)
