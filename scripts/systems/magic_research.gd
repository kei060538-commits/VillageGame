class_name MagicResearchPanel
extends Control

signal research_completed(level: int, field_name: String)

const MAGIC_VISUAL := preload("res://scripts/ui/magic_circle_visual.gd")

const GLYPHS := ["·", "○", "△", "□", "◇", "✦"]
const GLYPH_NAMES := ["Empty", "Circle", "Triangle", "Square", "Diamond", "Star"]
const FIELDS := ["Healing", "Agriculture", "Construction", "Weather", "Combat"]
const FIELD_CORE := {
    "Healing": 1,
    "Agriculture": 2,
    "Construction": 3,
    "Weather": 4,
    "Combat": 5,
}
const FIELD_JP := {
    "Healing": "治癒",
    "Agriculture": "農耕",
    "Construction": "構築",
    "Weather": "気象",
    "Combat": "戦闘",
}

const GLYPH_POWER := [0, 1, 4, 1, 2, 5]
const GLYPH_RANGE := [0, 3, 1, 2, 4, 3]
const GLYPH_STABILITY := [0, 3, -1, 4, 2, -2]
const GLYPH_DURATION := [0, 1, 0, 3, 2, 2]
const GLYPH_COST := [0, 2, 3, 2, 2, 5]
const GLYPH_EFFICIENCY := [0, 1, 0, 1, 3, 0]

const COLOR_INK := Color("e9e5ff")
const COLOR_MUTED := Color("9993b7")
const COLOR_GOLD := Color("dcb56f")
const COLOR_VIOLET := Color("9a61ff")
const COLOR_PANEL := Color("111126")
const COLOR_PANEL_ALT := Color("171631")
const COLOR_BORDER := Color("4b3d6c")

var research_level := 0
var glyph_states: Array[int] = []
var buttons: Array[Button] = []
var current_field := "Healing"
var requirements: Dictionary = {}

