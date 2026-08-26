extends Node2D

const ARCANE_BACKGROUND := preload("res://scripts/ui/arcane_background.gd")

const INK := Color("e9e5ff")
const MUTED := Color("9993b7")
const GOLD := Color("dcb56f")
const VIOLET := Color("9a61ff")
const PANEL := Color("101024")
const PANEL_ALT := Color("171631")

var clock: GameClock
var event_log: VillageEventLog
var village: VillageSimulation
var player: WitchPlayer
var research_panel: MagicResearchPanel

var safe_root: Control
var year_label: Label
var food_label: Label
var disease_label: Label
var threat_label: Label
var chronicle_label: Label
var return_overlay: Control
var return_title: Label
var return_body: Label
var portrait_texture: TextureRect

func _ready() -> void:
    clock = GameClock.new()
    add_child(clock)

    event_log = VillageEventLog.new()
    add_child(event_log)

    # The simulation remains alive, but the village world is no longer the primary screen.
    village = VillageSimulation.new()
    village.visible = false
    add_child(village)
    village.setup(clock, event_log)

    player = WitchPlayer.new()
    player.visible = false
    player.position = Vector2(760, 650)
    add_child(player)

    _build_ui()
    get_viewport().size_changed.connect(_apply_safe_area_layout)
    call_deferred("_apply_safe_area_layout")
    event_log.event_added.connect(_refresh_event_log)
    _refresh_event_log({})

func _process(_delta: float) -> void:
    if year_label == null:
        return
    var year := int((clock.get_day() - 1) / 24) + 1
    year_label.text = "YEAR %04d  ·  %s" % [year, clock.format_time()]
    _refresh_village_pulse()

func _build_ui() -> void:
    var canvas := CanvasLayer.new()
    add_child(canvas)

    var background := ARCANE_BACKGROUND.new()
    canvas.add_child(background)

    safe_root = Control.new()
    safe_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    safe_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(safe_root)

    _build_header()
    _build_village_pulse()
    _build_research_surface()
    _build_chronicle()
    _build_return_overlay()

func _build_header() -> void:
    var header := PanelContainer.new()
    header.anchor_left = 0.0
    header.anchor_right = 1.0
    header.offset_left = 18.0
    header.offset_top = 14.0
    header.offset_right = -18.0
    header.offset_bottom = 126.0
    header.add_theme_stylebox_override("panel", _panel_style(Color("0e0e22"), Color(GOLD, 0.34), 20, 1))
    safe_root.add_child(header)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 14)
    header.add_child(row)

    var portrait_frame := PanelContainer.new()
    portrait_frame.custom_minimum_size = Vector2(88, 88)
    portrait_frame.add_theme_stylebox_override("panel", _panel_style(Color("191632"), Color(GOLD, 0.62), 18, 1))
    row.add_child(portrait_frame)

    portrait_texture = TextureRect.new()
    portrait_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    portrait_texture.custom_minimum_size = Vector2(78, 78)
    portrait_frame.add_child(portrait_texture)

    var portrait_path := "res://art/player/witch_portrait.png"
    if ResourceLoader.exists(portrait_path):
        portrait_texture.texture = load(portrait_path)
    else:
        var emblem := Label.new()
        emblem.text = "✦"
        emblem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        emblem.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        emblem.add_theme_color_override("font_color", Color("b891ff"))
        emblem.add_theme_font_size_override("font_size", 40)
        portrait_frame.add_child(emblem)

    var text_box := VBoxContainer.new()
    text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    text_box.alignment = BoxContainer.ALIGNMENT_CENTER
    row.add_child(text_box)

    var kicker := Label.new()
    kicker.text = "THE IMMORTAL WITCH"
    kicker.add_theme_color_override("font_color", GOLD)
    kicker.add_theme_font_size_override("font_size", 12)
    text_box.add_child(kicker)

    var title := Label.new()
    title.text = "魔法研究記録"
    title.add_theme_color_override("font_color", INK)
    title.add_theme_font_size_override("font_size", 24)
    text_box.add_child(title)

    year_label = Label.new()
    year_label.text = "YEAR 0001"
    year_label.add_theme_color_override("font_color", MUTED)
    year_label.add_theme_font_size_override("font_size", 13)
    text_box.add_child(year_label)

    var moon := Label.new()
    moon.text = "☾"
    moon.custom_minimum_size.x = 46
    moon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    moon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    moon.add_theme_color_override("font_color", GOLD)
    moon.add_theme_font_size_override("font_size", 31)
    row.add_child(moon)

