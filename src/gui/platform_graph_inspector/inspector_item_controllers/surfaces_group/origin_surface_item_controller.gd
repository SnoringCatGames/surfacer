class_name OriginSurfaceItemController
extends InspectorItemController


const TYPE := InspectorItemType.ORIGIN_SURFACE
const IS_LEAF := false
const STARTS_COLLAPSED := true

var origin_surface: Surface
# Dictionary<Surface, Dictionary<EdgeType, Array<InterSurfaceEdgesResult>>>
var destination_surfaces_to_edge_types_to_edges_results := {}
# Array<Surface>
var attempted_destination_surfaces := []
var valid_edge_count := 0
var failed_edge_count := 0
var is_debug_only_state_populated := false

# Array<Vector2>
var fall_range_polygon_without_jump_distance: Array
# Array<Vector2>
var fall_range_polygon_with_jump_distance: Array

# Array<Surface>
var surfaces_in_fall_range: Array
# Array<Surface>
var surfaces_in_jump_range: Array

var valid_edges_count_item_controller: DescriptionItemController
var fall_range_description_item_controller: DescriptionItemController
var jump_range_description_item_controller: DescriptionItemController


func _init(
        parent_item: TreeItem,
        tree: Tree,
        graph: PlatformGraph,
        origin_surface: Surface,
        destination_surfaces_to_edge_types_to_edges_results: Dictionary) \
        .(
        TYPE,
        IS_LEAF,
        STARTS_COLLAPSED,
        parent_item,
        tree,
        graph) -> void:
    self.origin_surface = origin_surface
    self.destination_surfaces_to_edge_types_to_edges_results = \
            destination_surfaces_to_edge_types_to_edges_results
    _calculate_metadata()
    _post_init()


func _calculate_metadata() -> void:
    # Count the valid and failed edges from this surface.
    var edge_types_to_edges_results: Dictionary
    valid_edge_count = 0
    failed_edge_count = 0
    for destination_surface in \
            destination_surfaces_to_edge_types_to_edges_results:
        edge_types_to_edges_results = \
                destination_surfaces_to_edge_types_to_edges_results \
                        [destination_surface]
        for edge_type in edge_types_to_edges_results:
            for edges_result in edge_types_to_edges_results[edge_type]:
                valid_edge_count += edges_result.valid_edges.size()
                failed_edge_count += edges_result.failed_edge_attempts.size()
    
    # Populate a sorted list of all attempted destination edges.
    attempted_destination_surfaces.clear()
    for destination_surface in \
            destination_surfaces_to_edge_types_to_edges_results:
        attempted_destination_surfaces.push_back(destination_surface)
    attempted_destination_surfaces.sort_custom(
            SurfaceHorizontalPositionComparator,
            "sort")
    
    fall_range_polygon_without_jump_distance = FallMovementUtils \
            .calculate_jump_or_fall_range_polygon_from_surface(
                    graph.movement_params,
                    origin_surface,
                    false)
    fall_range_polygon_with_jump_distance = FallMovementUtils \
            .calculate_jump_or_fall_range_polygon_from_surface(
                    graph.movement_params,
                    origin_surface,
                    true)
    
    var surfaces_in_fall_range_result_set := {}
    var surfaces_in_jump_range_result_set := {}
    graph.get_surfaces_in_jump_and_fall_range(
            graph.collision_params,
            surfaces_in_fall_range_result_set,
            surfaces_in_jump_range_result_set,
            origin_surface)
    surfaces_in_fall_range = surfaces_in_fall_range_result_set.keys()
    surfaces_in_jump_range = surfaces_in_jump_range_result_set.keys()


func to_string() -> String:
    return "%s{ [%s, %s] }" % [
        InspectorItemType.get_string(TYPE),
        str(origin_surface.first_point),
        str(origin_surface.last_point),
    ]


func get_text() -> String:
    return "[%s, %s]" % [
        str(origin_surface.first_point),
        str(origin_surface.last_point),
    ]


func get_description() -> String:
    return ("There are %s valid outbound edges from this %s surface.") % [
        valid_edge_count,
        SurfaceSide.get_string(origin_surface.side),
    ]


func get_has_children() -> bool:
    return destination_surfaces_to_edge_types_to_edges_results.size() > 0


