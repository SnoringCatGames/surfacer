class_name ClickAnnotator
extends TransientAnnotator


const CLICK_INNER_END_RADIUS := 58.0
const CLICK_OUTER_END_RADIUS := 100.0

var CLICK_INNER_COLOR: Color = Sc.colors.click
var CLICK_OUTER_COLOR: Color = Sc.colors.click
var VALID_SURFACE_COLOR: Color = Sc.colors.surface_click_selection
var INVALID_SURFACE_COLOR: Color = Sc.colors.opacify(
        Sc.colors.invalid, ScaffolderColors.ALPHA_SOLID)

const CLICK_INNER_DURATION := 0.27
const CLICK_OUTER_DURATION := 0.23
const SURFACE_DURATION := 0.4

var click_position: Vector2
var selected_surface: Surface
var is_surface_navigatable: bool

var inner_progress: float
var outer_progress: float
var surface_progress: float


func _init(
        click_position: Vector2,
        selected_surface: Surface,
        is_surface_navigatable: bool
        ).(
        max(max(
                CLICK_INNER_DURATION,
                CLICK_OUTER_DURATION),
                SURFACE_DURATION)
        ) -> void:
    self.click_position = click_position
    self.selected_surface = selected_surface
    self.is_surface_navigatable = is_surface_navigatable
    _update()


func _update() -> void:
    ._update()
    
    inner_progress = (current_time - start_time) / CLICK_INNER_DURATION
    inner_progress = Sc.utils.ease_by_name(inner_progress, "ease_out")
    
    outer_progress = (current_time - start_time) / CLICK_OUTER_DURATION
    outer_progress = Sc.utils.ease_by_name(outer_progress, "ease_out")
    
    surface_progress = (current_time - start_time) / SURFACE_DURATION
    surface_progress = Sc.utils.ease_by_name(surface_progress, "ease_out")


func _draw() -> void:
    var is_inner_animation_complete := inner_progress >= 1.0
    var is_outer_animation_complete := outer_progress >= 1.0
    var is_surface_animation_complete := surface_progress >= 1.0
    
    if !is_surface_animation_complete and \
            selected_surface != null:
        var color := \
                VALID_SURFACE_COLOR if \
                is_surface_navigatable else \
                VALID_SURFACE_COLOR
        var alpha := color.a * (1 - surface_progress)
        color.a = alpha
        
        Sc.draw.draw_surface(
                self,
                selected_surface,
                color)
    
    if !is_inner_animation_complete:
        var alpha := CLICK_INNER_COLOR.a * (1 - inner_progress)
        var color := Color(
                CLICK_INNER_COLOR.r,
                CLICK_INNER_COLOR.g,
                CLICK_INNER_COLOR.b,
                alpha)
        var radius := CLICK_INNER_END_RADIUS * inner_progress
        
        draw_circle(
                click_position,
                radius,
                color)
    
    if !is_outer_animation_complete:
        var alpha := CLICK_OUTER_COLOR.a * (1 - outer_progress)
        var color := Color(
                CLICK_OUTER_COLOR.r,
                CLICK_OUTER_COLOR.g,
                CLICK_OUTER_COLOR.b,
                alpha)
        var radius := CLICK_OUTER_END_RADIUS * outer_progress
        
        draw_circle(
                click_position,
                radius,
                color)
