class_name DemoMain
extends Node


# FIXME: LEFT OFF HERE: Implement manifests. ------------------------------
@export var manifests: Array[SnoreCoreSettings] = []

@export var run_tests := true


func _ready() -> void:
    G.snore_core = SnoreCore.get_module("SnoreCore");
    G.scaffolder = SnoreCore.get_module("Scaffolder");
    G.surfacer = SnoreCore.get_module("Surfacer");
    G.snore_core.connect("all_modules_set_up_finished", _on_snore_core_set_up_finished)
    SnoreCore.set_up(manifests)

    if run_tests:
        SnoreCore.run_tests()

    # TODO: REMOVE
    var foo := Surface.new()
    var side: Surface.Side
    Surface.get_normal_from_side(side)
    foo.get_last_point()
    Geometry.are_colors_equal_with_epsilon(Color.WHITE, Color.BLACK, 0.0001)
    S.log.print(foo.to_string(false))


func _on_snore_core_set_up_finished() -> void:
    S.log.print("SnoreCore set up finished.")


func _on_gd_example_position_changed(node: Object, new_pos: Vector2) -> void:
    print("The position of " + node.get_class() + " is now " + str(new_pos))