func on_item_selected() -> void:
    _populate_debug_only_state()
    .on_item_selected()


func on_item_expanded() -> void:
    _populate_debug_only_state()
    .on_item_expanded()


func _populate_debug_only_state() -> void:
    if is_debug_only_state_populated:
        return
    
    var inter_surface_edges_results := []
    graph._calculate_inter_surface_edges_for_origin(
            inter_surface_edges_results,
            origin_surface,
            surfaces_in_jump_range,
            graph.collision_params)
    
    destination_surfaces_to_edge_types_to_edges_results.clear()
    
    for inter_surface_edges_result in inter_surface_edges_results:
        var destination_surface: Surface = \
                inter_surface_edges_result.destination_surface
        var edge_type: int = inter_surface_edges_result.edge_type
        
        var edge_types_to_edges_results: Dictionary
        if !destination_surfaces_to_edge_types_to_edges_results.has(
                destination_surface):
            edge_types_to_edges_results = {}
            destination_surfaces_to_edge_types_to_edges_results \
                    [destination_surface] = \
                    edge_types_to_edges_results
        else:
            edge_types_to_edges_results = \
                    destination_surfaces_to_edge_types_to_edges_results \
                            [destination_surface]
        
        var edges_results: Array
        if !edge_types_to_edges_results.has(edge_type):
            edges_results = []
            edge_types_to_edges_results[edge_type] = edges_results
        else:
            edges_results = edge_types_to_edges_results[edge_type]
        
        edges_results.push_back(inter_surface_edges_result)
    
    is_debug_only_state_populated = true


func find_and_expand_controller(
        search_type: int,
        metadata: Dictionary) -> bool:
    match search_type:
        InspectorSearchType.ORIGIN_SURFACE:
            if metadata.origin_surface == origin_surface:
                expand()
                select()
                return true
            else:
                return false
        InspectorSearchType.DESTINATION_SURFACE, \
        InspectorSearchType.EDGE:
            if metadata.origin_surface == origin_surface:
                expand()
                _trigger_find_and_expand_controller_recursive(
                        search_type,
                        metadata)
                return true
            else:
                return false
        _:
            Sc.logger.error("OriginSurfaceItemController.find_and_expand_controller")
            return false


func _find_and_expand_controller_recursive(
        search_type: int,
        metadata: Dictionary) -> void:
    assert(search_type == InspectorSearchType.EDGE or \
            search_type == InspectorSearchType.DESTINATION_SURFACE)
    var child := tree_item.get_children()
    while child != null:
        var is_subtree_found: bool = \
                child.get_metadata(0).find_and_expand_controller(
                        search_type,
                        metadata)
        if is_subtree_found:
            return
        child = child.get_next()
    select()


func _create_children_inner() -> void:
    valid_edges_count_item_controller = DescriptionItemController.new(
            tree_item,
            tree,
            graph,
            "%s valid outbound edges" % valid_edge_count,
            get_description(),
            funcref(self,
                    "_get_annotation_elements_for_valid_edges_count_description_item"))
    fall_range_description_item_controller = DescriptionItemController.new(
            tree_item,
            tree,
            graph,
            "%s surfaces in fall range" % \
                    surfaces_in_fall_range.size(),
            "There are %s surfaces in fall range." % \
                    surfaces_in_fall_range.size(),
            funcref(self,
                    "_get_annotation_elements_for_fall_range_description_item"))
    jump_range_description_item_controller = DescriptionItemController.new(
            tree_item,
            tree,
            graph,
            "%s surfaces in jump range" % \
                    surfaces_in_jump_range.size(),
            "There are %s surfaces in jump range." % \
                    surfaces_in_jump_range.size(),
            funcref(self,
                    "_get_annotation_elements_for_jump_range_description_item"))
    
    var edge_types_to_edges_results: Dictionary
    for destination_surface in attempted_destination_surfaces:
        edge_types_to_edges_results = \
                destination_surfaces_to_edge_types_to_edges_results \
                        [destination_surface] if \
                destination_surfaces_to_edge_types_to_edges_results.has(
                        destination_surface) else \
                {}
        DestinationSurfaceItemController.new(
                tree_item,
                tree,
                graph,
                origin_surface,
                destination_surface,
                edge_types_to_edges_results)


