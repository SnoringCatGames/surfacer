class_name DemoMain
extends Node


# FIXME: LEFT OFF HERE: Implement manifests. ------------------------------
@export var snore_core_settings: SnoreCoreMainSettings
@export var scaffolder_settings: ScaffolderSettings
@export var surfacer_settings: SurfacerSettings

@export var run_tests := true


func _ready() -> void:
    G.snore_core = SnoreCore.get_module("SnoreCore")
    G.scaffolder = SnoreCore.get_module("Scaffolder")
    G.surfacer = SnoreCore.get_module("Surfacer")

    G.snore_core.connect("all_modules_set_up_finished", _on_snore_core_set_up_finished)
    SnoreCore.set_up([snore_core_settings, scaffolder_settings, surfacer_settings])

    if run_tests:
        var tests_passed = SnoreCore.run_tests()

    # TODO: REMOVE
    var foo := Surface.new()
    var side: Surface.Side
    Surface.get_normal_from_side(side)
    foo.get_last_point()
    Geometry.are_colors_equal_with_epsilon(Color.WHITE, Color.BLACK, 0.0001)
    S.log.print(foo.to_string(false))


func _on_snore_core_set_up_finished() -> void:
    G.snore_core_settings = G.snore_core.get_settings()
    G.scaffolder_settings = G.scaffolder.get_settings()
    G.surfacer_settings = G.surfacer.get_settings()

    S.set_up(G.scaffolder_settings)


func _on_gd_example_position_changed(node: Object, new_pos: Vector2) -> void:
    print("The position of " + node.get_class() + " is now " + str(new_pos))
