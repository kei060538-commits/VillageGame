extends Control

const ARCANE_BACKGROUND := preload("res://scripts/ui/arcane_background.gd")
const MAGIC_VISUAL := preload("res://scripts/ui/magic_circle_visual.gd")

const INK := Color("eeeaff")
const MUTED := Color("aaa4c4")
const GOLD := Color("dcb56f")
const VIOLET := Color("9a61ff")
const DARK := Color("09091a")

var start_button: Button
var decorative_circle
var fade: ColorRect
var starting := false

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    _build_background()
    _build_decorative_circle()
    _build_title_content()
    _build_fade()
    _fade_in()

func _build_background() -> void:
    var background := ARCANE_BACKGROUND.new()
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)

    var veil := ColorRect.new()
    veil.color = Color(0.015, 0.012, 0.045, 0.22)
    veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(veil)

func _build_decorative_circle() -> void:
    var stage := Control.new()
    stage.anchor_left = 0.07
    stage.anchor_right = 0.93
    stage.anchor_top = 0.08
    stage.anchor_bottom = 0.57
    stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(stage)

    decorative_circle = MAGIC_VISUAL.new()
    decorative_circle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    decorative_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stage.add_child(decorative_circle)

    var states: Array[int] = [4, 1, 5, 2, 4, 3, 5, 1, 2]
    var rotations: Array[int] = [0, 1, 2, 3, 0, 2, 1, 3, 2]
    var links: Array[Vector2i] = [
        Vector2i(4, 1),
        Vector2i(4, 3),
        Vector2i(4, 5),
        Vector2i(4, 7),
        Vector2i(0, 8),
        Vector2i(2, 6),
    ]
    decorative_circle.set_state(states, "Weather", rotations, links)

    var halo_title := Label.new()
    halo_title.text = "THE IMMORTAL WITCH"
    halo_title.anchor_left = 0.0
    halo_title.anchor_right = 1.0
    halo_title.anchor_top = 0.47
    halo_title.anchor_bottom = 0.57
    halo_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    halo_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    halo_title.add_theme_color_override("font_color", Color(GOLD, 0.80))
    halo_title.add_theme_font_size_override("font_size", 14)
    halo_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(halo_title)

func _build_title_content() -> void:
    var content := VBoxContainer.new()
    content.anchor_left = 0.08
    content.anchor_right = 0.92
    content.anchor_top = 0.57
    content.anchor_bottom = 0.95
    content.alignment = BoxContainer.ALIGNMENT_CENTER
    content.add_theme_constant_override("separation", 12)
    add_child(content)

    var overline := Label.new()
    overline.text = "A VILLAGE THROUGH CENTURIES"
    overline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    overline.add_theme_color_override("font_color", GOLD)
    overline.add_theme_font_size_override("font_size", 14)
    content.add_child(overline)

    var title := Label.new()
    title.text = "ARCANA OF AGES"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_color_override("font_color", INK)
    title.add_theme_font_size_override("font_size", 48)
    content.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "Design forbidden circles. Leave the tower.\nMeet the village decades later."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    subtitle.add_theme_color_override("font_color", MUTED)
    subtitle.add_theme_font_size_override("font_size", 17)
    content.add_child(subtitle)

    var spacer := Control.new()
    spacer.custom_minimum_size.y = 8
    content.add_child(spacer)

    start_button = Button.new()
    start_button.text = "ENTER THE TOWER"
    start_button.custom_minimum_size = Vector2(330, 66)
    start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    start_button.focus_mode = Control.FOCUS_NONE
    start_button.add_theme_font_size_override("font_size", 19)
    start_button.add_theme_color_override("font_color", Color("171020"))
    start_button.add_theme_stylebox_override("normal", _button_style(GOLD, Color("f1d395"), 16))
    start_button.add_theme_stylebox_override("hover", _button_style(Color("efc875"), Color.WHITE, 16))
    start_button.add_theme_stylebox_override("pressed", _button_style(Color("bd8845"), Color("f1d395"), 16))
    start_button.pressed.connect(_start_game)
    content.add_child(start_button)

    var gestures := Label.new()
    gestures.text = "TAP GLYPH  ·  ROTATE RUNE  ·  DRAG TO LINK"
    gestures.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    gestures.add_theme_color_override("font_color", Color(VIOLET, 0.72))
    gestures.add_theme_font_size_override("font_size", 13)
    content.add_child(gestures)

    var working := Label.new()
    working.text = "WORKING TITLE · EARLY PLAYABLE BUILD"
    working.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    working.add_theme_color_override("font_color", Color(MUTED, 0.45))
    working.add_theme_font_size_override("font_size", 11)
    content.add_child(working)

func _build_fade() -> void:
    fade = ColorRect.new()
    fade.z_index = 100
    fade.color = DARK
    fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(fade)

func _fade_in() -> void:
    fade.modulate.a = 1.0
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_QUAD)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(fade, "modulate:a", 0.0, 0.55)

func _start_game() -> void:
    if starting:
        return
    starting = true
    start_button.disabled = true
    start_button.text = "OPENING THE GRIMOIRE..."

    if decorative_circle != null:
        decorative_circle.celebrate()

    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(fade, "modulate:a", 1.0, 0.52)
    tween.tween_property(self, "scale", Vector2(1.025, 1.025), 0.52)
    await tween.finished
    get_tree().change_scene_to_file("res://scenes/main.tscn")

func _button_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = border
    style.border_width_left = 1
    style.border_width_top = 1
    style.border_width_right = 1
    style.border_width_bottom = 1
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    style.content_margin_left = 18.0
    style.content_margin_right = 18.0
    style.content_margin_top = 12.0
    style.content_margin_bottom = 12.0
    style.shadow_color = Color(GOLD, 0.18)
    style.shadow_size = 12
    return style
