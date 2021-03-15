extends Node2D
class_name ElementAnnotator

# Dictionary<AnnotationElement, AnnotationElement>
var _elements_set := {}

var legend: Legend

func _ready() -> void:
    legend = $"/root/Global".legend

func add(element: AnnotationElement) -> void:
    _elements_set[element] = element
    update()

func add_all(elements: Array) -> void:
    for element in elements:
        add(element)

func clear() -> void:
    for element in _elements_set:
        element.clear()
    _elements_set.clear()
    update()

func erase(element: AnnotationElement) -> bool:
    element.clear()
    update()
    return _elements_set.erase(element)

func erase_all(elements: Array) -> void:
    for element in elements:
        erase(element)

func has(element: AnnotationElement) -> bool:
    return _elements_set.has(element)

func _draw() -> void:
    # Dictionary<int, LegendItem>
    var legend_items := {}
    
    for element in _elements_set:
        element.draw(self)
        for legend_item in element.get_legend_items():
            legend_items[legend_item.type] = legend_item
    
    legend.clear()
    for legend_item_type in legend_items:
        legend.add(legend_items[legend_item_type])
