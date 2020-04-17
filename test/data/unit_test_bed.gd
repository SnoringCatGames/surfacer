extends "res://addons/gut/test.gd"
class_name UnitTestBed

const END_COORDINATE_CLOSE_THRESHOLD := 0.001
const END_POSITION_CLOSE_THRESHOLD := Vector2(0.001, 0.001)

var sandbox: Node

var movement_params: MovementParams

func before_each() -> void:
    sandbox = self

func after_each() -> void:
    destroy()

func set_up(data = null) -> void:
    var global = $"/root/Global"
    movement_params = \
            data.movement_params if \
            data != null and data.has('movement_params') else \
            PlayerParamsUtils.create_player_params(TestPlayerParams, global).movement_params

func destroy() -> void:
    # FIXME: This shouldn't be possible. Why does Gut trigger this sometimes?
    if sandbox == null:
        return
    
    movement_params = null
