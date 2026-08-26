extends Control

const VIOLET := Color("9a61ff")
const VIOLET_SOFT := Color("7040b8")
const GOLD := Color("dcb56f")
const WHITE_GLOW := Color("ece7ff")
const DARK := Color("09091a")

var glyph_states: Array[int] = []
var current_field := "Healing"
var time := 0.0
var celebration := 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process(true)
    queue_redraw()

func set_state(states: Array[int], field_name: String) -> void:
    glyph_states = states.duplicate()
    current_field = field_name
    queue_redraw()

func celebrate() -> void:
    celebration = 1.0

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

    draw_arc(c, radius * 1.03, 0, TAU, 128, Color(GOLD, 0.52), 2.2, true)
    draw_arc(c, radius * 0.84, 0, TAU, 128, Color(field_color, 0.70 + pulse * 0.16), 2.4, true)
    draw_arc(c, radius * 0.51, 0, TAU, 96, Color(VIOLET, 0.52), 1.7, true)

    for i in range(24):
        var angle: float = TAU * float(i) / 24.0 + time * 0.045
        var inner: Vector2 = c + Vector2(cos(angle), sin(angle)) * radius * 0.91
        var outer_len: float = 0.985 if i % 3 == 0 else 0.955
        var outer: Vector2 = c + Vector2(cos(angle), sin(angle)) * radius * outer_len
        var tick_color: Color = GOLD if i % 3 == 0 else VIOLET_SOFT
        tick_color.a = 0.62
        draw_line(inner, outer, tick_color, 1.4)

    var diamond := PackedVector2Array([
        c + Vector2(0, -radius * 0.49),
        c + Vector2(radius * 0.49, 0),
        c + Vector2(0, radius * 0.49),
        c + Vector2(-radius * 0.49, 0),
        c + Vector2(0, -radius * 0.49),
    ])
    draw_polyline(diamond, Color(field_color, 0.38), 1.5, true)

    var square := PackedVector2Array([
        c + Vector2(-radius * 0.34, -radius * 0.34),
        c + Vector2(radius * 0.34, -radius * 0.34),
        c + Vector2(radius * 0.34, radius * 0.34),
        c + Vector2(-radius * 0.34, radius * 0.34),
        c + Vector2(-radius * 0.34, -radius * 0.34),
    ])
    draw_polyline(square, Color(VIOLET_SOFT, 0.32), 1.1, true)

    for i in range(9):
        if i == 4:
            continue
        var slot: Vector2 = get_slot_position(i)
        var active: bool = i < glyph_states.size() and glyph_states[i] > 0
        var line_color: Color = field_color if active else VIOLET_SOFT
        line_color.a = (0.50 + pulse * 0.22) if active else 0.11
        draw_line(c, slot, line_color, 1.9 if active else 0.9, true)

    var pairs := [[0, 8], [2, 6], [1, 7], [3, 5]]
    for pair in pairs:
        var a: int = int(pair[0])
        var b: int = int(pair[1])
        if a < glyph_states.size() and b < glyph_states.size() and glyph_states[a] > 0 and glyph_states[a] == glyph_states[b]:
            draw_line(get_slot_position(a), get_slot_position(b), Color(GOLD, 0.44 + pulse * 0.20), 2.3, true)

    var core_active: bool = glyph_states.size() > 4 and glyph_states[4] > 0
    var core_color: Color = WHITE_GLOW if core_active else VIOLET_SOFT
    for i in range(4, 0, -1):
        var cc: Color = core_color
        cc.a = (0.018 + celebration * 0.035) * float(5 - i)
        draw_circle(c, radius * 0.11 * float(i), cc)
    draw_circle(c, 3.5 + pulse * 1.2, Color(core_color, 0.92))

    # Glyphs are vector-drawn instead of font characters so Web exports never depend on CJK/symbol fonts.
    for i in range(9):
        var state: int = glyph_states[i] if i < glyph_states.size() else 0
        var glyph_color: Color = field_color
        if i == 4:
            glyph_color = WHITE_GLOW
        elif i == 0 or i == 2 or i == 6 or i == 8:
            glyph_color = GOLD
        _draw_glyph(get_slot_position(i), state, glyph_color, radius * 0.105, pulse)

    if celebration > 0.0:
        var burst: float = celebration
        draw_arc(c, radius * (1.0 + (1.0 - burst) * 0.33), 0, TAU, 128, Color(WHITE_GLOW, burst * 0.72), 4.0, true)

func _draw_glyph(center: Vector2, state: int, color: Color, glyph_radius: float, pulse: float) -> void:
    if state <= 0:
        draw_circle(center, 3.0 + pulse, Color(color, 0.88))
        return

    var glow: Color = Color(color, 0.20)
    match state:
        1:
            draw_arc(center, glyph_radius, 0, TAU, 48, glow, 8.0, true)
            draw_arc(center, glyph_radius, 0, TAU, 48, color, 3.0, true)
        2:
            var tri := PackedVector2Array([
                center + Vector2(0, -glyph_radius),
                center + Vector2(glyph_radius * 0.90, glyph_radius * 0.72),
                center + Vector2(-glyph_radius * 0.90, glyph_radius * 0.72),
                center + Vector2(0, -glyph_radius),
            ])
            draw_polyline(tri, glow, 8.0, true)
            draw_polyline(tri, color, 3.0, true)
        3:
            var sq := PackedVector2Array([
                center + Vector2(-glyph_radius * 0.78, -glyph_radius * 0.78),
                center + Vector2(glyph_radius * 0.78, -glyph_radius * 0.78),
                center + Vector2(glyph_radius * 0.78, glyph_radius * 0.78),
                center + Vector2(-glyph_radius * 0.78, glyph_radius * 0.78),
                center + Vector2(-glyph_radius * 0.78, -glyph_radius * 0.78),
            ])
            draw_polyline(sq, glow, 8.0, true)
            draw_polyline(sq, color, 3.0, true)
        4:
            var dia := PackedVector2Array([
                center + Vector2(0, -glyph_radius),
                center + Vector2(glyph_radius, 0),
                center + Vector2(0, glyph_radius),
                center + Vector2(-glyph_radius, 0),
                center + Vector2(0, -glyph_radius),
            ])
            draw_polyline(dia, glow, 8.0, true)
            draw_polyline(dia, color, 3.0, true)
        5:
            var star := PackedVector2Array()
            for i in range(8):
                var angle: float = -PI * 0.5 + TAU * float(i) / 8.0
                var r: float = glyph_radius if i % 2 == 0 else glyph_radius * 0.30
                star.append(center + Vector2(cos(angle), sin(angle)) * r)
            star.append(star[0])
            draw_polyline(star, glow, 8.0, true)
            draw_polyline(star, color, 3.0, true)

func _field_color(field_name: String) -> Color:
    match field_name:
        "Healing": return Color("b891ff")
        "Agriculture": return Color("8fd6a2")
        "Construction": return Color("e2b36f")
        "Weather": return Color("83b9ff")
        "Combat": return Color("d96988")
        _: return VIOLET
