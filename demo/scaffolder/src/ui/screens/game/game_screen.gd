class_name ScaffolderGameScreen
extends ScaffolderScreen


var sub_viewport: SubViewport


func _enter_tree() -> void:
    S.game_screen = self


func _ready() -> void:
    super()

    sub_viewport = %SubViewport

    await get_tree().process_frame

    # TODO: Configure different levels?
    var level_scene = (
        S.manifest.dev_mode_level
        if S.manifest.dev_mode
        else S.manifest.main_level
    )
    start(level_scene)


func start(level_scene: PackedScene) -> void:
    var level_node: ScaffolderLevel = level_scene.instantiate()
    %SubViewport.add_child(level_node)
    level_node.start()


func on_level_ended() -> void:
    S.screens.open("game_over")
    S.screens.close(self)