var title_label: Label
var field_label: Label
var challenge_label: Label
var profile_label: Label
var status_label: Label
var circle_stage: Control
var circle_visual: Control
var attempt_button: Button
var reset_button: Button

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = true
    mouse_filter = Control.MOUSE_FILTER_STOP

    var outer := PanelContainer.new()
    outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    outer.add_theme_stylebox_override("panel", _panel_style(COLOR_PANEL, COLOR_BORDER, 22, 1))
    add_child(outer)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 18)
    margin.add_theme_constant_override("margin_right", 18)
    margin.add_theme_constant_override("margin_top", 16)
    margin.add_theme_constant_override("margin_bottom", 16)
    outer.add_child(margin)

    var root_box := VBoxContainer.new()
    root_box.add_theme_constant_override("separation", 8)
    margin.add_child(root_box)

    title_label = Label.new()
    title_label.text = "ARCANE RESEARCH"
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.add_theme_color_override("font_color", COLOR_GOLD)
    title_label.add_theme_font_size_override("font_size", 13)
    root_box.add_child(title_label)

    field_label = Label.new()
    field_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    field_label.add_theme_color_override("font_color", COLOR_INK)
    field_label.add_theme_font_size_override("font_size", 27)
    root_box.add_child(field_label)

    var challenge_card := PanelContainer.new()
    challenge_card.custom_minimum_size.y = 68
    challenge_card.add_theme_stylebox_override("panel", _panel_style(COLOR_PANEL_ALT, Color(COLOR_VIOLET, 0.38), 14, 1))
    root_box.add_child(challenge_card)

    challenge_label = Label.new()
    challenge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    challenge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    challenge_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    challenge_label.add_theme_color_override("font_color", COLOR_INK)
    challenge_label.add_theme_font_size_override("font_size", 14)
    challenge_card.add_child(challenge_label)

    circle_stage = Control.new()
    circle_stage.custom_minimum_size = Vector2(430, 430)
    circle_stage.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    root_box.add_child(circle_stage)

    circle_visual = MAGIC_VISUAL.new()
    circle_visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    circle_stage.add_child(circle_visual)

    for i in range(9):
        glyph_states.append(0)
        var button := Button.new()
        button.custom_minimum_size = Vector2(60, 60)
        button.size = Vector2(60, 60)
        button.text = str(GLYPHS[0])
        button.focus_mode = Control.FOCUS_NONE
        button.add_theme_font_size_override("font_size", 27)
        button.add_theme_color_override("font_color", COLOR_INK)
        button.add_theme_color_override("font_hover_color", Color.WHITE)
        button.add_theme_stylebox_override("normal", _glyph_style(i, false))
        button.add_theme_stylebox_override("hover", _glyph_style(i, true))
        button.add_theme_stylebox_override("pressed", _glyph_style(i, true))
        button.tooltip_text = _slot_tooltip(i)
        button.pressed.connect(_cycle_glyph.bind(i))
        buttons.append(button)
        circle_stage.add_child(button)

    circle_stage.resized.connect(_layout_glyph_buttons)
    call_deferred("_layout_glyph_buttons")

    var metrics_card := PanelContainer.new()
    metrics_card.custom_minimum_size.y = 54
    metrics_card.add_theme_stylebox_override("panel", _panel_style(Color("0c0c20"), Color(COLOR_GOLD, 0.22), 12, 1))
    root_box.add_child(metrics_card)

    profile_label = Label.new()
    profile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    profile_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    profile_label.add_theme_color_override("font_color", COLOR_INK)
    profile_label.add_theme_font_size_override("font_size", 14)
    metrics_card.add_child(profile_label)

    var button_row := HBoxContainer.new()
    button_row.alignment = BoxContainer.ALIGNMENT_CENTER
    button_row.add_theme_constant_override("separation", 10)
    root_box.add_child(button_row)

    reset_button = Button.new()
    reset_button.text = "術式を消去"
    reset_button.custom_minimum_size = Vector2(148, 48)
    reset_button.focus_mode = Control.FOCUS_NONE
    reset_button.add_theme_font_size_override("font_size", 14)
    reset_button.add_theme_color_override("font_color", COLOR_MUTED)
    reset_button.add_theme_stylebox_override("normal", _panel_style(Color("111126"), Color(COLOR_BORDER, 0.8), 12, 1))
    reset_button.add_theme_stylebox_override("hover", _panel_style(Color("191735"), Color(COLOR_VIOLET, 0.55), 12, 1))
    reset_button.pressed.connect(_reset_circle)
    button_row.add_child(reset_button)

    attempt_button = Button.new()
    attempt_button.text = "術式を確定"
    attempt_button.custom_minimum_size = Vector2(220, 52)
    attempt_button.focus_mode = Control.FOCUS_NONE
    attempt_button.add_theme_font_size_override("font_size", 16)
    attempt_button.add_theme_color_override("font_color", Color("171020"))
    attempt_button.add_theme_stylebox_override("normal", _panel_style(COLOR_GOLD, Color("f4d99e"), 13, 1))
    attempt_button.add_theme_stylebox_override("hover", _panel_style(Color("f0cb82"), Color.WHITE, 13, 1))
    attempt_button.add_theme_stylebox_override("pressed", _panel_style(Color("c9964b"), Color("f4d99e"), 13, 1))
    attempt_button.pressed.connect(_attempt_breakthrough)
    button_row.add_child(attempt_button)

    status_label = Label.new()
    status_label.custom_minimum_size.y = 42
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.add_theme_color_override("font_color", COLOR_MUTED)
    status_label.add_theme_font_size_override("font_size", 13)
    root_box.add_child(status_label)

    _make_challenge()
    _refresh_all()

func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_R:
            _reset_circle()
            get_viewport().set_input_as_handled()
        elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
            _attempt_breakthrough()
            get_viewport().set_input_as_handled()

func toggle() -> void:
    visible = not visible
    if visible:
        status_label.text = ""
        _refresh_all()

func close() -> void:
    visible = false

func get_current_field() -> String:
    return current_field

