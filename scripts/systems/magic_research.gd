class_name MagicResearchPanel
extends Control

signal research_completed(level: int, field_name: String)

const MAGIC_VISUAL := preload("res://scripts/ui/magic_circle_visual.gd")

const GLYPH_NAMES := ["Empty", "Circle", "Triangle", "Square", "Diamond", "Star"]
const GLYPH_JP := ["空", "円", "三角", "四角", "菱形", "星"]
const ORIENTATION_NAMES := ["OUT", "CLOCKWISE", "IN", "COUNTER"]
const ORIENTATION_JP := ["外向", "順流", "内向", "逆流"]
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
const COLOR_MUTED := Color("aaa4c4")
const COLOR_GOLD := Color("dcb56f")
const COLOR_VIOLET := Color("9a61ff")
const COLOR_PANEL := Color("111126")
const COLOR_PANEL_ALT := Color("171631")
const COLOR_BORDER := Color("4b3d6c")
const DRAG_THRESHOLD := 18.0
const SLOT_HIT_RADIUS := 52.0

var research_level := 0
var glyph_states: Array[int] = []
var glyph_rotations: Array[int] = []
var connections: Array[Vector2i] = []
var buttons: Array[Button] = []
var current_field := "Healing"
var requirements: Dictionary = {}
var village_request: Dictionary = {}
var japanese_ui := true
var selected_slot := -1

var drag_source := -1
var drag_active := false
var drag_start := Vector2.ZERO
var drag_pointer := Vector2.ZERO

var title_label: Label
var field_label: Label
var request_label: Label
var challenge_label: Label
var profile_label: Label
var status_label: Label
var circle_stage: Control
var circle_visual
var attempt_button: Button
var reset_button: Button
var glyph_picker: PanelContainer
var glyph_picker_title: Label
var glyph_picker_buttons: Array[Button] = []
var rotation_label: Label

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = true
    mouse_filter = Control.MOUSE_FILTER_STOP

    var outer := PanelContainer.new()
    outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    outer.add_theme_stylebox_override("panel", _panel_style(COLOR_PANEL, COLOR_BORDER, 22, 1))
    add_child(outer)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 16)
    margin.add_theme_constant_override("margin_right", 16)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_bottom", 12)
    outer.add_child(margin)

    var root_box := VBoxContainer.new()
    root_box.add_theme_constant_override("separation", 7)
    margin.add_child(root_box)

    title_label = Label.new()
    title_label.text = _ui("魔法研究", "ARCANE RESEARCH")
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.add_theme_color_override("font_color", COLOR_GOLD)
    title_label.add_theme_font_size_override("font_size", 15)
    root_box.add_child(title_label)

    field_label = Label.new()
    field_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    field_label.add_theme_color_override("font_color", COLOR_INK)
    field_label.add_theme_font_size_override("font_size", 30)
    root_box.add_child(field_label)

    var challenge_card := PanelContainer.new()
    challenge_card.custom_minimum_size.y = 126
    challenge_card.add_theme_stylebox_override("panel", _panel_style(COLOR_PANEL_ALT, Color(COLOR_VIOLET, 0.42), 14, 1))
    root_box.add_child(challenge_card)

    var challenge_box := VBoxContainer.new()
    challenge_box.alignment = BoxContainer.ALIGNMENT_CENTER
    challenge_box.add_theme_constant_override("separation", 3)
    challenge_card.add_child(challenge_box)

    request_label = Label.new()
    request_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    request_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    request_label.add_theme_color_override("font_color", COLOR_GOLD)
    request_label.add_theme_font_size_override("font_size", 15)
    challenge_box.add_child(request_label)

    challenge_label = Label.new()
    challenge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    challenge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    challenge_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    challenge_label.add_theme_color_override("font_color", COLOR_INK)
    challenge_label.add_theme_font_size_override("font_size", 16)
    challenge_box.add_child(challenge_label)

    circle_stage = Control.new()
    circle_stage.custom_minimum_size = Vector2(500, 500)
    circle_stage.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    root_box.add_child(circle_stage)

    circle_visual = MAGIC_VISUAL.new()
    circle_visual.z_index = 3
    circle_visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    circle_stage.add_child(circle_visual)

    for i in range(9):
        glyph_states.append(0)
        glyph_rotations.append(0)
        var button := Button.new()
        button.z_index = 4
        button.custom_minimum_size = Vector2(82, 82)
        button.size = Vector2(82, 82)
        button.text = ""
        button.focus_mode = Control.FOCUS_NONE
        button.tooltip_text = _slot_tooltip(i)
        button.pressed.connect(_open_glyph_picker.bind(i))
        buttons.append(button)
        circle_stage.add_child(button)

    circle_stage.resized.connect(_layout_glyph_buttons)
    call_deferred("_layout_glyph_buttons")

    var metrics_card := PanelContainer.new()
    metrics_card.custom_minimum_size.y = 62
    metrics_card.add_theme_stylebox_override("panel", _panel_style(Color("0c0c20"), Color(COLOR_GOLD, 0.28), 12, 1))
    root_box.add_child(metrics_card)

    profile_label = Label.new()
    profile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    profile_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    profile_label.add_theme_color_override("font_color", COLOR_INK)
    profile_label.add_theme_font_size_override("font_size", 18)
    metrics_card.add_child(profile_label)

    var button_row := HBoxContainer.new()
    button_row.alignment = BoxContainer.ALIGNMENT_CENTER
    button_row.add_theme_constant_override("separation", 12)
    root_box.add_child(button_row)

    reset_button = Button.new()
    reset_button.text = _ui("消去", "CLEAR")
    reset_button.custom_minimum_size = Vector2(160, 56)
    reset_button.focus_mode = Control.FOCUS_NONE
    reset_button.add_theme_font_size_override("font_size", 18)
    reset_button.add_theme_color_override("font_color", COLOR_MUTED)
    reset_button.add_theme_stylebox_override("normal", _panel_style(Color("111126"), Color(COLOR_BORDER, 0.9), 13, 1))
    reset_button.add_theme_stylebox_override("hover", _panel_style(Color("191735"), Color(COLOR_VIOLET, 0.65), 13, 1))
    reset_button.pressed.connect(_reset_circle)
    button_row.add_child(reset_button)

    attempt_button = Button.new()
    attempt_button.text = _ui("術式を確定", "STABILIZE")
    attempt_button.custom_minimum_size = Vector2(246, 58)
    attempt_button.focus_mode = Control.FOCUS_NONE
    attempt_button.add_theme_font_size_override("font_size", 19)
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
    status_label.add_theme_font_size_override("font_size", 15)
    root_box.add_child(status_label)

    _build_glyph_picker()
    _make_challenge()
    _refresh_all()

