class_name WitchWorldVisual
extends Node2D

const PURPLE := Color("4d2b78")
const PURPLE_DEEP := Color("21162f")
const VIOLET := Color("9a61ff")
const GOLD := Color("dcb56f")
const SILVER := Color("d9d7e9")
const SILVER_SHADOW := Color("9693b4")
const SKIN := Color("f2c5b6")
const DARK := Color("0f0d1e")
const WHITE_GLOW := Color("eeeaff")

var facing := Vector2.DOWN
var walk_time := 0.0
var moving := false

func _ready() -> void:
    z_index = 20
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    set_process(true)
    queue_redraw()

func _process(delta: float) -> void:
    var actor := get_parent() as CharacterBody2D
    if actor == null:
        return

    moving = actor.velocity.length_squared() > 4.0
    if moving:
        facing = actor.velocity.normalized()
        walk_time += delta * 8.0
    else:
        walk_time += delta * 2.0
    queue_redraw()

func _draw() -> void:
    var bob := sin(walk_time) * (1.6 if moving else 0.55)
    var step := sin(walk_time) * 2.2 if moving else 0.0
    var horizontal := signf(facing.x)
    if absf(horizontal) < 0.1:
        horizontal = 1.0
    var looking_up := facing.y < -0.35
    var side_view := absf(facing.x) > 0.55

    # Ground shadow.
    draw_ellipse(Vector2(0, 17), Vector2(17, 6), Color(0, 0, 0, 0.32))

    # Flowing cloak silhouette, deliberately large enough to read on phone screens.
    var cloak := PackedVector2Array([
        Vector2(-14, -3 + bob),
        Vector2(-18, 11 + bob),
        Vector2(-11, 22 + bob),
        Vector2(0, 17 + bob),
        Vector2(11, 22 + bob),
        Vector2(18, 11 + bob),
        Vector2(14, -3 + bob),
    ])
    draw_colored_polygon(cloak, PURPLE_DEEP)
    draw_polyline(PackedVector2Array([Vector2(-14, -3 + bob), Vector2(-18, 11 + bob), Vector2(-11, 22 + bob)]), GOLD, 1.5, true)
    draw_polyline(PackedVector2Array([Vector2(14, -3 + bob), Vector2(18, 11 + bob), Vector2(11, 22 + bob)]), GOLD, 1.5, true)

    # Legs / boots.
    draw_line(Vector2(-5, 13 + bob), Vector2(-6 - step * 0.35, 21 + bob), DARK, 5.0)
    draw_line(Vector2(5, 13 + bob), Vector2(6 + step * 0.35, 21 + bob), DARK, 5.0)
    draw_line(Vector2(-7 - step * 0.35, 21 + bob), Vector2(-2 - step * 0.35, 21 + bob), GOLD, 1.4)
    draw_line(Vector2(3 + step * 0.35, 21 + bob), Vector2(8 + step * 0.35, 21 + bob), GOLD, 1.4)

    # Torso.
    draw_rect(Rect2(-9, -7 + bob, 18, 22), PURPLE, true)
    draw_line(Vector2(0, -6 + bob), Vector2(0, 13 + bob), GOLD, 2.0)
    draw_line(Vector2(-8, 12 + bob), Vector2(8, 12 + bob), GOLD, 1.4)

    # Silver hair. Back view uses a broader sheet, front view has side locks.
    if looking_up:
        draw_colored_polygon(PackedVector2Array([
            Vector2(-11, -16 + bob), Vector2(11, -16 + bob), Vector2(15, 7 + bob),
            Vector2(7, 15 + bob), Vector2(0, 10 + bob), Vector2(-7, 15 + bob), Vector2(-15, 7 + bob)
        ]), SILVER)
        draw_line(Vector2(-7, -10 + bob), Vector2(-11, 10 + bob), SILVER_SHADOW, 2.0)
        draw_line(Vector2(7, -10 + bob), Vector2(11, 10 + bob), SILVER_SHADOW, 2.0)
    else:
        draw_circle(Vector2(0, -14 + bob), 10.5, SILVER)
        draw_line(Vector2(-7, -10 + bob), Vector2(-13, 10 + bob), SILVER, 5.0)
        draw_line(Vector2(7, -10 + bob), Vector2(13, 10 + bob), SILVER, 5.0)
        draw_line(Vector2(-8, -8 + bob), Vector2(-12, 14 + bob), SILVER_SHADOW, 1.5)
        draw_line(Vector2(8, -8 + bob), Vector2(12, 14 + bob), SILVER_SHADOW, 1.5)
        draw_circle(Vector2(horizontal * 1.0, -13 + bob), 7.2, SKIN)
        if side_view:
            draw_circle(Vector2(horizontal * 3.0, -14 + bob), 1.2, VIOLET)
        else:
            draw_circle(Vector2(-3, -14 + bob), 1.1, VIOLET)
            draw_circle(Vector2(3, -14 + bob), 1.1, VIOLET)

    # Wide witch hat, consistent with the approved Lumina direction.
    var hat_y := -23 + bob
    draw_colored_polygon(PackedVector2Array([
        Vector2(-10, hat_y), Vector2(-3, hat_y - 18), Vector2(5, hat_y - 10), Vector2(9, hat_y)
    ]), PURPLE_DEEP)
    draw_line(Vector2(-4, hat_y - 1), Vector2(6, hat_y - 1), GOLD, 2.0)
    draw_line(Vector2(-19, hat_y), Vector2(20, hat_y), PURPLE_DEEP, 8.0)
    draw_line(Vector2(-18, hat_y - 1), Vector2(19, hat_y - 1), Color("6f3ca4"), 2.0)
    draw_circle(Vector2(7, hat_y - 2), 2.5, GOLD)
    draw_circle(Vector2(7, hat_y - 2), 1.2, VIOLET)

    # Staff is kept on the screen-readable outside edge of the silhouette.
    var staff_x := 18.0 * horizontal
    var staff_top := Vector2(staff_x, -19 + bob)
    var staff_bottom := Vector2(staff_x - horizontal * 2.0, 21 + bob)
    draw_line(staff_top, staff_bottom, Color("8a5b45"), 3.0)
    draw_arc(staff_top, 7.5, 0.0, TAU, 24, GOLD, 2.0, true)
    draw_circle(staff_top, 5.0, Color(VIOLET, 0.22))
    draw_circle(staff_top, 3.2, VIOLET)
    draw_line(staff_top + Vector2(-4, 0), staff_top + Vector2(4, 0), WHITE_GLOW, 1.3)
    draw_line(staff_top + Vector2(0, -4), staff_top + Vector2(0, 4), WHITE_GLOW, 1.3)

func draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for index in range(24):
        var angle := TAU * float(index) / 24.0
        points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
    draw_colored_polygon(points, color)
