extends Reference
class_name TestBed

const JumpFromPlatformMovement = preload("res://framework/player_movement/jump_from_platform_movement.gd")
const TestPlayerParams = preload("res://framework/test/test_data/test_player_params.gd")

var TEST_LEVEL_LONG_FALL := {
    scene_resource_path = "res://framework/test/test_data/test_level_long_fall.tscn",
    start = {
        surface = Surface.new([Vector2(128, 64), Vector2(192, 64)], SurfaceSide.FLOOR),
        # These are the Player's center positions when jumping/landing on this part of the Surface.
        positions = {
            near = Vector2(192, 54),
            far = Vector2(128, 54),
        }
    },
    end = {
        surface = Surface.new([Vector2(256, 832), Vector2(320, 832)], SurfaceSide.FLOOR),
        # These are the Player's center positions when jumping/landing on this part of the Surface.
        positions = {
            near = Vector2(256, 822),
            far = Vector2(320, 822),
        }
    },
}

const GROUPS := [
    "surfaces",
    "human_players",
    "computer_players",
]

var sandbox: Node

var test_player_params: TestPlayerParams
var jump_from_platform_movement: JumpFromPlatformMovement
var level: Level
var space_state: Physics2DDirectSpaceState
var global_calc_params: MovementCalcGlobalParams

func _init(sandbox: Node) -> void:
    self.sandbox = sandbox

func destroy() -> void:
    var scene_tree := sandbox.get_tree()
    
    for group in GROUPS:
        for node in scene_tree.get_nodes_in_group(group):
            node.remove_from_group(group)
    
    for node in sandbox.get_children():
        node.queue_free()

func set_up_level(data: Dictionary) -> void:
    test_player_params = TestPlayerParams.new()
    jump_from_platform_movement = \
            JumpFromPlatformMovement.new(test_player_params._movement_params)
    jump_from_platform_movement.surfaces = [data.start.surface, data.end.surface]
    
    var level_scene := load(data.scene_resource_path)
    level = level_scene.instance()
    sandbox.add_child(level)
    
    space_state = level.get_world_2d().direct_space_state
    global_calc_params = \
            MovementCalcGlobalParams.new(jump_from_platform_movement.params, space_state)