func set_village_request(request: Dictionary, refresh_now: bool = true) -> void:
    village_request = request.duplicate(true)
    if refresh_now and is_node_ready():
        _make_challenge()
        _refresh_all()

func _build_glyph_picker() -> void:
    glyph_picker = PanelContainer.new()
    glyph_picker.visible = false
    glyph_picker.z_index = 30
    glyph_picker.anchor_left = 0.03
    glyph_picker.anchor_right = 0.97
    glyph_picker.anchor_top = 1.0
    glyph_picker.anchor_bottom = 1.0
    glyph_picker.offset_top = -224.0
    glyph_picker.offset_bottom = -10.0
    glyph_picker.add_theme_stylebox_override("panel", _panel_style(Color("17152f"), Color(COLOR_GOLD, 0.82), 18, 2))
    add_child(glyph_picker)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 14)
    margin.add_theme_constant_override("margin_right", 14)
    margin.add_theme_constant_override("margin_top", 10)
    margin.add_theme_constant_override("margin_bottom", 12)
    glyph_picker.add_child(margin)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 8)
    margin.add_child(box)

    glyph_picker_title = Label.new()
    glyph_picker_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    glyph_picker_title.add_theme_color_override("font_color", COLOR_GOLD)
    glyph_picker_title.add_theme_font_size_override("font_size", 17)
    box.add_child(glyph_picker_title)

    var row := HBoxContainer.new()
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.add_theme_constant_override("separation", 7)
    box.add_child(row)

    for state in range(GLYPH_NAMES.size()):
        var option := Button.new()
        option.text = _glyph_name(state)
        option.custom_minimum_size = Vector2(92, 58)
        option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        option.focus_mode = Control.FOCUS_NONE
        option.add_theme_font_size_override("font_size", 15)
        option.pressed.connect(_choose_glyph.bind(state))
        glyph_picker_buttons.append(option)
        row.add_child(option)

    var rotate_row := HBoxContainer.new()
    rotate_row.alignment = BoxContainer.ALIGNMENT_CENTER
    rotate_row.add_theme_constant_override("separation", 10)
    box.add_child(rotate_row)

    var rotate_left := Button.new()
    rotate_left.text = _ui("左へ90°", "ROTATE -90")
    rotate_left.custom_minimum_size = Vector2(160, 48)
    rotate_left.focus_mode = Control.FOCUS_NONE
    rotate_left.add_theme_font_size_override("font_size", 15)
    rotate_left.pressed.connect(_rotate_selected.bind(-1))
    rotate_row.add_child(rotate_left)

    rotation_label = Label.new()
    rotation_label.custom_minimum_size = Vector2(155, 48)
    rotation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    rotation_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    rotation_label.add_theme_color_override("font_color", COLOR_INK)
    rotation_label.add_theme_font_size_override("font_size", 15)
    rotate_row.add_child(rotation_label)

    var rotate_right := Button.new()
    rotate_right.text = _ui("右へ90°", "ROTATE +90")
    rotate_right.custom_minimum_size = Vector2(160, 48)
    rotate_right.focus_mode = Control.FOCUS_NONE
    rotate_right.add_theme_font_size_override("font_size", 15)
    rotate_right.pressed.connect(_rotate_selected.bind(1))
    rotate_row.add_child(rotate_right)

