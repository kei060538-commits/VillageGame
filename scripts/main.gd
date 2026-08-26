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
var safe_root: Control
var info_panel: PanelContainer
var history_panel: PanelContainer
var touch_root: Control

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
    get_viewport().size_changed.connect(_apply_safe_area_layout)
    call_deferred("_apply_safe_area_layout")
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
        hint_label.text = "E / TOWER: enter the research tower"
        return

    var nearest: Villager = _nearest_villager(72.0)
    if nearest != null:
        var preferred_magic: String = nearest.get_preferred_magic_field()
        var magic_skill: int = nearest.get_work_magic_level()
        hint_label.text = "F / TALK: greet  |  %s  |  %s  |  age %d  |  %s  |  %s magic %d" % [
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

    if event.keycode == KEY_E:
        _try_tower_interaction()
    elif event.keycode == KEY_F:
        _try_greet()
    elif event.keycode == KEY_1:
        clock.set_speed(1.0)
    elif event.keycode == KEY_2:
        clock.set_speed(4.0)
    elif event.keycode == KEY_3:
        clock.set_speed(16.0)

func _try_tower_interaction() -> void:
    if player.position.distance_to(VillageSimulation.TOWER_POSITION) >= 92.0:
        return
    player.set_touch_direction(Vector2.ZERO)
    research_panel.toggle()
    get_viewport().set_input_as_handled()

func _try_greet() -> void:
    var nearest: Villager = _nearest_villager(72.0)
    if nearest == null:
        return
    village.interact_with_witch(nearest)
    get_viewport().set_input_as_handled()

func _build_ui() -> void:
    var canvas := CanvasLayer.new()
    add_child(canvas)

    safe_root = Control.new()
    safe_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    safe_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(safe_root)

    info_panel = PanelContainer.new()
    info_panel.position = Vector2(14, 14)
    info_panel.size = Vector2(610, 108)
    safe_root.add_child(info_panel)

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

    history_panel = PanelContainer.new()
    history_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    history_panel.offset_left = -410.0
    history_panel.offset_top = 14.0
    history_panel.offset_right = -14.0
    history_panel.offset_bottom = 246.0
    safe_root.add_child(history_panel)

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

    if _touch_controls_enabled():
        _build_touch_controls(safe_root)

    research_panel = MagicResearchPanel.new()
    research_panel.z_index = 20
    canvas.add_child(research_panel)
    research_panel.research_completed.connect(_on_research_completed)
    _add_research_close_button()

func _touch_controls_enabled() -> bool:
    return OS.has_feature("ios") or OS.has_feature("android") or OS.has_feature("web") or DisplayServer.is_touchscreen_available()

func _apply_safe_area_layout() -> void:
    if safe_root == null:
        return

    safe_root.offset_left = 0.0
    safe_root.offset_top = 0.0
    safe_root.offset_right = 0.0
    safe_root.offset_bottom = 0.0

    var viewport_size: Vector2 = get_viewport().get_visible_rect().size
    var left_inset := 0.0
    var top_inset := 0.0
    var right_inset := 0.0
    var bottom_inset := 0.0

    if OS.has_feature("ios") or OS.has_feature("android"):
        var window_size: Vector2i = DisplayServer.window_get_size()
        var safe_area: Rect2i = DisplayServer.get_display_safe_area()
        if window_size.x > 0 and window_size.y > 0 and safe_area.size.x > 0 and safe_area.size.y > 0:
            var scale_x: float = viewport_size.x / float(window_size.x)
            var scale_y: float = viewport_size.y / float(window_size.y)
            left_inset = maxf(0.0, float(safe_area.position.x) * scale_x)
            top_inset = maxf(0.0, float(safe_area.position.y) * scale_y)
            var unsafe_right: int = window_size.x - (safe_area.position.x + safe_area.size.x)
            var unsafe_bottom: int = window_size.y - (safe_area.position.y + safe_area.size.y)
            right_inset = maxf(0.0, float(unsafe_right) * scale_x)
            bottom_inset = maxf(0.0, float(unsafe_bottom) * scale_y)

    safe_root.offset_left = left_inset
    safe_root.offset_top = top_inset
    safe_root.offset_right = -right_inset
    safe_root.offset_bottom = -bottom_inset

    var usable_width: float = viewport_size.x - left_inset - right_inset
    if info_panel != null:
        info_panel.size.x = minf(610.0, maxf(360.0, usable_width - 28.0))
    if history_panel != null:
        history_panel.visible = usable_width >= 1040.0

func _add_research_close_button() -> void:
    var close_button := Button.new()
    close_button.text = "CLOSE"
    close_button.focus_mode = Control.FOCUS_NONE
    close_button.custom_minimum_size = Vector2(96, 48)
    close_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    close_button.offset_left = -116.0
    close_button.offset_top = -64.0
    close_button.offset_right = -20.0
    close_button.offset_bottom = -16.0
    close_button.pressed.connect(research_panel.close)
    research_panel.add_child(close_button)

func _build_touch_controls(parent: Control) -> void:
    touch_root = Control.new()
    touch_root.z_index = 5
    touch_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    touch_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(touch_root)

    var up := _make_touch_button(touch_root, "UP", Vector2(0.0, 1.0), Rect2(112, -224, 76, 76))
    var left := _make_touch_button(touch_root, "LEFT", Vector2(0.0, 1.0), Rect2(30, -142, 76, 76))
    var down := _make_touch_button(touch_root, "DOWN", Vector2(0.0, 1.0), Rect2(112, -142, 76, 76))
    var right := _make_touch_button(touch_root, "RIGHT", Vector2(0.0, 1.0), Rect2(194, -142, 76, 76))

    up.button_down.connect(player.set_touch_direction.bind(Vector2.UP))
    up.button_up.connect(player.set_touch_direction.bind(Vector2.ZERO))
    left.button_down.connect(player.set_touch_direction.bind(Vector2.LEFT))
    left.button_up.connect(player.set_touch_direction.bind(Vector2.ZERO))
    down.button_down.connect(player.set_touch_direction.bind(Vector2.DOWN))
    down.button_up.connect(player.set_touch_direction.bind(Vector2.ZERO))
    right.button_down.connect(player.set_touch_direction.bind(Vector2.RIGHT))
    right.button_up.connect(player.set_touch_direction.bind(Vector2.ZERO))

    var tower_button := _make_touch_button(touch_root, "TOWER", Vector2(1.0, 1.0), Rect2(-224, -142, 92, 76))
    var talk_button := _make_touch_button(touch_root, "TALK", Vector2(1.0, 1.0), Rect2(-124, -142, 92, 76))
    tower_button.pressed.connect(_try_tower_interaction)
    talk_button.pressed.connect(_try_greet)

    var speed_1 := _make_touch_button(touch_root, "x1", Vector2(1.0, 1.0), Rect2(-246, -214, 62, 54))
    var speed_4 := _make_touch_button(touch_root, "x4", Vector2(1.0, 1.0), Rect2(-176, -214, 62, 54))
    var speed_16 := _make_touch_button(touch_root, "x16", Vector2(1.0, 1.0), Rect2(-106, -214, 62, 54))
    speed_1.pressed.connect(clock.set_speed.bind(1.0))
    speed_4.pressed.connect(clock.set_speed.bind(4.0))
    speed_16.pressed.connect(clock.set_speed.bind(16.0))

func _make_touch_button(parent: Control, text: String, anchor: Vector2, rect: Rect2) -> Button:
    var button := Button.new()
    button.text = text
    button.focus_mode = Control.FOCUS_NONE
    button.anchor_left = anchor.x
    button.anchor_right = anchor.x
    button.anchor_top = anchor.y
    button.anchor_bottom = anchor.y
    button.offset_left = rect.position.x
    button.offset_top = rect.position.y
    button.offset_right = rect.position.x + rect.size.x
    button.offset_bottom = rect.position.y + rect.size.y
    button.add_theme_font_size_override("font_size", 15)
    parent.add_child(button)
    return button

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
