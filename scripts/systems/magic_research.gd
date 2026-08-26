class_name MagicResearchPanel
extends Control

signal research_completed(level: int, field_name: String)

const RUNES := ["·", "○", "△", "□", "◇"]
const FIELDS := ["Healing", "Agriculture", "Construction", "Weather", "Combat"]

var research_level := 0
var rune_states: Array[int] = []
var buttons: Array[Button] = []
var target: Array[int] = []
var title_label: Label
var target_label: Label
var status_label: Label

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    visible = false
    set_anchors_preset(Control.PRESET_CENTER)
    offset_left = -230.0
    offset_top = -230.0
    offset_right = 230.0
    offset_bottom = 230.0

    var panel := PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(panel)

    var root_box := VBoxContainer.new()
    root_box.add_theme_constant_override("separation", 10)
    panel.add_child(root_box)

    title_label = Label.new()
    title_label.text = "Magic Circle Research"
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    root_box.add_child(title_label)

    var help := Label.new()
    help.text = "Click each sigil to cycle its geometry. Match the target circle.\nPress E to leave the tower."
    help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    root_box.add_child(help)

    target_label = Label.new()
    target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    root_box.add_child(target_label)

    var grid := GridContainer.new()
    grid.columns = 3
    grid.custom_minimum_size = Vector2(300, 300)
    grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    root_box.add_child(grid)

    for i in range(9):
        rune_states.append(0)
        var button := Button.new()
        button.custom_minimum_size = Vector2(92, 92)
        button.text = RUNES[0]
        button.add_theme_font_size_override("font_size", 28)
        button.pressed.connect(_cycle_rune.bind(i))
        buttons.append(button)
        grid.add_child(button)

    status_label = Label.new()
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    root_box.add_child(status_label)

    _make_target()
    _refresh_text()

func _unhandled_input(event: InputEvent) -> void:
    if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
        close()
        get_viewport().set_input_as_handled()

func toggle() -> void:
    visible = not visible
    get_tree().paused = visible

func close() -> void:
    visible = false
    get_tree().paused = false

func _cycle_rune(index: int) -> void:
    rune_states[index] = (rune_states[index] + 1) % RUNES.size()
    buttons[index].text = str(RUNES[rune_states[index]])
    _check_solution()

func _check_solution() -> void:
    if rune_states == target:
        research_level += 1
        var field_name: String = str(FIELDS[(research_level - 1) % FIELDS.size()])
        status_label.text = "Breakthrough: %s magic reached level %d" % [field_name, research_level]
        research_completed.emit(research_level, field_name)
        for i in range(rune_states.size()):
            rune_states[i] = 0
            buttons[i].text = str(RUNES[0])
        _make_target()
        _refresh_text()

func _make_target() -> void:
    target.clear()
    var seed_value: int = research_level + 1
    for i in range(9):
        var row: int = int(i / 3)
        var col: int = i % 3
        var ring_bias: int = int(abs(1 - row) + abs(1 - col))
        target.append(int(1 + ((i * 2 + seed_value + ring_bias) % (RUNES.size() - 1))))

func _refresh_text() -> void:
    var field_name: String = str(FIELDS[research_level % FIELDS.size()])
    title_label.text = "Magic Circle Research  Lv.%d" % research_level
    var target_text := ""
    for i in range(9):
        target_text += str(RUNES[target[i]]) + ("\n" if i % 3 == 2 else "  ")
    target_label.text = "Next field: %s\nTarget topology:\n%s" % [field_name, target_text]
