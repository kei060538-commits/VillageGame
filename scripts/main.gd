extends Node2D

const ARCANE_BACKGROUND := preload("res://scripts/ui/arcane_background.gd")
const RESEARCH_REQUEST_PLANNER := preload("res://scripts/systems/research_request_planner.gd")

const INK := Color("e9e5ff")
const MUTED := Color("aaa4c4")
const GOLD := Color("dcb56f")
const VIOLET := Color("9a61ff")
const PANEL := Color("101024")

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
var chronicle_card: PanelContainer
var chronicle_button: Button
var chronicle_expanded := false
var return_overlay: Control
var return_title: Label
var return_body: Label
var portrait_texture: TextureRect

func _ready() -> void:
    clock = GameClock.new()
    add_child(clock)

    event_log = VillageEventLog.new()
    add_child(event_log)

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
    var year: int = int((clock.get_day() - 1) / 24) + 1
    if _japanese_ui_enabled():
        year_label.text = "%04d年   %s" % [year, clock.format_time()]
    else:
        year_label.text = "YEAR %04d   %s" % [year, clock.format_time()]
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
    header.offset_left = 16.0
    header.offset_top = 12.0
    header.offset_right = -16.0
    header.offset_bottom = 132.0
    header.add_theme_stylebox_override("panel", _panel_style(Color("0e0e22"), Color(GOLD, 0.40), 20, 1))
    safe_root.add_child(header)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 14)
    header.add_child(row)

    var portrait_frame := PanelContainer.new()
    portrait_frame.custom_minimum_size = Vector2(92, 92)
    portrait_frame.add_theme_stylebox_override("panel", _panel_style(Color("191632"), Color(GOLD, 0.68), 18, 1))
    row.add_child(portrait_frame)

    portrait_texture = TextureRect.new()
    portrait_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    portrait_texture.custom_minimum_size = Vector2(82, 82)
    portrait_frame.add_child(portrait_texture)

    var portrait_path: String = "res://art/player/witch_portrait.png"
    if ResourceLoader.exists(portrait_path):
        portrait_texture.texture = load(portrait_path)
    else:
        var emblem := Label.new()
        emblem.text = "*"
        emblem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        emblem.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        emblem.add_theme_color_override("font_color", Color("b891ff"))
        emblem.add_theme_font_size_override("font_size", 48)
        portrait_frame.add_child(emblem)

    var text_box := VBoxContainer.new()
    text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    text_box.alignment = BoxContainer.ALIGNMENT_CENTER
    text_box.add_theme_constant_override("separation", 2)
    row.add_child(text_box)

    var kicker := Label.new()
    kicker.text = "THE IMMORTAL WITCH"
    kicker.add_theme_color_override("font_color", GOLD)
    kicker.add_theme_font_size_override("font_size", 14)
    text_box.add_child(kicker)

    var title := Label.new()
    title.text = _ui("魔法研究記録", "ARCANE RESEARCH")
    title.add_theme_color_override("font_color", INK)
    title.add_theme_font_size_override("font_size", 27)
    text_box.add_child(title)

    year_label = Label.new()
    year_label.text = _ui("0001年", "YEAR 0001")
    year_label.add_theme_color_override("font_color", MUTED)
    year_label.add_theme_font_size_override("font_size", 16)
    text_box.add_child(year_label)

    var mark := Label.new()
    mark.text = "O"
    mark.custom_minimum_size.x = 42
    mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    mark.add_theme_color_override("font_color", GOLD)
    mark.add_theme_font_size_override("font_size", 25)
    row.add_child(mark)

func _build_village_pulse() -> void:
    var row := HBoxContainer.new()
    row.anchor_left = 0.0
    row.anchor_right = 1.0
    row.offset_left = 16.0
    row.offset_top = 144.0
    row.offset_right = -16.0
    row.offset_bottom = 216.0
    row.add_theme_constant_override("separation", 8)
    safe_root.add_child(row)

    food_label = _stat_card(row, "HARVEST", "食糧", Color("8fd6a2"))
    disease_label = _stat_card(row, "PLAGUE", "疫病", Color("b891ff"))
    threat_label = _stat_card(row, "THREAT", "魔物", Color("d96988"))
    _refresh_village_pulse()