func _build_village_pulse() -> void:
    var row := HBoxContainer.new()
    row.anchor_left = 0.0
    row.anchor_right = 1.0
    row.offset_left = 18.0
    row.offset_top = 138.0
    row.offset_right = -18.0
    row.offset_bottom = 202.0
    row.add_theme_constant_override("separation", 8)
    safe_root.add_child(row)

    food_label = _stat_card(row, "HARVEST", "食糧", Color("8fd6a2"))
    disease_label = _stat_card(row, "PLAGUE", "疫病", Color("b891ff"))
    threat_label = _stat_card(row, "THREAT", "魔物", Color("d96988"))
    _refresh_village_pulse()

func _stat_card(parent: HBoxContainer, english: String, japanese: String, accent: Color) -> Label:
    var panel := PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.add_theme_stylebox_override("panel", _panel_style(Color("101024"), Color(accent, 0.30), 13, 1))
    parent.add_child(panel)

    var box := VBoxContainer.new()
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    panel.add_child(box)

    var top := Label.new()
    top.text = "%s · %s" % [english, japanese]
    top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    top.add_theme_color_override("font_color", Color(accent, 0.88))
    top.add_theme_font_size_override("font_size", 10)
    box.add_child(top)

    var value := Label.new()
    value.text = "00%"
    value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    value.add_theme_color_override("font_color", INK)
    value.add_theme_font_size_override("font_size", 19)
    box.add_child(value)
    return value

func _build_research_surface() -> void:
    research_panel = MagicResearchPanel.new()
    research_panel.anchor_left = 0.0
    research_panel.anchor_right = 1.0
    research_panel.anchor_top = 0.0
    research_panel.anchor_bottom = 1.0
    research_panel.offset_left = 18.0
    research_panel.offset_top = 216.0
    research_panel.offset_right = -18.0
    research_panel.offset_bottom = -212.0
    research_panel.z_index = 10
    safe_root.add_child(research_panel)
    research_panel.research_completed.connect(_on_research_completed)

func _build_chronicle() -> void:
    var card := PanelContainer.new()
    card.anchor_left = 0.0
    card.anchor_right = 1.0
    card.anchor_top = 1.0
    card.anchor_bottom = 1.0
    card.offset_left = 18.0
    card.offset_top = -198.0
    card.offset_right = -18.0
    card.offset_bottom = -16.0
    card.add_theme_stylebox_override("panel", _panel_style(PANEL, Color(VIOLET, 0.26), 18, 1))
    safe_root.add_child(card)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 14)
    margin.add_theme_constant_override("margin_right", 14)
    margin.add_theme_constant_override("margin_top", 10)
    margin.add_theme_constant_override("margin_bottom", 10)
    card.add_child(margin)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 5)
    margin.add_child(box)

    var header := HBoxContainer.new()
    box.add_child(header)

    var heading := Label.new()
    heading.text = "VILLAGE CHRONICLE  ·  村の記憶"
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    heading.add_theme_color_override("font_color", GOLD)
    heading.add_theme_font_size_override("font_size", 12)
    header.add_child(heading)

    var generation := Label.new()
    generation.text = "20 SOULS"
    generation.add_theme_color_override("font_color", MUTED)
    generation.add_theme_font_size_override("font_size", 11)
    header.add_child(generation)

    chronicle_label = Label.new()
    chronicle_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    chronicle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    chronicle_label.add_theme_color_override("font_color", Color("c7c2dc"))
    chronicle_label.add_theme_font_size_override("font_size", 12)
    box.add_child(chronicle_label)

func _build_return_overlay() -> void:
    return_overlay = Control.new()
    return_overlay.visible = false
    return_overlay.z_index = 40
    return_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    return_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    safe_root.add_child(return_overlay)

    var dim := ColorRect.new()
    dim.color = Color(0.02, 0.015, 0.05, 0.76)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    return_overlay.add_child(dim)

    var card := PanelContainer.new()
    card.anchor_left = 0.08
    card.anchor_right = 0.92
    card.anchor_top = 0.32
    card.anchor_bottom = 0.68
    card.add_theme_stylebox_override("panel", _panel_style(Color("15132d"), Color(GOLD, 0.72), 24, 2))
    return_overlay.add_child(card)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 22)
    margin.add_theme_constant_override("margin_right", 22)
    margin.add_theme_constant_override("margin_top", 22)
    margin.add_theme_constant_override("margin_bottom", 22)
    card.add_child(margin)

    var box := VBoxContainer.new()
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    box.add_theme_constant_override("separation", 10)
    margin.add_child(box)

    var star := Label.new()
    star.text = "✦  ☾  ✦"
    star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    star.add_theme_color_override("font_color", GOLD)
    star.add_theme_font_size_override("font_size", 22)
    box.add_child(star)

    return_title = Label.new()
    return_title.text = "研究塔からの帰還"
    return_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    return_title.add_theme_color_override("font_color", INK)
    return_title.add_theme_font_size_override("font_size", 25)
    box.add_child(return_title)

    return_body = Label.new()
    return_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    return_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return_body.add_theme_color_override("font_color", Color("c8c2df"))
    return_body.add_theme_font_size_override("font_size", 14)
    box.add_child(return_body)

    var continue_button := Button.new()
    continue_button.text = "次の研究へ"
    continue_button.custom_minimum_size = Vector2(220, 50)
    continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    continue_button.focus_mode = Control.FOCUS_NONE
    continue_button.add_theme_font_size_override("font_size", 16)
    continue_button.add_theme_color_override("font_color", Color("171020"))
    continue_button.add_theme_stylebox_override("normal", _panel_style(GOLD, Color("f4d99e"), 14, 1))
    continue_button.add_theme_stylebox_override("hover", _panel_style(Color("f0cb82"), Color.WHITE, 14, 1))
    continue_button.pressed.connect(_dismiss_return_overlay)
    box.add_child(continue_button)

