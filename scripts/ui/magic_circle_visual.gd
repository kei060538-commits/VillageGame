extends Control

const BREAKTHROUGH_OVERLAY := preload("res://scripts/ui/breakthrough_overlay.gd")

const VIOLET := Color("9a61ff")
const VIOLET_SOFT := Color("7040b8")
const GOLD := Color("dcb56f")
const WHITE_GLOW := Color("ece7ff")
const DARK := Color("09091a")

var glyph_states: Array[int] = []
var glyph_rotations: Array[int] = []
var connections: Array[Vector2i] = []
var current_field := "Healing"
var time := 0.0
var celebration := 0.0
var drag_source := -1
var drag_point := Vector2.ZERO
var drag_active := false

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process(true)
    queue_redraw()

func set_state(states: Array[int], field_name: String, rotations: Array[int] = [], links: Array[Vector2i] = []) -> void:
    glyph_states = states.duplicate()
    glyph_rotations = rotations.duplicate()
    connections = links.duplicate()
    current_field = field_name
    queue_redraw()

func set_mana_drag_preview(source: int, point: Vector2, active: bool) -> void:
    drag_source = source
    drag_point = point
    drag_active = active
    queue_redraw()

func celebrate() -> void:
    celebration = 1.0
    _spawn_breakthrough_overlay()

func _spawn_breakthrough_overlay() -> void:
    if not is_inside_tree() or size.x <= 0.0 or size.y <= 0.0:
        return

    var transform := get_global_transform_with_canvas()
    var screen_center: Vector2 = transform * (size * 0.5)
    var segments: Array[Vector2] = []
    for link in connections:
        var a: int = link.x
        var b: int = link.y
        if a < 0 or a >= 9 or b < 0 or b >= 9:
            continue
        if a >= glyph_states.size() or b >= glyph_states.size():
            continue
        if glyph_states[a] <= 0 or glyph_states[b] <= 0:
            continue
        segments.append(transform * get_slot_position(a))
        segments.append(transform * get_slot_position(b))

    var layer := CanvasLayer.new()
    layer.layer = 120
    get_tree().root.add_child(layer)

    var overlay := BREAKTHROUGH_OVERLAY.new()
    layer.add_child(overlay)
    overlay.setup(screen_center, segments, _field_color(current_field))
    overlay.finished.connect(layer.queue_free)

func get_slot_position(index: int) -> Vector2:
    var c: Vector2 = size * 0.5
    var ring: float = minf(size.x, size.y) * 0.345
    var positions := [
        c + Vector2(-ring * 0.72, -ring * 0.72),
        c + Vector2(0, -ring),
        c + Vector2(ring * 0.72, -ring * 0.72),
        c + Vector2(-ring, 0),
        c,
        c + Vector2(ring, 0),
        c + Vector2(-ring * 0.72, ring * 0.72),
        c + Vector2(0, ring),
        c + Vector2(ring * 0.72, ring * 0.72),
    ]
    return Vector2(positions[index])

func _process(delta: float) -> void:
    time += delta
    celebration = maxf(0.0, celebration - delta * 0.55)
    queue_redraw()

