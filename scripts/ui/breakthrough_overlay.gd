extends Control

signal finished

const WHITE_GLOW := Color("f6f1ff")
const GOLD := Color("e2bb72")

var center := Vector2.ZERO
var segments: Array[Vector2] = []
var field_color := Color("9a61ff")
var elapsed := 0.0
var duration := 1.05

func setup(screen_center: Vector2, link_segments: Array[Vector2], color: Color) -> void:
    center = screen_center
    segments = link_segments.duplicate()
    field_color = color

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    set_process(true)
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    queue_redraw()
    if elapsed >= duration:
        finished.emit()
        queue_free()

func _draw() -> void:
    if size.x <= 0.0 or size.y <= 0.0:
        return

    var t: float = clampf(elapsed / duration, 0.0, 1.0)
    var intro: float = minf(1.0, t / 0.16)
    var fade: float = 1.0 - smoothstep(0.54, 1.0, t)
    var flash: float = (1.0 - t) * (1.0 - t)

    draw_rect(Rect2(Vector2.ZERO, size), Color(WHITE_GLOW, 0.17 * flash), true)

    for i in range(segments.size() / 2):
        var start: Vector2 = segments[i * 2]
        var finish: Vector2 = segments[i * 2 + 1]
        var glow_color: Color = field_color.lerp(GOLD, 0.42)
        draw_line(start, finish, Color(glow_color, 0.18 * fade * intro), 18.0, true)
        draw_line(start, finish, Color(WHITE_GLOW, 0.94 * fade * intro), 4.0 + 3.0 * (1.0 - t), true)

        var bead_t: float = fmod(t * 2.7 + float(i) * 0.23, 1.0)
        var bead: Vector2 = start.lerp(finish, bead_t)
        draw_circle(bead, 7.0 * fade + 2.0, Color(WHITE_GLOW, 0.92 * fade))

    var base_radius: float = minf(size.x, size.y) * 0.18
    for ring_index in range(3):
        var delayed: float = clampf((t - float(ring_index) * 0.10) / 0.78, 0.0, 1.0)
        if delayed <= 0.0:
            continue
        var radius: float = base_radius * (0.58 + delayed * (1.65 + 0.23 * ring_index))
        var alpha: float = (1.0 - delayed) * (0.76 - 0.13 * ring_index)
        var ring_color: Color = WHITE_GLOW if ring_index == 0 else field_color.lerp(GOLD, 0.38)
        draw_arc(center, radius, 0.0, TAU, 128, Color(ring_color, alpha), 5.0 - float(ring_index), true)

    var ray_alpha: float = fade * (1.0 - absf(t - 0.28)) * 0.44
    for ray in range(16):
        var angle: float = TAU * float(ray) / 16.0 + elapsed * 0.42
        var inner: Vector2 = center + Vector2(cos(angle), sin(angle)) * base_radius * 0.28
        var outer: Vector2 = center + Vector2(cos(angle), sin(angle)) * base_radius * (0.92 + t * 0.90)
        draw_line(inner, outer, Color(GOLD, maxf(0.0, ray_alpha)), 2.0, true)

    draw_circle(center, maxf(2.0, base_radius * 0.16 * (1.0 - t)), Color(WHITE_GLOW, 0.82 * fade))
