extends "res://addons/gut/test.gd"

const TestBed := preload("res://framework/test/test_data/test_bed.gd")

var test_bed: TestBed
var surface: Surface

func before_each() -> void:
    test_bed = TestBed.new(self)

func set_up(data: Dictionary) -> void:
    test_bed.set_up_level(data)
    
    surface = data.start.surface
    
    test_bed.global_calc_params.destination_surface = data.end.surface

func test_TODO():
    var data := test_bed.TEST_LEVEL_LONG_FALL
    set_up(data)
    test_bed.global_calc_params.position_start = data.start.positions.near
    test_bed.global_calc_params.position_end = data.end.positions.near
    
    var instructions := test_bed.jump_from_platform_movement._calculate_jump_instructions( \
            test_bed.global_calc_params)
    assert_not_null(instructions)
    # FIXME
#    assert_true(instructions)

# FIXME: LEFT OFF HERE: -------------A ********
# - Enumerate all of the different things to test for edge calculations
# - Implement a few, and validate my current helper data utility setup

# FIXME: Things to test:
# - 