func _stat_card(parent: HBoxContainer, english: String, japanese: String, accent: Color) -> Label:
    var panel := PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.add_theme_stylebox_override("panel", _panel_style(Color("101024"), Color(accent, 0.34), 14, 1))
    parent.add_child(panel)

    var box := VBoxContainer.new()
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    box.add_theme_constant_override("separation", 0)
    panel.add_child(box)

    var top := Label.new()
    top.text = _ui(japanese, english)
    top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    top.add_theme_color_override("font_color", Color(accent, 0.92))
    top.add_theme_font_size_override("font_size", 13)
    box.add_child(top)

    var value := Label.new()
    value.text = "00%"
    value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    value.add_theme_color_override("font_color", INK)
    value.add_theme_font_size_override("font_size", 24)
    box.add_child(value)
    return value

func _build_research_surface() -> void:
    research_panel = MagicResearchPanel.new()
    research_panel.japanese_ui = _japanese_ui_enabled()
    research_panel.anchor_left = 0.0
    research_panel.anchor_right = 1.0
    research_panel.anchor_top = 0.0
    research_panel.anchor_bottom = 1.0
    research_panel.offset_left = 16.0
    research_panel.offset_top = 230.0
    research_panel.offset_right = -16.0
    research_panel.offset_bottom = -92.0
    research_panel.z_index = 10
    safe_root.add_child(research_panel)
    research_panel.research_completed.connect(_on_research_completed)
    research_panel.set_village_request(_current_research_request())

func _build_chronicle() -> void:
    chronicle_card = PanelContainer.new()
    chronicle_card.z_index = 24
    chronicle_card.anchor_left = 0.0
    chronicle_card.anchor_right = 1.0
    chronicle_card.anchor_top = 1.0
    chronicle_card.anchor_bottom = 1.0
    chronicle_card.offset_left = 16.0
    chronicle_card.offset_top = -78.0
    chronicle_card.offset_right = -16.0
    chronicle_card.offset_bottom = -12.0
    chronicle_card.add_theme_stylebox_override("panel", _panel_style(PANEL, Color(VIOLET, 0.34), 18, 1))
    safe_root.add_child(chronicle_card)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 14)
    margin.add_theme_constant_override("margin_right", 14)
    margin.add_theme_constant_override("margin_top", 10)
    margin.add_theme_constant_override("margin_bottom", 10)
    chronicle_card.add_child(margin)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 8)
    margin.add_child(box)

    var header := HBoxContainer.new()
    header.custom_minimum_size.y = 40
    box.add_child(header)

    var heading := Label.new()
    heading.text = _ui("村の記憶", "VILLAGE CHRONICLE")
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    heading.add_theme_color_override("font_color", GOLD)
    heading.add_theme_font_size_override("font_size", 16)
    header.add_child(heading)

    var generation := Label.new()
    generation.text = _ui("20人", "20 SOULS")
    generation.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    generation.add_theme_color_override("font_color", MUTED)
    generation.add_theme_font_size_override("font_size", 13)
    header.add_child(generation)

    chronicle_button = Button.new()
    chronicle_button.text = _ui("履歴", "LOG")
    chronicle_button.custom_minimum_size = Vector2(76, 40)
    chronicle_button.focus_mode = Control.FOCUS_NONE
    chronicle_button.add_theme_font_size_override("font_size", 14)
    chronicle_button.pressed.connect(_toggle_chronicle)
    header.add_child(chronicle_button)

    chronicle_label = Label.new()
    chronicle_label.visible = false
    chronicle_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    chronicle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    chronicle_label.add_theme_color_override("font_color", Color("d3cee6"))
    chronicle_label.add_theme_font_size_override("font_size", 15)
    box.add_child(chronicle_label)

func _toggle_chronicle() -> void:
    chronicle_expanded = not chronicle_expanded
    chronicle_label.visible = chronicle_expanded
    if chronicle_expanded:
        chronicle_button.text = _ui("閉じる", "CLOSE")
    else:
        chronicle_button.text = _ui("履歴", "LOG")
    chronicle_card.offset_top = -286.0 if chronicle_expanded else -78.0
    _refresh_event_log({})