func _destroy_children_inner() -> void:
    valid_edges_count_item_controller = null
    fall_range_description_item_controller = null
    jump_range_description_item_controller = null


func get_annotation_elements() -> Array:
    var elements := _get_jump_fall_range_annotation_elements(
            true,
            true)
    
    var valid_edges_annotation_elements := \
            _get_valid_edges_annotation_elements()
    Sc.utils.concat(elements, valid_edges_annotation_elements)
    
    var origin_element := OriginSurfaceAnnotationElement.new(origin_surface)
    elements.push_back(origin_element)
    
    return elements


func _get_annotation_elements_for_valid_edges_count_description_item() -> \
        Array:
    return _get_valid_edges_annotation_elements()


func _get_annotation_elements_for_destination_surfaces_description_item() -> \
        Array:
    var elements := get_annotation_elements()
    var element: SurfaceAnnotationElement
    for destination_surface in attempted_destination_surfaces:
        element = DestinationSurfaceAnnotationElement.new(destination_surface)
        elements.push_back(element)
    return elements


func _get_annotation_elements_for_fall_range_description_item() -> Array:
    var elements := _get_jump_fall_range_annotation_elements(
            true,
            false)
    var element: SurfaceAnnotationElement
    for destination_surface in surfaces_in_fall_range:
        if destination_surface != origin_surface:
            element = DestinationSurfaceAnnotationElement.new(
                    destination_surface)
        else:
            element = OriginSurfaceAnnotationElement.new(origin_surface)
        elements.push_back(element)
    return elements


func _get_annotation_elements_for_jump_range_description_item() -> Array:
    var elements := _get_jump_fall_range_annotation_elements(
            false,
            true)
    var element: SurfaceAnnotationElement
    for destination_surface in surfaces_in_jump_range:
        if destination_surface != origin_surface:
            element = DestinationSurfaceAnnotationElement.new(
                    destination_surface)
        else:
            element = OriginSurfaceAnnotationElement.new(origin_surface)
        elements.push_back(element)
    return elements


func _get_jump_fall_range_annotation_elements(
        includes_fall_range: bool,
        includes_jump_range: bool) -> Array:
    var elements := []
    
    if includes_fall_range:
        var fall_range_without_jump_distance_element := \
                FallRangeWithoutJumpDistanceAnnotationElement.new(
                        fall_range_polygon_without_jump_distance,
                        Sc.annotators.params \
                                .fall_range_polygon_color_config,
                        false,
                        false,
                        Sc.annotators.params \
                                .default_polyline_dash_length,
                        Sc.annotators.params.default_polyline_dash_gap,
                        4.0)
        elements.push_back(fall_range_without_jump_distance_element)
    
    if includes_jump_range:
        var fall_range_with_jump_distance_element := \
                FallRangeWithJumpDistanceAnnotationElement.new(
                        fall_range_polygon_with_jump_distance,
                        Sc.annotators.params \
                                .fall_range_polygon_color_config,
                        false,
                        false,
                        Sc.annotators.params \
                                .default_polyline_dash_length,
                        Sc.annotators.params.default_polyline_dash_gap,
                        1.0)
        elements.push_back(fall_range_with_jump_distance_element)
    
    return elements


func _get_valid_edges_annotation_elements() -> Array:
    var elements := []
    var element: EdgeAnnotationElement
    var edge: Edge
    for destination_surface in \
            destination_surfaces_to_edge_types_to_edges_results:
        for edge_type in destination_surfaces_to_edge_types_to_edges_results \
                [destination_surface]:
            for edges_result in \
                    destination_surfaces_to_edge_types_to_edges_results \
                            [destination_surface][edge_type]:
                for valid_edge in edges_result.valid_edges:
                    element = EdgeAnnotationElement.new(
                            valid_edge,
                            true,
                            false,
                            true,
                            false)
                    elements.push_back(element)
    return elements


class SurfaceHorizontalPositionComparator:
    static func sort(
            a: Surface,
            b: Surface) -> bool:
        return a.bounding_box.position.x < b.bounding_box.position.x if \
                a.bounding_box.position.x != b.bounding_box.position.x else \
                a.bounding_box.end.x != b.bounding_box.end.x