func _input(event: InputEvent) -> void:
    if not visible or circle_stage == null:
        return

    if event is InputEventScreenTouch:
        _handle_pointer_button(event.position, event.pressed)
    elif event is InputEventScreenDrag:
        _handle_pointer_motion(event.position)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        _handle_pointer_button(event.position, event.pressed)
    elif event is InputEventMouseMotion and drag_source >= 0:
        _handle_pointer_motion(event.position)

func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE and glyph_picker != null and glyph_picker.visible:
            _close_glyph_picker()
            get_viewport().set_input_as_handled()
        elif event.keycode == KEY_R:
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

        var orientation: int = glyph_rotations[i] % 4
        match orientation:
            0:
                reach += 1
            1:
                duration += 1
            2:
                stability += 1
                efficiency += 1
            3:
                power += 1

    var active_links := 0
    for link in connections:
        var a: int = link.x
        var b: int = link.y
        if a < 0 or b < 0 or a >= glyph_states.size() or b >= glyph_states.size():
            continue
        if glyph_states[a] <= 0 or glyph_states[b] <= 0:
            continue

        active_links += 1
        raw_cost += 1
        if a == 4 or b == 4:
            power += 2
            stability += 1
        else:
            duration += 1

        if glyph_states[a] == glyph_states[b]:
            stability += 2
            efficiency += 1
        else:
            power += 1

        if _are_opposite(a, b):
            reach += 1

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
        "links": active_links,
        "aligned": aligned,
    }

func _open_glyph_picker(index: int) -> void:
    selected_slot = index
    glyph_picker.visible = true
    if index == 4:
        glyph_picker_title.text = _ui("中心核の紋章を選ぶ", "SELECT CORE GLYPH")
    elif _is_corner(index):
        glyph_picker_title.text = _ui("境界紋を選ぶ", "SELECT BOUNDARY GLYPH")
    else:
        glyph_picker_title.text = _ui("導流紋を選ぶ", "SELECT FLOW GLYPH")
    status_label.text = _slot_tooltip(index)
    _refresh_slot_styles()
    _refresh_picker_styles()

func _choose_glyph(state: int) -> void:
    if selected_slot < 0 or selected_slot >= glyph_states.size():
        return
    var slot: int = selected_slot
    glyph_states[slot] = state
    if state <= 0:
        glyph_rotations[slot] = 0
        _remove_connections_for_slot(slot)
    selected_slot = -1
    glyph_picker.visible = false
    status_label.text = ""
    _refresh_profile()
    _sync_circle_visual()
    _refresh_slot_styles()

