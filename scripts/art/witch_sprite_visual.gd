class_name WitchSpriteVisual
extends Sprite2D

const FRAME_COLUMNS := 3
const DIRECTION_ROWS := 8
const WALK_FRAME_TIME := 0.16

var facing_row := 0
var walk_timer := 0.0
var walk_frame := 1

func _ready() -> void:
    texture = WitchArtData.get_texture()
    hframes = FRAME_COLUMNS
    vframes = DIRECTION_ROWS
    frame_coords = Vector2i(0, facing_row)
    centered = true
    position = Vector2(0, -23)
    scale = Vector2(3.35, 3.35)
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    z_index = 22
    set_process(true)

func _process(delta: float) -> void:
    var actor := get_parent() as CharacterBody2D
    if actor == null or texture == null:
        return

    var movement := actor.velocity
    if movement.length_squared() > 4.0:
        facing_row = _direction_row(movement.normalized())
        walk_timer += delta
        if walk_timer >= WALK_FRAME_TIME:
            walk_timer = 0.0
            walk_frame = 2 if walk_frame == 1 else 1
        frame_coords = Vector2i(walk_frame, facing_row)
    else:
        walk_timer = 0.0
        walk_frame = 1
        frame_coords = Vector2i(0, facing_row)

func _direction_row(direction: Vector2) -> int:
    var angle := atan2(direction.y, direction.x)
    var octant := int(round(angle / (PI / 4.0)))
    match octant:
        2: return 0 # down / front
        1: return 1 # down-right
        0: return 2 # right
        -1: return 3 # up-right
        -2: return 4 # up / back
        -3: return 5 # up-left
        4, -4: return 6 # left
        3: return 7 # down-left
        _: return facing_row
