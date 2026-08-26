extends Node2D

var clock: GameClock
var event_log: VillageEventLog
var village: VillageSimulation
var player: WitchPlayer
var research_panel: MagicResearchPanel

var clock_label: Label
var status_label: Label
var hint_label: Label
var log_label: Label

func _ready() -> void:
    clock = GameClock.new()
    add_child(clock)

    event_log = VillageEventLog.new()
    add_child(event_log)

    village = VillageSimulation.new()
    add_child(village)
    village.setup(clock, event_log)

    player = WitchPlayer.new()
    player.position = Vector2(760, 650)
    add_child(player)

    var camera := Camera2D.new()
    camera.enabled = true
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = 1600
    camera.limit_bottom = 900
    player.add_child(camera)

    _build_ui()
    event_log.event_added.connect(_refresh_event_log)
    _refresh_event_log({})

func _process(_delta: float) -> void:
    if clock_label == null:
        return

    clock_label.text = clock.format_time() + "   x%.0f" % clock.time_scale
    status_label.text = "Village Magic Lv.%d   %s" % [
        village.magic_level,
        village.get_status_summary(),
    ]

    var tower_distance: float = player.position.distance_to(VillageSimulation.TOWER_POSITION)
    if tower_distance < 92.0:
        hint_label.text = "E: enter the research tower"
        return

    var nearest: Villager = _nearest_villager(72.0)
    if nearest != null:
        var preferred_magic: String = nearest.get_preferred_magic_field()
        var magic_skill: int = nearest.get_work_magic_level()
        hint_label.text = "F: greet  |  %s  |  %s  |  age %d  |  %s  |  %s magic %d" % [
            nearest.display_name,
            nearest.occupation,
            nearest.age,
            nearest.current_action,
            preferred_magic,
            magic_skill,
        ]
    else:
        hint_label.text = "WASD / arrows: move    F: greet villager    1/2/3: time speed"

func _unhandled_input(event: InputEvent) -> void:
    if not (event is InputEventKey and event.pressed and not event.echo):
        return

    if event.keycode == KEY_E and player.position.distance_to(VillageSimulation.TOWER_POSITION) < 92.0:
        research_panel.toggle()
        get_viewport().set_input_as_handled()
    elif event.keycode == KEY_F:
        var nearest: Villager = _nearest_villager(72.0)
        if nearest != null:
            village.interact_with_witch(nearest)
            get_viewport().set_input_as_handled()
    elif event.keycode == KEY_1:
        clock.set_speed(1.0)
    elif event.keycode == KEY_2:
        clock.set_speed(4.0)
    elif event.keycode == KEY_3:
        clock.set_speed(16.0)

func _build_ui() -> void:
    var canvas := CanvasLayer.new()
    add_child(canvas)

    var info_panel := PanelContainer.new()
    info_panel.position = Vector2(14, 14)
    info_panel.size = Vector2(610, 108)
    canvas.add_child(info_panel)

    var info_box := VBoxContainer.new()
    info_panel.add_child(info_box)

    clock_label = Label.new()
    clock_label.add_theme_font_size_override("font_size", 18)
    info_box.add_child(clock_label)

    status_label = Label.new()
    info_box.add_child(status_label)

    hint_label = Label.new()
    hint_label.text = "WASD / arrows: move"
    hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    info_box.add_child(hint_label)

    var history_panel := PanelContainer.new()
    history_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    history_panel.offset_left = -410.0
    history_panel.offset_top = 14.0
    history_panel.offset_right = -14.0
    history_panel.offset_bottom = 246.0
    canvas.add_child(history_panel)

    var history_box := VBoxContainer.new()
    history_panel.add_child(history_box)

    var history_title := Label.new()
    history_title.text = "Village Chronicle"
    history_title.add_theme_font_size_override("font_size", 17)
    history_box.add_child(history_title)

    log_label = Label.new()
    log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    log_label.custom_minimum_size = Vector2(370, 180)
    history_box.add_child(log_label)

    research_panel = MagicResearchPanel.new()
    canvas.add_child(research_panel)
    research_panel.research_completed.connect(_on_research_completed)

func _on_research_completed(level: int, field_name: String) -> void:
    village.apply_magic_research(level, field_name)
    var years_spent: int = clampi(8 + level * 2, 10, 30)
    clock.fast_forward_years(years_spent)
    event_log.add_event(
        "The immortal witch returned from the tower after %d years of research." % years_spent,
        clock.get_day(), clock.get_minute_of_day(), "history"
    )
    research_panel.close()

func _refresh_event_log(_entry: Dictionary) -> void:
    if log_label == null:
        return
    var lines: Array[String] = []
    for entry in event_log.latest(7):
        lines.append(event_log.format_entry(entry))
    log_label.text = "\n".join(lines)

func _nearest_villager(max_distance: float) -> Villager:
    var nearest: Villager = null
    var nearest_distance := max_distance
    for villager in village.villagers:
        if not is_instance_valid(villager):
            continue
        var distance: float = player.position.distance_to(villager.position)
        if distance < nearest_distance:
            nearest = villager
            nearest_distance = distance
    return nearest
