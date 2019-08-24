extends "res://addons/gut/test.gd"
class_name TestBed

const JumpFromPlatformMovement := preload("res://framework/movement/models/jump_from_platform_movement.gd")
const TestPlayerParams := preload("res://framework/test/test_data/test_player_params.gd")

var TEST_LEVEL_LONG_FALL := {
    scene_resource_path = "res://framework/test/test_data/test_level_long_fall.tscn",
    start = {
        surface = Surface.new([Vector2(128, 64), Vector2(192, 64)], SurfaceSide.FLOOR, [0]),
        # These are the Player's center positions when jumping/landing on this part of the Surface.
        positions = {
            near = Vector2(192, 54),
            far = Vector2(128, 54),
        }
    },
    end = {
        surface = Surface.new([Vector2(256, 832), Vector2(320, 832)], SurfaceSide.FLOOR, [38]),
        # These are the Player's center positions when jumping/landing on this part of the Surface.
        positions = {
            near = Vector2(256, 822),
            far = Vector2(320, 822),
        }
    },
}

var TEST_LEVEL_LONG_RISE := {
    scene_resource_path = "res://framework/test/test_data/test_level_long_rise.tscn",
    start = {
        surface = Surface.new([Vector2(128, 64), Vector2(192, 64)], SurfaceSide.FLOOR, [44]),
        # These are the Player's center positions when jumping/landing on this part of the Surface.
        positions = {
            near = Vector2(128, 54),
            far = Vector2(192, 54),
        }
    },
    end = {
        surface = Surface.new([Vector2(-128, -448), Vector2(-64, -448)], SurfaceSide.FLOOR, [0]),
        # These are the Player's center positions when jumping/landing on this part of the Surface.
        positions = {
            near = Vector2(-64, -458),
            far = Vector2(-128, -458),
        }
    },
}

var TEST_LEVEL_FAR_DISTANCE := {
    scene_resource_path = "res://framework/test/test_data/test_level_far_distance.tscn",
    start = {
        surface = Surface.new([Vector2(128, 64), Vector2(192, 64)], SurfaceSide.FLOOR, [0]),
        # These are the Player's center positions when jumping/landing on this part of the Surface.
        positions = {
            near = Vector2(192, 54),
            far = Vector2(128, 54),
        }
    },
    end = {
        surface = Surface.new([Vector2(704, 64), Vector2(768, 64)], SurfaceSide.FLOOR, [9]),
        # These are the Player's center positions when jumping/landing on this part of the Surface.
        positions = {
            near = Vector2(704, 54),
            far = Vector2(768, 54),
        }
    },
}

const GROUPS := [
    Utils.GROUP_NAME_HUMAN_PLAYERS,
    Utils.GROUP_NAME_COMPUTER_PLAYERS,
    Utils.GROUP_NAME_SURFACES,
]

const END_COORDINATE_CLOSE_THRESHOLD := 0.001
const END_POSITION_CLOSE_THRESHOLD := Vector2(0.001, 0.001)

var sandbox: Node

var movement_params: MovementParams
var jump_from_platform_movement: JumpFromPlatformMovement
var level: Level
var test_player: TestPlayer
var surface_parser: SurfaceParser
var space_state: Physics2DDirectSpaceState
var global_calc_params: MovementCalcGlobalParams
var start_surface: Surface
var end_surface: Surface

func before_each() -> void:
    sandbox = self

func after_each() -> void:
    destroy()

func set_up(data := TEST_LEVEL_LONG_FALL) -> void:
    set_up_level(data)

func destroy() -> void:
    # FIXME: This shouldn't be possible. Why does Gut trigger this sometimes?
    if sandbox == null:
        return
    
    var scene_tree := sandbox.get_tree()
    
    for group in GROUPS:
        for node in scene_tree.get_nodes_in_group(group):
            node.remove_from_group(group)
            node.queue_free()
    
    for node in sandbox.get_children():
        sandbox.remove_child(node)
        node.queue_free()
    
    movement_params = null
    jump_from_platform_movement = null
    level = null
    test_player = null
    surface_parser = null
    space_state = null
    global_calc_params = null
    start_surface = null
    end_surface = null

func set_up_level(data: Dictionary) -> void:
    var level_scene := load(data.scene_resource_path)
    level = level_scene.instance()
    sandbox.add_child(level)
    
    test_player = level.human_player
    movement_params = test_player.movement_params
    for movement_type in test_player.movement_types:
        if movement_type is JumpFromPlatformMovement:
            jump_from_platform_movement = movement_type
    assert(jump_from_platform_movement != null)
    
    surface_parser = level.surface_parser
    space_state = level.get_world_2d().direct_space_state
    global_calc_params = MovementCalcGlobalParams.new( \
            movement_params, space_state, surface_parser)
    
    _store_surfaces(data)

func _store_surfaces(data: Dictionary) -> void:
    for surface in surface_parser.all_surfaces:
        if surface.side == data.start.surface.side and \
                surface.vertices[0] == data.start.surface.vertices[0] and \
                surface.vertices[1] == data.start.surface.vertices[1]:
            start_surface = surface
        elif surface.side == data.end.surface.side and \
                surface.vertices[0] == data.end.surface.vertices[0] and \
                surface.vertices[1] == data.end.surface.vertices[1]:
            end_surface = surface
    
    assert(start_surface != null)
    assert(end_surface != null)
    
    jump_from_platform_movement.surfaces = [start_surface, end_surface]
    global_calc_params.destination_surface = end_surface