func _rotate_selected(step: int) -> void:
    if selected_slot < 0 or selected_slot >= glyph_states.size():
        return
    if glyph_states[selected_slot] <= 0:
        status_label.text = _ui("先に紋章を置いてから回転させる。", "PLACE A GLYPH BEFORE ROTATING IT.")
        return

    var slot: int = selected_slot
    glyph_rotations[slot] = (glyph_rotations[slot] + step + 4) % 4
    selected_slot = -1
    glyph_picker.visible = false
    status_label.text = _ui("紋章の向きを変更した。", "GLYPH ORIENTATION CHANGED.")
    _refresh_profile()
    _sync_circle_visual()
    _refresh_slot_styles()

func _close_glyph_picker() -> void:
    selected_slot = -1
    if glyph_picker != null:
        glyph_picker.visible = false
    _refresh_slot_styles()

func _handle_pointer_button(viewport_position: Vector2, pressed: bool) -> void:
    if pressed:
        if glyph_picker != null and glyph_picker.visible:
            return
        var local: Vector2 = _circle_local_position(viewport_position)
        if not Rect2(Vector2.ZERO, circle_stage.size).has_point(local):
            drag_source = -1
            return
        var slot: int = _slot_at_local_position(local)
        if slot >= 0 and glyph_states[slot] > 0:
            drag_source = slot
            drag_start = local
            drag_pointer = local
            drag_active = false
        else:
            drag_source = -1
        return

    if drag_source < 0:
        return

    var local: Vector2 = _circle_local_position(viewport_position)
    var target: int = _slot_at_local_position(local)
    if drag_active:
        if target >= 0 and target != drag_source and glyph_states[target] > 0:
            _toggle_connection(drag_source, target)
        else:
            status_label.text = _ui("接続をキャンセルした。", "LINK CANCELLED.")
        get_viewport().set_input_as_handled()

    drag_source = -1
    drag_active = false
    if circle_visual != null:
        circle_visual.set_mana_drag_preview(-1, Vector2.ZERO, false)

func _handle_pointer_motion(viewport_position: Vector2) -> void:
    if drag_source < 0:
        return
    var local: Vector2 = _circle_local_position(viewport_position)
    drag_pointer = local
    if not drag_active and drag_start.distance_to(local) >= DRAG_THRESHOLD:
        drag_active = true
        status_label.text = _ui("別の紋章まで指を運ぶと魔力線を接続する。", "DRAG TO ANOTHER GLYPH TO WIRE A MANA LINK.")

    if drag_active:
        if circle_visual != null:
            circle_visual.set_mana_drag_preview(drag_source, drag_pointer, true)
        get_viewport().set_input_as_handled()

func _toggle_connection(first: int, second: int) -> void:
    if first == second:
        return
    if first < 0 or second < 0 or first >= glyph_states.size() or second >= glyph_states.size():
        return
    if glyph_states[first] <= 0 or glyph_states[second] <= 0:
        return

    var link := _normalized_link(first, second)
    var index: int = connections.find(link)
    if index >= 0:
        connections.remove_at(index)
        status_label.text = _ui("魔力線を解除した。", "MANA LINK REMOVED.")
    else:
        connections.append(link)
        status_label.text = _ui("魔力線を接続した。", "MANA LINK CONNECTED.")
    _refresh_profile()
    _sync_circle_visual()
    _refresh_slot_styles()

func _attempt_breakthrough() -> void:
    _close_glyph_picker()
    var profile: Dictionary = get_circle_profile()
    var failures: Array[String] = _failure_reasons(profile)
    if failures.is_empty():
        var completed_field: String = current_field
        research_level += 1
        status_label.add_theme_color_override("font_color", COLOR_GOLD)
        if japanese_ui:
            status_label.text = "%s術式が安定した。研究記録 Lv.%d" % [_field_jp(completed_field), research_level]
        else:
            status_label.text = "%s circle stabilized. Research Lv.%d" % [completed_field, research_level]
        circle_visual.celebrate()
        research_completed.emit(research_level, completed_field)
        _reset_circle()
        _make_challenge()
        _refresh_all()
        return

    status_label.add_theme_color_override("font_color", Color("e89ab8"))
    status_label.text = _ui("術式崩壊: ", "COLLAPSE: ") + " / ".join(failures)

