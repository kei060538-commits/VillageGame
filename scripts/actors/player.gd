class_name WitchPlayer
extends CharacterBody2D

const SPEED := 170.0

func _ready() -> void:
    queue_redraw()

func _physics_process(_delta: float) -> void:
    var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

    var keyboard_vector := Vector2.ZERO
    if Input.is_key_pressed(KEY_A):
        keyboard_vector.x -= 1.0
    if Input.is_key_pressed(KEY_D):
        keyboard_vector.x += 1.0
    if Input.is_key_pressed(KEY_W):
        keyboard_vector.y -= 1.0
    if Input.is_key_pressed(KEY_S):
        keyboard_vector.y += 1.0

    if keyboard_vector.length_squared() > 0.0:
        input_vector = keyboard_vector.normalized()

    velocity = input_vector * SPEED
    move_and_slide()

    position.x = clampf(position.x, 24.0, 1576.0)
    position.y = clampf(position.y, 24.0, 876.0)

func _draw() -> void:
    # Placeholder witch sprite. Final build will use pixel art.
    draw_circle(Vector2(0, 3), 11.0, Color("9f72d8"))
    draw_polygon(
        PackedVector2Array([Vector2(-15, -7), Vector2(15, -7), Vector2(0, -31)]),
        PackedColorArray([Color("493167")])
    )
    draw_line(Vector2(-13, -10), Vector2(13, -10), Color("d2a7ff"), 3.0)
    draw_circle(Vector2(-4, 1), 1.5, Color.WHITE)
    draw_circle(Vector2(4, 1), 1.5, Color.WHITE)