func get_circle_profile() -> Dictionary:
    var power := 0
    var reach := 0
    var stability := 0
    var duration := 0
    var raw_cost := 0
    var efficiency := 0
    var active_glyphs := 0

    for i in range(glyph_states.size()):
        var state: int = glyph_states[i]
        if state <= 0:
            continue
        active_glyphs += 1
        raw_cost += int(GLYPH_COST[state])

        if i == 4:
            power += int(GLYPH_POWER[state]) * 2
            stability += int(GLYPH_STABILITY[state])
            duration += int(GLYPH_DURATION[state])
        elif _is_corner(i):
            reach += int(GLYPH_RANGE[state]) * 2
            stability += int(GLYPH_STABILITY[state])
            efficiency += int(GLYPH_EFFICIENCY[state])
        else:
            power += int(GLYPH_POWER[state])
            duration += int(GLYPH_DURATION[state]) * 2
            stability += int(GLYPH_STABILITY[state])
            efficiency += int(GLYPH_EFFICIENCY[state])

    var opposite_pairs: Array[Array] = [[0, 8], [2, 6], [1, 7], [3, 5]]
    for pair in opposite_pairs:
        var first_index: int = int(pair[0])
        var second_index: int = int(pair[1])
        var first_state: int = glyph_states[first_index]
        if first_state > 0 and first_state == glyph_states[second_index]:
            stability += 3
            efficiency += 1

    var mana_cost: int = maxi(1, raw_cost - efficiency)
    var expected_core: int = int(FIELD_CORE.get(current_field, 0))
    var aligned: bool = glyph_states[4] == expected_core

    return {
        "power": power,
        "range": reach,
        "stability": stability,
        "duration": duration,
        "mana_cost": mana_cost,
        "active_glyphs": active_glyphs,
        "aligned": aligned,
    }

func _cycle_glyph(index: int) -> void:
    glyph_states[index] = (glyph_states[index] + 1) % GLYPHS.size()
    buttons[index].text = str(GLYPHS[glyph_states[index]])
    status_label.text = ""
    _refresh_profile()
    _sync_circle_visual()

func _attempt_breakthrough() -> void:
    var profile: Dictionary = get_circle_profile()
    var failures: Array[String] = _failure_reasons(profile)
    if failures.is_empty():
        var completed_field := current_field
        research_level += 1
        status_label.add_theme_color_override("font_color", COLOR_GOLD)
        status_label.text = "%s術式が安定した。研究記録 Lv.%d" % [_field_jp(completed_field), research_level]
        circle_visual.celebrate()
        research_completed.emit(research_level, completed_field)
        _reset_circle()
        _make_challenge()
        _refresh_all()
        return

    status_label.add_theme_color_override("font_color", Color("cf8aa9"))
    status_label.text = "術式崩壊：" + " / ".join(failures)

func _failure_reasons(profile: Dictionary) -> Array[String]:
    var failures: Array[String] = []
    if not bool(profile.get("aligned", false)):
        failures.append("中心核が不一致")
    if int(profile.get("power", 0)) < int(requirements.get("power", 0)):
        failures.append("出力不足")
    if int(profile.get("range", 0)) < int(requirements.get("range", 0)):
        failures.append("範囲不足")
    if int(profile.get("stability", 0)) < int(requirements.get("stability", 0)):
        failures.append("安定性不足")
    if int(profile.get("duration", 0)) < int(requirements.get("duration", 0)):
        failures.append("持続不足")
    if int(profile.get("mana_cost", 999)) > int(requirements.get("max_mana", 999)):
        failures.append("魔力消費過多")
    if int(profile.get("active_glyphs", 0)) < int(requirements.get("min_glyphs", 0)):
        failures.append("術式が未完成")
    return failures