func _failure_reasons(profile: Dictionary) -> Array[String]:
    var failures: Array[String] = []
    if not bool(profile.get("aligned", false)):
        failures.append(_ui("中心核不一致", "WRONG CORE"))
    if int(profile.get("power", 0)) < int(requirements.get("power", 0)):
        failures.append(_ui("出力不足", "LOW POWER"))
    if int(profile.get("range", 0)) < int(requirements.get("range", 0)):
        failures.append(_ui("範囲不足", "LOW RANGE"))
    if int(profile.get("stability", 0)) < int(requirements.get("stability", 0)):
        failures.append(_ui("安定性不足", "LOW STABILITY"))
    if int(profile.get("duration", 0)) < int(requirements.get("duration", 0)):
        failures.append(_ui("持続不足", "LOW DURATION"))
    if int(profile.get("mana_cost", 999)) > int(requirements.get("max_mana", 999)):
        failures.append(_ui("魔力消費過多", "MANA TOO HIGH"))
    if int(profile.get("active_glyphs", 0)) < int(requirements.get("min_glyphs", 0)):
        failures.append(_ui("術式未完成", "INCOMPLETE"))
    if int(profile.get("links", 0)) < int(requirements.get("min_links", 0)):
        failures.append(_ui("魔力線不足", "NOT ENOUGH LINKS"))
    return failures

func _make_challenge() -> void:
    if village_request.has("field"):
        current_field = str(village_request.get("field", "Healing"))
    else:
        current_field = str(FIELDS[research_level % FIELDS.size()])
    if not FIELD_CORE.has(current_field):
        current_field = "Healing"

    var tier: int = int(research_level / FIELDS.size())

    match current_field:
        "Healing":
            requirements = {"power": 6 + tier * 2, "range": 6 + tier, "stability": 12 + tier * 2, "duration": 4 + tier, "max_mana": 27 + tier * 2, "min_glyphs": 5, "min_links": 2}
        "Agriculture":
            requirements = {"power": 5 + tier, "range": 14 + tier * 2, "stability": 8 + tier * 2, "duration": 8 + tier, "max_mana": 29 + tier * 2, "min_glyphs": 6, "min_links": 3}
        "Construction":
            requirements = {"power": 7 + tier * 2, "range": 8 + tier, "stability": 15 + tier * 2, "duration": 6 + tier, "max_mana": 28 + tier * 2, "min_glyphs": 6, "min_links": 3}
        "Weather":
            requirements = {"power": 8 + tier * 2, "range": 16 + tier * 2, "stability": 7 + tier, "duration": 8 + tier * 2, "max_mana": 31 + tier * 2, "min_glyphs": 7, "min_links": 4}
        "Combat":
            requirements = {"power": 15 + tier * 2, "range": 8 + tier, "stability": 5 + tier, "duration": 3 + tier, "max_mana": 33 + tier * 2, "min_glyphs": 6, "min_links": 3}

func _refresh_all() -> void:
    if japanese_ui:
        field_label.text = "%s術式  |  RESEARCH %02d" % [_field_jp(current_field), research_level + 1]
    else:
        field_label.text = "%s  |  RESEARCH %02d" % [current_field.to_upper(), research_level + 1]

    _refresh_request_text()

    var core_index: int = int(FIELD_CORE.get(current_field, 0))
    var core_name: String = str(GLYPH_JP[core_index]) if japanese_ui else str(GLYPH_NAMES[core_index])
    if japanese_ui:
        challenge_label.text = "中心核: %s   出力 >= %d   範囲 >= %d   安定 >= %d\n持続 >= %d   魔力 <= %d   紋章 >= %d   導線 >= %d" % [
            core_name,
            int(requirements.get("power", 0)),
            int(requirements.get("range", 0)),
            int(requirements.get("stability", 0)),
            int(requirements.get("duration", 0)),
            int(requirements.get("max_mana", 0)),
            int(requirements.get("min_glyphs", 0)),
            int(requirements.get("min_links", 0)),
        ]
    else:
        challenge_label.text = "CORE: %s   P >= %d   R >= %d   S >= %d\nD >= %d   MANA <= %d   GLYPHS >= %d   LINKS >= %d" % [
            core_name,
            int(requirements.get("power", 0)),
            int(requirements.get("range", 0)),
            int(requirements.get("stability", 0)),
            int(requirements.get("duration", 0)),
            int(requirements.get("max_mana", 0)),
            int(requirements.get("min_glyphs", 0)),
            int(requirements.get("min_links", 0)),
        ]
    _refresh_profile()
    _sync_circle_visual()
    _refresh_slot_styles()

