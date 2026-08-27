class_name WitchPlayer
extends CharacterBody2D

const SPEED := 170.0
const SPRITE_PATH := "res://art/player/witch_8dir_atlas.png"
const FRAME_COLUMNS := 3
const DIRECTION_ROWS := 8
const WALK_FRAME_TIME := 0.16

var touch_direction := Vector2.ZERO
var witch_sprite: Sprite2D
var facing_row := 4
var walk_timer := 0.0
var walk_frame := 1

func _ready() -> void:
    position = VillageSimulation.VISIT_SPAWN_POSITION
    _build_sprite()
    queue_redraw()

func _build_sprite() -> void:
    if not ResourceLoader.exists(SPRITE_PATH):
        return

    witch_sprite = Sprite2D.new()
    witch_sprite.name = "WitchSprite"
    witch_sprite.texture = load(SPRITE_PATH)
    witch_sprite.hframes = FRAME_COLUMNS
    witch_sprite.vframes = DIRECTION_ROWS
    witch_sprite.frame_coords = Vector2i(0, facing_row)
    witch_sprite.position = Vector2(0, -35)
    witch_sprite.scale = Vector2(1.35, 1.35)
    witch_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    witch_sprite.z_index = 4
    add_child(witch_sprite)

func set_touch_direction(direction: Vector2) -> void:
    touch_direction = direction.normalized() if direction.length_squared() > 0.0 else Vector2.ZERO

func _physics_process(delta: float) -> void:
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
    elif touch_direction.length_squared() > 0.0:
        input_vector = touch_direction

    velocity = input_vector * SPEED
    move_and_slide()

    position.x = clampf(position.x, 28.0, VillageSimulation.WORLD_SIZE.x - 28.0)
    position.y = clampf(position.y, 40.0, VillageSimulation.WORLD_SIZE.y - 28.0)
    _update_sprite(delta, input_vector)

func _update_sprite(delta: float, movement: Vector2) -> void:
    if witch_sprite == null:
        queue_redraw()
        return

    if movement.length_squared() > 0.01:
        facing_row = _direction_row(movement)
        walk_timer += delta
        if walk_timer >= WALK_FRAME_TIME:
            walk_timer = 0.0
            walk_frame = 2 if walk_frame == 1 else 1
        witch_sprite.frame_coords = Vector2i(walk_frame, facing_row)
    else:
        walk_timer = 0.0
        walk_frame = 1
        witch_sprite.frame_coords = Vector2i(0, facing_row)

func _direction_row(direction: Vector2) -> int:
    var angle := atan2(direction.y, direction.x)
    var octant := int(round(angle / (PI / 4.0)))
    match octant:
        -2: return 0 # up
        -1: return 1 # up-right
        0: return 2 # right
        1: return 3 # down-right
        2: return 4 # down
        3: return 5 # down-left
        4, -4: return 6 # left
        -3: return 7 # up-left
        _: return facing_row

func _draw() -> void:
    if witch_sprite != null:
        return

    # Fallback if the production sprite asset cannot be loaded.
    draw_circle(Vector2(0, 3), 11.0, Color("9f72d8"))
    draw_colored_polygon(
        PackedVector2Array([Vector2(-15, -7), Vector2(15, -7), Vector2(0, -31)]),
        Color("493167")
    )
    draw_line(Vector2(-13, -10), Vector2(13, -10), Color("d2a7ff"), 3.0)
    draw_circle(Vector2(-4, 1), 1.5, Color.WHITE)
    draw_circle(Vector2(4, 1), 1.5, Color.WHITE)
