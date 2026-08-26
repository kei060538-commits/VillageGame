class_name MagicResearchPanel
extends Control

signal research_completed(level: int, field_name: String)

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

const GLYPH_POWER := [0, 1, 4, 1, 2, 5]
const GLYPH_RANGE := [0, 3, 1, 2, 4, 3]
const GLYPH_STABILITY := [0, 3, -1, 4, 2, -2]
const GLYPH_DURATION := [0, 1, 0, 3, 2, 2]
const GLYPH_COST := [0, 2, 3, 2, 2, 5]
const GLYPH_EFFICIENCY := [0, 1, 0, 1, 3, 0]

var research_level := 0
var glyph_states: Array[int] = []
var buttons: Array[Button] = []
var current_field := "Healing"
var requirements: Dictionary = {}

var title_label: Label
var challenge_label: Label
var profile_label: Label
var status_label: Label

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    visible = false
    set_anchors_preset(Control.PRESET_CENTER)
    offset_left = -290.0
    offset_top = -330.0
    offset_right = 290.0
    offset_bottom = 330.0

    var panel := PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(panel)

    var root_box := VBoxContainer.new()
    root_box.add_theme_constant_override("separation", 8)
    panel.add_child(root_box)

    title_label = Label.new()
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.add_theme_font_size_override("font_size", 20)
    root_box.add_child(title_label)

    var help := Label.new()
    help.text = "Corners define the boundary, edges control mana flow, and the center defines the magical field.\nDifferent circles can satisfy the same theory. Press E to leave the tower."
    help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    root_box.add_child(help)

    challenge_label = Label.new()
    challenge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    challenge_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    root_box.add_child(challenge_label)

    var grid := GridContainer.new()
    grid.columns = 3
    grid.custom_minimum_size = Vector2(330, 330)
    grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    root_box.add_child(grid)

    for i in range(9):
        glyph_states.append(0)
        var button := Button.new()
        button.custom_minimum_size = Vector2(102, 102)
        button.text = str(GLYPHS[0])
        button.add_theme_font_size_override("font_size", 30)
        button.tooltip_text = _slot_tooltip(i)
        button.pressed.connect(_cycle_glyph.bind(i))
        buttons.append(button)
        grid.add_child(button)

    profile_label = Label.new()
    profile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    root_box.add_child(profile_label)

    var button_row := HBoxContainer.new()
    button_row.alignment = BoxContainer.ALIGNMENT_CENTER
    root_box.add_child(button_row)

    var attempt_button := Button.new()
    attempt_button.text = "Attempt breakthrough"
    attempt_button.pressed.connect(_attempt_breakthrough)
    button_row.add_child(attempt_button)

    var reset_button := Button.new()
    reset_button.text = "Erase circle"
    reset_button.pressed.connect(_reset_circle)
    button_row.add_child(reset_button)

    status_label = Label.new()
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    root_box.add_child(status_label)

    _make_challenge()
    _refresh_all()

func _unhandled_input(event: InputEvent) -> void:
    if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
        close()
        get_viewport().set_input_as_handled()

func toggle() -> void:
    visible = not visible
    get_tree().paused = visible
    if visible:
        status_label.text = ""
        _refresh_all()

func close() -> void:
    visible = false
    get_tree().paused = false

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

func _attempt_breakthrough() -> void:
    var profile: Dictionary = get_circle_profile()
    var failures: Array[String] = _failure_reasons(profile)
    if failures.is_empty():
        var completed_field := current_field
        research_level += 1
        status_label.text = "Breakthrough: %s theory stabilized at research level %d." % [completed_field, research_level]
        research_completed.emit(research_level, completed_field)
        _reset_circle()
        _make_challenge()
        _refresh_all()
        return

    status_label.text = "The circle collapses: " + "; ".join(failures)

func _failure_reasons(profile: Dictionary) -> Array[String]:
    var failures: Array[String] = []
    if not bool(profile.get("aligned", false)):
        failures.append("wrong core geometry for %s" % current_field)
    if int(profile.get("power", 0)) < int(requirements.get("power", 0)):
        failures.append("power is too low")
    if int(profile.get("range", 0)) < int(requirements.get("range", 0)):
        failures.append("range is too small")
    if int(profile.get("stability", 0)) < int(requirements.get("stability", 0)):
        failures.append("stability is too low")
    if int(profile.get("duration", 0)) < int(requirements.get("duration", 0)):
        failures.append("duration is too short")
    if int(profile.get("mana_cost", 999)) > int(requirements.get("max_mana", 999)):
        failures.append("mana cost is too high")
    if int(profile.get("active_glyphs", 0)) < int(requirements.get("min_glyphs", 0)):
        failures.append("the circle is incomplete")
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
    title_label.text = "Magic Circle Research  Lv.%d" % research_level
    var core_index: int = int(FIELD_CORE.get(current_field, 0))
    var core_name: String = str(GLYPH_NAMES[core_index])
    challenge_label.text = "%s theory | Core: %s %s\nNeed  P≥%d  R≥%d  S≥%d  D≥%d  Mana≤%d" % [
        current_field,
        str(GLYPHS[core_index]),
        core_name,
        int(requirements.get("power", 0)),
        int(requirements.get("range", 0)),
        int(requirements.get("stability", 0)),
        int(requirements.get("duration", 0)),
        int(requirements.get("max_mana", 0)),
    ]
    for i in range(buttons.size()):
        buttons[i].text = str(GLYPHS[glyph_states[i]])
    _refresh_profile()

func _refresh_profile() -> void:
    var profile: Dictionary = get_circle_profile()
    var alignment_text := "aligned" if bool(profile.get("aligned", false)) else "misaligned"
    profile_label.text = "Current circle: P %d | R %d | S %d | D %d | Mana %d | %s" % [
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
    if profile_label != null:
        _refresh_profile()

func _is_corner(index: int) -> bool:
    return index == 0 or index == 2 or index == 6 or index == 8

func _slot_tooltip(index: int) -> String:
    if index == 4:
        return "Core slot: chooses the magical field and contributes raw power."
    if _is_corner(index):
        return "Boundary slot: geometry mainly controls range and containment."
    return "Flow slot: geometry mainly controls power, duration, and mana flow."
