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
    var c := size * 0.5
    var ring := minf(size.x, size.y) * 0.345
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

    var c := size * 0.5
    var radius := minf(size.x, size.y) * 0.34
    var pulse := 0.5 + 0.5 * sin(time * 1.7)
    var field_color := _field_color(current_field)

    # Deep glass plate and layered magical halo.
    draw_circle(c, radius * 1.21, Color(DARK, 0.72))
    for i in range(5, 0, -1):
        var halo := field_color
        halo.a = (0.015 + celebration * 0.045) * float(6 - i)
        draw_circle(c, radius * (1.06 + 0.055 * i), halo)

    draw_arc(c, radius * 1.03, 0, TAU, 128, Color(GOLD, 0.48), 2.0, true)
    draw_arc(c, radius * 0.84, 0, TAU, 128, Color(field_color, 0.68 + pulse * 0.16), 2.0, true)
    draw_arc(c, radius * 0.51, 0, TAU, 96, Color(VIOLET, 0.48), 1.5, true)

    # Rotating rune ticks.
    for i in range(24):
        var angle := TAU * float(i) / 24.0 + time * 0.045
        var inner := c + Vector2(cos(angle), sin(angle)) * radius * 0.91
        var outer_len := 0.985 if i % 3 == 0 else 0.955
        var outer := c + Vector2(cos(angle), sin(angle)) * radius * outer_len
        var tick_color := GOLD if i % 3 == 0 else VIOLET_SOFT
        tick_color.a = 0.58
        draw_line(inner, outer, tick_color, 1.25)

    # Core geometry.
    var diamond := PackedVector2Array([
        c + Vector2(0, -radius * 0.49),
        c + Vector2(radius * 0.49, 0),
        c + Vector2(0, radius * 0.49),
        c + Vector2(-radius * 0.49, 0),
        c + Vector2(0, -radius * 0.49),
    ])
    draw_polyline(diamond, Color(field_color, 0.34), 1.35, true)

    var square := PackedVector2Array([
        c + Vector2(-radius * 0.34, -radius * 0.34),
        c + Vector2(radius * 0.34, -radius * 0.34),
        c + Vector2(radius * 0.34, radius * 0.34),
        c + Vector2(-radius * 0.34, radius * 0.34),
        c + Vector2(-radius * 0.34, -radius * 0.34),
    ])
    draw_polyline(square, Color(VIOLET_SOFT, 0.28), 1.0, true)

    # Mana connections appear as glyphs are placed.
    for i in range(9):
        if i == 4:
            continue
        var slot := get_slot_position(i)
        var active := i < glyph_states.size() and glyph_states[i] > 0
        var line_color := field_color if active else VIOLET_SOFT
        line_color.a = (0.48 + pulse * 0.2) if active else 0.10
        draw_line(c, slot, line_color, 1.7 if active else 0.8, true)

    # Opposite matching glyphs create brighter stabilizing chords.
    var pairs := [[0, 8], [2, 6], [1, 7], [3, 5]]
    for pair in pairs:
        var a := int(pair[0])
        var b := int(pair[1])
        if a < glyph_states.size() and b < glyph_states.size() and glyph_states[a] > 0 and glyph_states[a] == glyph_states[b]:
            draw_line(get_slot_position(a), get_slot_position(b), Color(GOLD, 0.42 + pulse * 0.18), 2.1, true)

    # Center core glow.
    var core_active := glyph_states.size() > 4 and glyph_states[4] > 0
    var core_color := WHITE_GLOW if core_active else VIOLET_SOFT
    for i in range(4, 0, -1):
        var cc := core_color
        cc.a = (0.018 + celebration * 0.035) * float(5 - i)
        draw_circle(c, radius * 0.11 * float(i), cc)
    draw_circle(c, 3.5 + pulse * 1.2, Color(core_color, 0.92))

    if celebration > 0.0:
        var burst := celebration
        draw_arc(c, radius * (1.0 + (1.0 - burst) * 0.33), 0, TAU, 128, Color(WHITE_GLOW, burst * 0.72), 4.0, true)

func _field_color(field_name: String) -> Color:
    match field_name:
        "Healing": return Color("b891ff")
        "Agriculture": return Color("8fd6a2")
        "Construction": return Color("e2b36f")
        "Weather": return Color("83b9ff")
        "Combat": return Color("d96988")
        _: return VIOLET
