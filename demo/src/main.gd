class_name DemoMain
extends Node


@export var manifest: ScaffolderManifest


func _ready() -> void:
    # FIXME: LEFT OFF HERE: Implement manifests. ------------------------------
    var manifests: TypedArray[ScaffolderManifest] = []
    
    SnoreCore.connect("set_up_finished", self, "_on_snore_core_set_up_finished")
    SnoreCore.set_up(manifests)

    G.main = self

    S.set_up(manifest)

    # TODO: REMOVE
    var foo := Surface.new()
    var side: Surface.Side
    Surface.get_normal_from_side(side)
    foo.get_last_point()
    Geometry.are_colors_equal_with_epsilon(Color.WHITE, Color.BLACK, 0.0001)
    S.log.print(foo.to_string(false))

    SnoreCore.run_tests()


func _on_snore_core_set_up_finished() -> void:
    S.log.print("SnoreCore set up finished.")


func _on_gd_example_position_changed(node: Object, new_pos: Vector2) -> void:
    print("The position of " + node.get_class() + " is now " + str(new_pos))