func _build_return_overlay() -> void:
    return_overlay = Control.new()
    return_overlay.visible = false
    return_overlay.z_index = 40
    return_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    return_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    safe_root.add_child(return_overlay)

    var dim := ColorRect.new()
    dim.color = Color(0.02, 0.015, 0.05, 0.82)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    return_overlay.add_child(dim)

    var card := PanelContainer.new()
    card.anchor_left = 0.07
    card.anchor_right = 0.93
    card.anchor_top = 0.30
    card.anchor_bottom = 0.70
    card.add_theme_stylebox_override("panel", _panel_style(Color("15132d"), Color(GOLD, 0.78), 24, 2))
    return_overlay.add_child(card)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 24)
    margin.add_theme_constant_override("margin_right", 24)
    margin.add_theme_constant_override("margin_top", 24)
    margin.add_theme_constant_override("margin_bottom", 24)
    card.add_child(margin)

    var box := VBoxContainer.new()
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    box.add_theme_constant_override("separation", 14)
    margin.add_child(box)

    var star := Label.new()
    star.text = "*   *   *"
    star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    star.add_theme_color_override("font_color", GOLD)
    star.add_theme_font_size_override("font_size", 25)
    box.add_child(star)

    return_title = Label.new()
    return_title.text = _ui("研究塔からの帰還", "RETURN FROM THE TOWER")
    return_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    return_title.add_theme_color_override("font_color", INK)
    return_title.add_theme_font_size_override("font_size", 29)
    box.add_child(return_title)

    return_body = Label.new()
    return_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    return_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return_body.add_theme_color_override("font_color", Color("d5d0e7"))
    return_body.add_theme_font_size_override("font_size", 18)
    box.add_child(return_body)

    var continue_button := Button.new()
    continue_button.text = _ui("次の研究へ", "CONTINUE")
    continue_button.custom_minimum_size = Vector2(250, 58)
    continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    continue_button.focus_mode = Control.FOCUS_NONE
    continue_button.add_theme_font_size_override("font_size", 18)
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
    research_panel.set_village_request(_current_research_request(), false)
    _show_return_overlay(years_spent, field_name)
    _refresh_village_pulse()
    _refresh_event_log({})

func _current_research_request() -> Dictionary:
    var level: int = 0 if research_panel == null else int(research_panel.research_level)
    return RESEARCH_REQUEST_PLANNER.choose_request(
        village.food_security,
        village.disease_pressure,
        village.monster_threat,
        village.magic_fields,
        level
    )

func _show_return_overlay(years_spent: int, field_name: String) -> void:
    if not _japanese_ui_enabled():
        return_title.text = "%d YEARS LATER" % years_spent
        return_body.text = "%s magic entered the village tradition.\nYou have not aged, but the village has." % field_name
    else:
        var field_jp: String = str({
            "Healing": "治癒魔法",
            "Agriculture": "農耕魔法",
            "Construction": "構築魔法",
            "Weather": "気象魔法",
            "Combat": "戦闘魔法",
        }.get(field_name, field_name))
        return_title.text = "%d年後の村へ" % years_spent
        return_body.text = "%sが村の知識として受け継がれた。\nあなたの姿は変わらない。けれど村の時間だけが進んでいる。" % field_jp
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
    var count: int = 6 if chronicle_expanded else 2
    for entry in event_log.latest(count):
        lines.append("- " + event_log.format_entry(entry))
    chronicle_label.text = "\n".join(lines)

func _ui(japanese: String, english: String) -> String:
    return japanese if _japanese_ui_enabled() else english

func _japanese_ui_enabled() -> bool:
    if not OS.has_feature("web"):
        return true
    return bool(UIFont.japanese_ready)

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
    var left_inset: float = maxf(0.0, float(safe_area.position.x) * scale_x)
    var top_inset: float = maxf(0.0, float(safe_area.position.y) * scale_y)
    var unsafe_right: int = window_size.x - (safe_area.position.x + safe_area.size.x)
    var unsafe_bottom: int = window_size.y - (safe_area.position.y + safe_area.size.y)
    var right_inset: float = maxf(0.0, float(unsafe_right) * scale_x)
    var bottom_inset: float = maxf(0.0, float(unsafe_bottom) * scale_y)

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
