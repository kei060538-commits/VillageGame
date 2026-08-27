extends Control

const BASE := Color("09091a")
const MID := Color("11112b")
const VIOLET := Color("6f3bc3")
const GOLD := Color("d8a85b")

var time := 0.0
var stars: Array[Dictionary] = []

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var rng := RandomNumberGenerator.new()
    rng.seed = 44021
    for i in range(46):
        stars.append({
            "p": Vector2(rng.randf(), rng.randf()),
            "r": rng.randf_range(0.7, 2.2),
            "phase": rng.randf_range(0.0, TAU),
            "warm": rng.randf() < 0.16,
        })
    queue_redraw()

func _process(delta: float) -> void:
    time += delta
    queue_redraw()

func _draw() -> void:
    var s := size
    if s.x <= 0.0 or s.y <= 0.0:
        return

    draw_rect(Rect2(Vector2.ZERO, s), BASE)

    # Soft vertical atmosphere bands.
    var bands := 14
    for i in range(bands):
        var t := float(i) / float(bands - 1)
        var band_color := BASE.lerp(MID, 0.45 + sin(t * PI) * 0.35)
        band_color.a = 0.45
        draw_rect(Rect2(0.0, s.y * t, s.x, s.y / float(bands) + 2.0), band_color)

    # Violet nebula glows behind the research surface.
    _draw_glow(Vector2(s.x * 0.20, s.y * 0.34), s.x * 0.42, VIOLET, 0.055)
    _draw_glow(Vector2(s.x * 0.86, s.y * 0.62), s.x * 0.52, Color("40206e"), 0.050)
    _draw_glow(Vector2(s.x * 0.48, s.y * 0.92), s.x * 0.34, Color("7d46cf"), 0.035)

    for star in stars:
        var p := Vector2(star["p"]) * s
        var pulse := 0.55 + 0.45 * sin(time * 1.3 + float(star["phase"]))
        var color := GOLD if bool(star["warm"]) else Color("b8b7ff")
        color.a = 0.24 + pulse * 0.48
        var radius := float(star["r"]) * (0.85 + pulse * 0.22)
        draw_circle(p, radius, color)
        if radius > 1.45:
            draw_line(p - Vector2(radius * 2.4, 0), p + Vector2(radius * 2.4, 0), color, 0.8)
            draw_line(p - Vector2(0, radius * 2.4), p + Vector2(0, radius * 2.4), color, 0.8)

    # Decorative crescent and fine gold frame marks.
    var moon_center := Vector2(s.x * 0.86, s.y * 0.105)
    draw_arc(moon_center, 34.0, -PI * 0.62, PI * 0.62, 48, Color(GOLD, 0.65), 2.0, true)
    draw_arc(moon_center + Vector2(12, 0), 28.0, -PI * 0.62, PI * 0.62, 48, Color(BASE, 0.96), 8.0, true)
    draw_line(Vector2(24, 54), Vector2(24, 118), Color(GOLD, 0.28), 1.0)
    draw_line(Vector2(s.x - 24, s.y - 118), Vector2(s.x - 24, s.y - 54), Color(GOLD, 0.28), 1.0)

func _draw_glow(center: Vector2, radius: float, color: Color, alpha: float) -> void:
    for i in range(7, 0, -1):
        var c := color
        c.a = alpha * (1.0 - float(i - 1) / 7.0)
        draw_circle(center, radius * float(i) / 7.0, c)