func _on_research_completed(level: int, field_name: String) -> void:
    village.apply_magic_research(level, field_name)
    var years_spent: int = clampi(8 + level * 2, 10, 30)
    clock.fast_forward_years(years_spent)
    event_log.add_event(
        "The immortal witch returned from the tower after %d years of research." % years_spent,
        clock.get_day(), clock.get_minute_of_day(), "history"
    )
    _show_return_overlay(years_spent, field_name)
    _refresh_village_pulse()
    _refresh_event_log({})

func _show_return_overlay(years_spent: int, field_name: String) -> void:
    var field_jp := {
        "Healing": "治癒魔法",
        "Agriculture": "農耕魔法",
        "Construction": "構築魔法",
        "Weather": "気象魔法",
        "Combat": "戦闘魔法",
    }.get(field_name, field_name)
    return_title.text = "%d年後の村へ" % years_spent
    return_body.text = "%sが村の知識として受け継がれた。\nあなたの姿は変わらない。けれど村の時間だけが進んでいる。" % str(field_jp)
    return_overlay.visible = true

func _dismiss_return_overlay() -> void:
    return_overlay.visible = false

func _refresh_village_pulse() -> void:
    if food_label != null:
        food_label.text = "%02d%%" % int(village.food_security)
    if disease_label != null:
        disease_label.text = "%02d%%" % int(village.disease_pressure)
    if threat_label != null:
        threat_label.text = "%02d%%" % int(village.monster_threat)

func _refresh_event_log(_entry: Dictionary) -> void:
    if chronicle_label == null:
        return
    var lines: Array[String] = []
    for entry in event_log.latest(4):
        lines.append("• " + event_log.format_entry(entry))
    chronicle_label.text = "\n".join(lines)

func _apply_safe_area_layout() -> void:
    if safe_root == null:
        return

    safe_root.offset_left = 0.0
    safe_root.offset_top = 0.0
    safe_root.offset_right = 0.0
    safe_root.offset_bottom = 0.0

    if not (OS.has_feature("ios") or OS.has_feature("android")):
        return

    var viewport_size: Vector2 = get_viewport().get_visible_rect().size
    var window_size: Vector2i = DisplayServer.window_get_size()
    var safe_area: Rect2i = DisplayServer.get_display_safe_area()
    if window_size.x <= 0 or window_size.y <= 0 or safe_area.size.x <= 0 or safe_area.size.y <= 0:
        return

    var scale_x: float = viewport_size.x / float(window_size.x)
    var scale_y: float = viewport_size.y / float(window_size.y)
    var left_inset := maxf(0.0, float(safe_area.position.x) * scale_x)
    var top_inset := maxf(0.0, float(safe_area.position.y) * scale_y)
    var unsafe_right: int = window_size.x - (safe_area.position.x + safe_area.size.x)
    var unsafe_bottom: int = window_size.y - (safe_area.position.y + safe_area.size.y)
    var right_inset := maxf(0.0, float(unsafe_right) * scale_x)
    var bottom_inset := maxf(0.0, float(unsafe_bottom) * scale_y)

    safe_root.offset_left = left_inset
    safe_root.offset_top = top_inset
    safe_root.offset_right = -right_inset
    safe_root.offset_bottom = -bottom_inset

func _panel_style(bg: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = border
    style.border_width_left = width
    style.border_width_top = width
    style.border_width_right = width
    style.border_width_bottom = width
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    style.content_margin_left = 10.0
    style.content_margin_right = 10.0
    style.content_margin_top = 8.0
    style.content_margin_bottom = 8.0
    style.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
    style.shadow_size = 8
    return style
