extends TestBed
    
var surface: Surface
var offset: Vector2

func set_up(state := {}) -> void:
    surface = Surface.new([state.surface_start, state.surface_end], state.side, [INF])
    offset = Vector2(10, 10)

func assert_constraint(constraint: MovementConstraint, state: Dictionary) -> void:
    assert_eq(constraint.passing_point, state.passing_point)
    assert_eq(constraint.passing_vertically, state.passing_vertically)
    assert_eq(constraint.should_stay_on_min_side, state.should_stay_on_min_side)

func test_floor_surface() -> void:
    set_up({
        side = SurfaceSide.FLOOR,
        surface_start = Vector2(100, 0),
        surface_end = Vector2(200, 0),
    })
    
    var constraints := PlayerMovement._calculate_constraints(surface, offset)
    
    assert_constraint(constraints[0], {
        passing_point = Vector2(90, -10),
        passing_vertically = true,
        should_stay_on_min_side = true,
    })
    assert_constraint(constraints[1], {
        passing_point = Vector2(210, -10),
        passing_vertically = true,
        should_stay_on_min_side = false,
    })

func test_ceiling_surface() -> void:
    set_up({
        side = SurfaceSide.CEILING,
        surface_start = Vector2(200, 0),
        surface_end = Vector2(100, 0),
    })
    
    var constraints := PlayerMovement._calculate_constraints(surface, offset)
    
    assert_constraint(constraints[0], {
        passing_point = Vector2(90, 10),
        passing_vertically = true,
        should_stay_on_min_side = true,
    })
    assert_constraint(constraints[1], {
        passing_point = Vector2(210, 10),
        passing_vertically = true,
        should_stay_on_min_side = false,
    })

func test_left_wall_surface() -> void:
    set_up({
        side = SurfaceSide.LEFT_WALL,
        surface_start = Vector2(0, 100),
        surface_end = Vector2(0, 200),
    })
    
    var constraints := PlayerMovement._calculate_constraints(surface, offset)
    
    assert_constraint(constraints[0], {
        passing_point = Vector2(10, 90),
        passing_vertically = false,
        should_stay_on_min_side = true,
    })
    assert_constraint(constraints[1], {
        passing_point = Vector2(10, 210),
        passing_vertically = false,
        should_stay_on_min_side = false,
    })

func test_right_wall_surface() -> void:
    set_up({
        side = SurfaceSide.RIGHT_WALL,
        surface_start = Vector2(0, 200),
        surface_end = Vector2(0, 100),
    })
    
    var constraints := PlayerMovement._calculate_constraints(surface, offset)
    
    assert_constraint(constraints[0], {
        passing_point = Vector2(-10, 90),
        passing_vertically = false,
        should_stay_on_min_side = true,
    })
    assert_constraint(constraints[1], {
        passing_point = Vector2(-10, 210),
        passing_vertically = false,
        should_stay_on_min_side = false,
    })
