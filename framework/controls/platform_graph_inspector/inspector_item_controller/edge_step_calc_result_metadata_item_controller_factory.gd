# This class is a necessary hack to work-around an unfortunate limitation in GDScript where a class
# cannot reference itself. Ideally, this factory would just be a static function within
# EdgeStepCalcResultMetadataItemController.
class_name EdgeStepCalcResultMetadataItemControllerFactory

static func create( \
        tree_item: TreeItem, \
        tree: Tree, \
        graph: PlatformGraph, \
        edge_or_edge_attempt, \
        step_result_metadata: EdgeStepCalcResultMetadata, \
        step_item_factory \
        ) -> EdgeStepCalcResultMetadataItemController:
    return EdgeStepCalcResultMetadataItemController.new( \
            tree_item, \
            tree, \
            graph, \
            edge_or_edge_attempt, \
            step_result_metadata, \
            step_item_factory)