func _refresh_request_text() -> void:
    if request_label == null:
        return
    if village_request.is_empty():
        request_label.text = _ui("個人研究  |  魔法体系の基礎を探る", "PERSONAL RESEARCH  |  Explore the foundations of magic")
        request_label.add_theme_color_override("font_color", COLOR_MUTED)
        return

    var title_key: String = "title_jp" if japanese_ui else "title_en"
    var detail_key: String = "detail_jp" if japanese_ui else "detail_en"
    var title: String = str(village_request.get(title_key, _ui("村からの研究依頼", "VILLAGE REQUEST")))
    var detail: String = str(village_request.get(detail_key, ""))
    request_label.text = "%s\n%s" % [title, detail]

    var severity: int = int(village_request.get("severity", 0))
    if severity >= 3:
        request_label.add_theme_color_override("font_color", Color("ef91ab"))
    elif severity >= 2:
        request_label.add_theme_color_override("font_color", Color("f0c27a"))
    else:
        request_label.add_theme_color_override("font_color", COLOR_GOLD)

func _refresh_profile() -> void:
    var profile: Dictionary = get_circle_profile()
    var alignment_text: String
    if bool(profile.get("aligned", false)):
        alignment_text = _ui("核一致", "CORE OK")
    else:
        alignment_text = _ui("核不一致", "CORE X")
    profile_label.text = "P %02d   R %02d   S %02d   D %02d   M %02d   L %02d   %s" % [
        int(profile.get("power", 0)),
        int(profile.get("range", 0)),
        int(profile.get("stability", 0)),
        int(profile.get("duration", 0)),
        int(profile.get("mana_cost", 0)),
        int(profile.get("links", 0)),
        alignment_text,
    ]

func _reset_circle() -> void:
    selected_slot = -1
    drag_source = -1
    drag_active = false
    connections.clear()
    if glyph_picker != null:
        glyph_picker.visible = false
    for i in range(glyph_states.size()):
        glyph_states[i] = 0
        glyph_rotations[i] = 0
    if status_label != null:
        status_label.add_theme_color_override("font_color", COLOR_MUTED)
        status_label.text = ""
    if profile_label != null:
        _refresh_profile()
    _sync_circle_visual()
    _refresh_slot_styles()

func _sync_circle_visual() -> void:
    if circle_visual != null:
        circle_visual.set_state(glyph_states, current_field, glyph_rotations, connections)

func _layout_glyph_buttons() -> void:
    if circle_visual == null or buttons.size() != 9:
        return
    for i in range(buttons.size()):
        var center: Vector2 = circle_visual.get_slot_position(i)
        buttons[i].position = center - buttons[i].size * 0.5

func _refresh_slot_styles() -> void:
    for i in range(buttons.size()):
        var selected: bool = i == selected_slot
        buttons[i].add_theme_stylebox_override("normal", _glyph_style(i, false, selected))
        buttons[i].add_theme_stylebox_override("hover", _glyph_style(i, true, selected))
        buttons[i].add_theme_stylebox_override("pressed", _glyph_style(i, true, selected))

func _refresh_picker_styles() -> void:
    if selected_slot < 0 or selected_slot >= glyph_states.size():
        return
    var current_state: int = glyph_states[selected_slot]
    for state in range(glyph_picker_buttons.size()):
        var active: bool = state == current_state
        var option: Button = glyph_picker_buttons[state]
        option.add_theme_stylebox_override("normal", _picker_style(active, false))
        option.add_theme_stylebox_override("hover", _picker_style(active, true))
        option.add_theme_stylebox_override("pressed", _picker_style(true, true))
        option.add_theme_color_override("font_color", COLOR_GOLD if active else COLOR_INK)

    if rotation_label != null:
        if current_state <= 0:
            rotation_label.text = _ui("向き: --", "ORIENT: --")
        else:
            rotation_label.text = _ui(
                "向き: %s" % ORIENTATION_JP[glyph_rotations[selected_slot] % 4],
                "ORIENT: %s" % ORIENTATION_NAMES[glyph_rotations[selected_slot] % 4]
            )