func _make_challenge() -> void:
    current_field = str(FIELDS[research_level % FIELDS.size()])
    var tier: int = int(research_level / FIELDS.size())

    match current_field:
        "Healing":
            requirements = {"power": 6 + tier * 2, "range": 6 + tier, "stability": 12 + tier * 2, "duration": 4 + tier, "max_mana": 27 + tier * 2, "min_glyphs": 5}
        "Agriculture":
            requirements = {"power": 5 + tier, "range": 14 + tier * 2, "stability": 8 + tier * 2, "duration": 8 + tier, "max_mana": 29 + tier * 2, "min_glyphs": 6}
        "Construction":
            requirements = {"power": 7 + tier * 2, "range": 8 + tier, "stability": 15 + tier * 2, "duration": 6 + tier, "max_mana": 28 + tier * 2, "min_glyphs": 6}
        "Weather":
            requirements = {"power": 8 + tier * 2, "range": 16 + tier * 2, "stability": 7 + tier, "duration": 8 + tier * 2, "max_mana": 31 + tier * 2, "min_glyphs": 7}
        "Combat":
            requirements = {"power": 15 + tier * 2, "range": 8 + tier, "stability": 5 + tier, "duration": 3 + tier, "max_mana": 33 + tier * 2, "min_glyphs": 6}

func _refresh_all() -> void:
    field_label.text = "%s術式  ·  RESEARCH %02d" % [_field_jp(current_field), research_level + 1]
    var core_index: int = int(FIELD_CORE.get(current_field, 0))
    challenge_label.text = "中心核 %s   ｜   出力 ≥ %d   範囲 ≥ %d   安定 ≥ %d\n持続 ≥ %d   魔力 ≤ %d   使用紋章 ≥ %d" % [
        str(GLYPHS[core_index]),
        int(requirements.get("power", 0)),
        int(requirements.get("range", 0)),
        int(requirements.get("stability", 0)),
        int(requirements.get("duration", 0)),
        int(requirements.get("max_mana", 0)),
        int(requirements.get("min_glyphs", 0)),
    ]
    for i in range(buttons.size()):
        buttons[i].text = str(GLYPHS[glyph_states[i]])
    _refresh_profile()
    _sync_circle_visual()

func _refresh_profile() -> void:
    var profile: Dictionary = get_circle_profile()
    var alignment_text := "核✓" if bool(profile.get("aligned", false)) else "核×"
    profile_label.text = "P %02d    R %02d    S %02d    D %02d    M %02d    %s" % [
        int(profile.get("power", 0)),
        int(profile.get("range", 0)),
        int(profile.get("stability", 0)),
        int(profile.get("duration", 0)),
        int(profile.get("mana_cost", 0)),
        alignment_text,
    ]

func _reset_circle() -> void:
    for i in range(glyph_states.size()):
        glyph_states[i] = 0
        if i < buttons.size():
            buttons[i].text = str(GLYPHS[0])
    if status_label != null:
        status_label.add_theme_color_override("font_color", COLOR_MUTED)
    if profile_label != null:
        _refresh_profile()
    _sync_circle_visual()

func _sync_circle_visual() -> void:
    if circle_visual != null:
        circle_visual.set_state(glyph_states, current_field)

func _layout_glyph_buttons() -> void:
    if circle_visual == null or buttons.size() != 9:
        return
    for i in range(buttons.size()):
        var center: Vector2 = circle_visual.get_slot_position(i)
        buttons[i].position = center - buttons[i].size * 0.5

func _is_corner(index: int) -> bool:
    return index == 0 or index == 2 or index == 6 or index == 8

func _slot_tooltip(index: int) -> String:
    if index == 4:
        return "中心核：魔法分野を決め、出力へ強く影響する。"
    if _is_corner(index):
        return "境界紋：主に範囲と封じ込めを決める。"
    return "導流紋：主に出力、持続、魔力流を決める。"

func _field_jp(field_name: String) -> String:
    return str(FIELD_JP.get(field_name, field_name))

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
    style.content_margin_top = 7.0
    style.content_margin_bottom = 7.0
    return style

func _glyph_style(index: int, highlighted: bool) -> StyleBoxFlat:
    var role_color := COLOR_GOLD if _is_corner(index) else COLOR_VIOLET
    if index == 4:
        role_color = Color("e9e5ff")
    var bg := Color("18162f") if not highlighted else Color("2b2350")
    var border := Color(role_color, 0.48 if not highlighted else 0.92)
    var style := _panel_style(bg, border, 30, 1 if not highlighted else 2)
    style.shadow_color = Color(role_color, 0.13 if not highlighted else 0.28)
    style.shadow_size = 8 if highlighted else 4
    return style