func _draw() -> void:
    if size.x <= 0.0 or size.y <= 0.0:
        return

    var c: Vector2 = size * 0.5
    var radius: float = minf(size.x, size.y) * 0.34
    var pulse: float = 0.5 + 0.5 * sin(time * 1.7)
    var field_color: Color = _field_color(current_field)

    draw_circle(c, radius * 1.21, Color(DARK, 0.72))
    for i in range(5, 0, -1):
        var halo: Color = field_color
        halo.a = (0.015 + celebration * 0.045) * float(6 - i)
        draw_circle(c, radius * (1.06 + 0.055 * i), halo)

    draw_arc(c, radius * 1.03, 0, TAU, 128, Color(GOLD, 0.58), 2.4, true)
    draw_arc(c, radius * 0.84, 0, TAU, 128, Color(field_color, 0.76 + pulse * 0.14), 2.8, true)
    draw_arc(c, radius * 0.51, 0, TAU, 96, Color(VIOLET, 0.62), 2.0, true)

    for i in range(24):
        var angle: float = TAU * float(i) / 24.0 + time * 0.045
        var inner: Vector2 = c + Vector2(cos(angle), sin(angle)) * radius * 0.91
        var outer_len: float = 0.985 if i % 3 == 0 else 0.955
        var outer: Vector2 = c + Vector2(cos(angle), sin(angle)) * radius * outer_len
        var tick_color: Color = GOLD if i % 3 == 0 else VIOLET_SOFT
        tick_color.a = 0.72
        draw_line(inner, outer, tick_color, 1.6)

    var diamond := PackedVector2Array([
        c + Vector2(0, -radius * 0.49),
        c + Vector2(radius * 0.49, 0),
        c + Vector2(0, radius * 0.49),
        c + Vector2(-radius * 0.49, 0),
        c + Vector2(0, -radius * 0.49),
    ])
    draw_polyline(diamond, Color(field_color, 0.48), 1.8, true)

    var square := PackedVector2Array([
        c + Vector2(-radius * 0.34, -radius * 0.34),
        c + Vector2(radius * 0.34, -radius * 0.34),
        c + Vector2(radius * 0.34, radius * 0.34),
        c + Vector2(-radius * 0.34, radius * 0.34),
        c + Vector2(-radius * 0.34, -radius * 0.34),
    ])
    draw_polyline(square, Color(VIOLET_SOFT, 0.42), 1.5, true)

    for i in range(9):
        if i == 4:
            continue
        var slot: Vector2 = get_slot_position(i)
        var active: bool = i < glyph_states.size() and glyph_states[i] > 0
        var line_color: Color = field_color if active else VIOLET_SOFT
        line_color.a = (0.30 + pulse * 0.08) if active else 0.10
        draw_line(c, slot, line_color, 1.4 if active else 0.9, true)

    _draw_connections(field_color, pulse)

    if drag_active and drag_source >= 0 and drag_source < 9:
        var start: Vector2 = get_slot_position(drag_source)
        draw_line(start, drag_point, Color(WHITE_GLOW, 0.22), 9.0, true)
        draw_line(start, drag_point, Color(WHITE_GLOW, 0.94), 3.0, true)
        draw_circle(drag_point, 5.5 + pulse * 2.0, Color(WHITE_GLOW, 0.86))

    var core_active: bool = glyph_states.size() > 4 and glyph_states[4] > 0
    var core_color: Color = WHITE_GLOW if core_active else VIOLET_SOFT
    for i in range(4, 0, -1):
        var cc: Color = core_color
        cc.a = (0.022 + celebration * 0.035) * float(5 - i)
        draw_circle(c, radius * 0.11 * float(i), cc)
    draw_circle(c, 3.8 + pulse * 1.2, Color(core_color, 0.96))

    for i in range(9):
        var state: int = glyph_states[i] if i < glyph_states.size() else 0
        var rotation_steps: int = glyph_rotations[i] if i < glyph_rotations.size() else 0
        var glyph_color: Color = field_color
        if i == 4:
            glyph_color = WHITE_GLOW
        elif i == 0 or i == 2 or i == 6 or i == 8:
            glyph_color = GOLD
        _draw_glyph(get_slot_position(i), state, glyph_color, radius * 0.105, pulse, rotation_steps)

    if celebration > 0.0:
        var burst: float = celebration
        for ring_index in range(3):
            var offset: float = float(ring_index) * 0.12
            var phase: float = clampf(1.0 - burst - offset, 0.0, 1.0)
            if phase > 0.0:
                draw_arc(
                    c,
                    radius * (1.0 + phase * (0.34 + float(ring_index) * 0.08)),
                    0,
                    TAU,
                    128,
                    Color(WHITE_GLOW, (1.0 - phase) * burst * (0.82 - float(ring_index) * 0.16)),
                    5.0 - float(ring_index),
                    true
                )

func _draw_connections(field_color: Color, pulse: float) -> void:
    for index in range(connections.size()):
        var link: Vector2i = connections[index]
        var a: int = link.x
        var b: int = link.y
        if a < 0 or a >= 9 or b < 0 or b >= 9:
            continue
        if a >= glyph_states.size() or b >= glyph_states.size():
            continue
        if glyph_states[a] <= 0 or glyph_states[b] <= 0:
            continue

        var start := get_slot_position(a)
        var finish := get_slot_position(b)
        var same_glyph: bool = glyph_states[a] == glyph_states[b]
        var color: Color = GOLD if same_glyph else field_color
        var celebration_boost: float = celebration * 0.30
        draw_line(start, finish, Color(color, 0.16 + celebration_boost), 10.0 + celebration * 8.0, true)
        draw_line(start, finish, Color(color.lerp(WHITE_GLOW, celebration * 0.82), 0.72 + pulse * 0.16 + celebration * 0.10), 3.2 + celebration * 2.8, true)

        var flow_speed: float = 0.27 + celebration * 1.35
        var flow: float = fmod(time * flow_speed + float(index) * 0.19, 1.0)
        var bead: Vector2 = start.lerp(finish, flow)
        draw_circle(bead, 4.6 + pulse * 1.1 + celebration * 4.0, Color(WHITE_GLOW, 0.94))