func _circle_local_position(viewport_position: Vector2) -> Vector2:
    return circle_stage.get_global_transform_with_canvas().affine_inverse() * viewport_position

func _slot_at_local_position(local_position: Vector2) -> int:
    if circle_visual == null:
        return -1
    var best := -1
    var best_distance := SLOT_HIT_RADIUS
    for i in range(9):
        var distance: float = local_position.distance_to(circle_visual.get_slot_position(i))
        if distance <= best_distance:
            best = i
            best_distance = distance
    return best

func _normalized_link(first: int, second: int) -> Vector2i:
    return Vector2i(mini(first, second), maxi(first, second))

func _remove_connections_for_slot(slot: int) -> void:
    for index in range(connections.size() - 1, -1, -1):
        var link: Vector2i = connections[index]
        if link.x == slot or link.y == slot:
            connections.remove_at(index)

func _slot_connection_count(slot: int) -> int:
    var count := 0
    for link in connections:
        if link.x == slot or link.y == slot:
            count += 1
    return count

func _are_opposite(first: int, second: int) -> bool:
    var link := _normalized_link(first, second)
    return link == Vector2i(0, 8) or link == Vector2i(2, 6) or link == Vector2i(1, 7) or link == Vector2i(3, 5)

func _is_corner(index: int) -> bool:
    return index == 0 or index == 2 or index == 6 or index == 8

func _slot_tooltip(index: int) -> String:
    if index == 4:
        return _ui("中心核: 魔法分野と主出力。回転で流れを調整し、他の紋章へドラッグして接続する。", "Core: magic field and main output. Rotate it or drag to another glyph to wire it.")
    if _is_corner(index):
        return _ui("境界紋: 主に範囲と封じ込め。回転と魔力線で性能が変わる。", "Boundary: mainly range and containment. Rotation and links change its behavior.")
    return _ui("導流紋: 主に出力、持続、魔力流。別の紋章へドラッグして接続する。", "Flow: mainly power, duration and mana flow. Drag it to another glyph to connect.")

func _glyph_name(state: int) -> String:
    if state < 0 or state >= GLYPH_NAMES.size():
        return "?"
    return str(GLYPH_JP[state]) if japanese_ui else str(GLYPH_NAMES[state]).to_upper()

func _ui(japanese: String, english: String) -> String:
    return japanese if japanese_ui else english

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

func _glyph_style(index: int, highlighted: bool, selected: bool = false) -> StyleBoxFlat:
    var role_color: Color = COLOR_GOLD if _is_corner(index) else COLOR_VIOLET
    if index == 4:
        role_color = Color("e9e5ff")
    var bg: Color = Color("17152f")
    if highlighted:
        bg = Color("2d2454")
    if selected:
        bg = Color("38295f")
    bg.a = 0.94
    var linked: bool = _slot_connection_count(index) > 0
    var border_alpha: float = 1.0 if selected or highlighted or linked else 0.55
    var border: Color = Color(role_color, border_alpha)
    var width: int = 3 if selected else (2 if highlighted or linked else 1)
    var style := _panel_style(bg, border, 41, width)
    style.shadow_color = Color(role_color, 0.40 if selected else (0.34 if highlighted or linked else 0.18))
    style.shadow_size = 12 if selected else (10 if highlighted or linked else 5)
    return style

func _picker_style(active: bool, highlighted: bool) -> StyleBoxFlat:
    var bg: Color = Color("2a2148") if active else Color("101024")
    if highlighted:
        bg = Color("34275b")
    var border: Color = Color(COLOR_GOLD, 0.95) if active else Color(COLOR_VIOLET, 0.48 if not highlighted else 0.82)
    return _panel_style(bg, border, 12, 2 if active or highlighted else 1)
