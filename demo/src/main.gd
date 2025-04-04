class_name DemoMain
extends Node


@export var manifest: ScaffolderManifest


func _ready() -> void:
    G.main = self

    S.set_up(manifest)
    # TODO: REMOVE
    var foo: Surface
    var side: Surface.Side
    Surface.get_normal_from_side(side)
    foo.get_last_point()


func _on_gd_example_position_changed(node: Object, new_pos: Vector2) -> void:
    print("The position of " + node.get_class() + " is now " + str(new_pos))