func _draw_glyph(center: Vector2, state: int, color: Color, glyph_radius: float, pulse: float, rotation_steps: int) -> void:
    if state <= 0:
        draw_arc(center, glyph_radius * 0.90, 0, TAU, 40, Color(color, 0.12), 1.4, true)
        draw_circle(center, 3.5 + pulse * 0.6, Color(color, 0.92))
        return

    var glow: Color = Color(color, 0.40 + celebration * 0.24)
    var main_color: Color = color.lerp(WHITE_GLOW, 0.30 + celebration * 0.45)
    main_color.a = 0.98
    var rotation: float = float(rotation_steps % 8) * PI * 0.25
    var glow_width: float = 12.0 + celebration * 6.0
    var main_width: float = 4.8 + celebration * 2.2

    match state:
        1:
            draw_arc(center, glyph_radius, 0, TAU, 64, glow, glow_width, true)
            draw_arc(center, glyph_radius, 0, TAU, 64, main_color, main_width, true)
        2:
            var tri := _rotated_poly(center, [
                Vector2(0, -glyph_radius),
                Vector2(glyph_radius * 0.90, glyph_radius * 0.72),
                Vector2(-glyph_radius * 0.90, glyph_radius * 0.72),
                Vector2(0, -glyph_radius),
            ], rotation)
            draw_polyline(tri, glow, glow_width, true)
            draw_polyline(tri, main_color, main_width, true)
        3:
            var sq := _rotated_poly(center, [
                Vector2(-glyph_radius * 0.78, -glyph_radius * 0.78),
                Vector2(glyph_radius * 0.78, -glyph_radius * 0.78),
                Vector2(glyph_radius * 0.78, glyph_radius * 0.78),
                Vector2(-glyph_radius * 0.78, glyph_radius * 0.78),
                Vector2(-glyph_radius * 0.78, -glyph_radius * 0.78),
            ], rotation)
            draw_polyline(sq, glow, glow_width, true)
            draw_polyline(sq, main_color, main_width, true)
        4:
            var dia := _rotated_poly(center, [
                Vector2(0, -glyph_radius),
                Vector2(glyph_radius, 0),
                Vector2(0, glyph_radius),
                Vector2(-glyph_radius, 0),
                Vector2(0, -glyph_radius),
            ], rotation)
            draw_polyline(dia, glow, glow_width, true)
            draw_polyline(dia, main_color, main_width, true)
        5:
            var local_star: Array[Vector2] = []
            for i in range(8):
                var angle: float = -PI * 0.5 + TAU * float(i) / 8.0
                var r: float = glyph_radius if i % 2 == 0 else glyph_radius * 0.30
                local_star.append(Vector2(cos(angle), sin(angle)) * r)
            local_star.append(local_star[0])
            var star := _rotated_poly(center, local_star, rotation)
            draw_polyline(star, glow, glow_width, true)
            draw_polyline(star, main_color, main_width, true)

    var direction: Vector2 = Vector2(0, -glyph_radius).rotated(rotation)
    var notch_start: Vector2 = center + direction * 0.32
    var notch_end: Vector2 = center + direction * 1.03
    draw_line(notch_start, notch_end, Color(WHITE_GLOW, 0.96), 3.1, true)
    draw_circle(notch_end, 3.8 + pulse * 0.45, Color(WHITE_GLOW, 0.98))

func _rotated_poly(center: Vector2, local_points: Array, rotation: float) -> PackedVector2Array:
    var result := PackedVector2Array()
    for point in local_points:
        result.append(center + Vector2(point).rotated(rotation))
    return result

func _field_color(field_name: String) -> Color:
    match field_name:
        "Healing": return Color("b891ff")
        "Agriculture": return Color("8fd6a2")
        "Construction": return Color("e2b36f")
        "Weather": return Color("83b9ff")
        "Combat": return Color("d96988")
        _: return VIOLET
