extends Node

const INK := Color("eeeaff")
const MUTED := Color("aaa4c4")
const GOLD := Color("dcb56f")
const VIOLET := Color("9a61ff")
const PANEL := Color("101024")
const GREEN := Color("8fd6a2")

var main_node: Node2D
var village: VillageSimulation
var player: WitchPlayer
var research_canvas: CanvasLayer
var camera: Camera2D

var launcher_canvas: CanvasLayer
var launcher_button: Button
var visit_canvas: CanvasLayer
var visit_root: Control
var village_title: Label
var village_status: Label
var nearby_label: Label
var talk_button: Button
var dialogue_panel: PanelContainer
var dialogue_label: Label

var in_village := false
var held_directions: Dictionary = {}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_bind_main")

func _bind_main() -> void:
    main_node = get_parent() as Node2D
    if main_node == null:
        return

    village = main_node.get("village") as VillageSimulation
    player = main_node.get("player") as WitchPlayer
    var safe_root := main_node.get("safe_root") as Control

    if village == null or player == null or safe_root == null:
        call_deferred("_bind_main")
        return

    research_canvas = safe_root.get_parent() as CanvasLayer
    player.set_physics_process(false)

    _build_camera()
    _build_launcher()
    _build_visit_ui()
    set_process(true)

func _build_camera() -> void:
    camera = Camera2D.new()
    camera.name = "VillageCamera"
    camera.enabled = false
    camera.zoom = Vector2(1.42, 1.42)
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 6.0
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = int(VillageSimulation.WORLD_SIZE.x)
    camera.limit_bottom = int(VillageSimulation.WORLD_SIZE.y)
    camera.limit_smoothed = true
    player.add_child(camera)

func _build_launcher() -> void:
    launcher_canvas = CanvasLayer.new()
    launcher_canvas.layer = 36
    add_child(launcher_canvas)

    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    launcher_canvas.add_child(root)

    launcher_button = Button.new()
    launcher_button.text = _ui("村へ", "VISIT VILLAGE")
    launcher_button.anchor_left = 1.0
    launcher_button.anchor_right = 1.0
    launcher_button.anchor_top = 1.0
    launcher_button.anchor_bottom = 1.0
    launcher_button.offset_left = -154.0
    launcher_button.offset_top = -151.0
    launcher_button.offset_right = -26.0
    launcher_button.offset_bottom = -99.0
    launcher_button.focus_mode = Control.FOCUS_NONE
    launcher_button.add_theme_font_size_override("font_size", 17)
    launcher_button.add_theme_color_override("font_color", Color("181020"))
    launcher_button.add_theme_stylebox_override("normal", _panel_style(GOLD, Color("f0d28e"), 14, 1))
    launcher_button.add_theme_stylebox_override("hover", _panel_style(Color("efc875"), Color.WHITE, 14, 1))
    launcher_button.add_theme_stylebox_override("pressed", _panel_style(Color("bd8845"), GOLD, 14, 1))
    launcher_button.pressed.connect(_enter_village)
    root.add_child(launcher_button)

func _build_visit_ui() -> void:
    visit_canvas = CanvasLayer.new()
    visit_canvas.layer = 60
    visit_canvas.visible = false
    add_child(visit_canvas)

    visit_root = Control.new()
    visit_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    visit_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    visit_canvas.add_child(visit_root)

    var top_card := PanelContainer.new()
    top_card.anchor_left = 0.035
    top_card.anchor_right = 0.965
    top_card.offset_top = 18.0
    top_card.offset_bottom = 112.0
    top_card.add_theme_stylebox_override("panel", _panel_style(Color("0c1020", 0.94), Color(GOLD, 0.58), 18, 1))
    visit_root.add_child(top_card)

    var top_margin := MarginContainer.new()
    top_margin.add_theme_constant_override("margin_left", 16)
    top_margin.add_theme_constant_override("margin_right", 16)
    top_margin.add_theme_constant_override("margin_top", 10)
    top_margin.add_theme_constant_override("margin_bottom", 10)
    top_card.add_child(top_margin)

    var top_row := HBoxContainer.new()
    top_margin.add_child(top_row)

    var top_text := VBoxContainer.new()
    top_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top_text.add_theme_constant_override("separation", 2)
    top_row.add_child(top_text)

    village_title = Label.new()
    village_title.text = _ui("村", "THE VILLAGE")
    village_title.add_theme_color_override("font_color", INK)
    village_title.add_theme_font_size_override("font_size", 25)
    top_text.add_child(village_title)

    village_status = Label.new()
    village_status.add_theme_color_override("font_color", MUTED)
    village_status.add_theme_font_size_override("font_size", 14)
    top_text.add_child(village_status)

    var return_button := Button.new()
    return_button.text = _ui("研究塔へ", "TO TOWER")
    return_button.custom_minimum_size = Vector2(124, 52)
    return_button.focus_mode = Control.FOCUS_NONE
    return_button.add_theme_font_size_override("font_size", 15)
    return_button.add_theme_color_override("font_color", INK)
    return_button.add_theme_stylebox_override("normal", _panel_style(Color("191632", 0.96), Color(VIOLET, 0.66), 13, 1))
    return_button.add_theme_stylebox_override("hover", _panel_style(Color("2a2150", 0.98), VIOLET, 13, 1))
    return_button.pressed.connect(_exit_village)
    top_row.add_child(return_button)

    var nearby_card := PanelContainer.new()
    nearby_card.anchor_left = 0.10
    nearby_card.anchor_right = 0.90
    nearby_card.anchor_top = 1.0
    nearby_card.anchor_bottom = 1.0
    nearby_card.offset_top = -285.0
    nearby_card.offset_bottom = -225.0
    nearby_card.add_theme_stylebox_override("panel", _panel_style(Color("0e0e22", 0.93), Color(VIOLET, 0.42), 15, 1))
    visit_root.add_child(nearby_card)

    nearby_label = Label.new()
    nearby_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    nearby_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    nearby_label.add_theme_color_override("font_color", INK)
    nearby_label.add_theme_font_size_override("font_size", 16)
    nearby_card.add_child(nearby_label)

    _build_dpad()

    talk_button = Button.new()
    talk_button.text = _ui("話す", "TALK")
    talk_button.anchor_left = 1.0
    talk_button.anchor_right = 1.0
    talk_button.anchor_top = 1.0
    talk_button.anchor_bottom = 1.0
    talk_button.offset_left = -176.0
    talk_button.offset_top = -154.0
    talk_button.offset_right = -28.0
    talk_button.offset_bottom = -82.0
    talk_button.focus_mode = Control.FOCUS_NONE
    talk_button.add_theme_font_size_override("font_size", 19)
    talk_button.add_theme_color_override("font_color", Color("181020"))
    talk_button.add_theme_stylebox_override("normal", _panel_style(GOLD, Color("f0d28e"), 18, 1))
    talk_button.add_theme_stylebox_override("hover", _panel_style(Color("efc875"), Color.WHITE, 18, 1))
    talk_button.add_theme_stylebox_override("disabled", _panel_style(Color("5b526c", 0.72), Color("7e748f", 0.62), 18, 1))
    talk_button.pressed.connect(_talk_to_nearest)
    visit_root.add_child(talk_button)

    dialogue_panel = PanelContainer.new()
    dialogue_panel.visible = false
    dialogue_panel.anchor_left = 0.07
    dialogue_panel.anchor_right = 0.93
    dialogue_panel.anchor_top = 1.0
    dialogue_panel.anchor_bottom = 1.0
    dialogue_panel.offset_top = -420.0
    dialogue_panel.offset_bottom = -305.0
    dialogue_panel.add_theme_stylebox_override("panel", _panel_style(Color("15132d", 0.98), Color(GOLD, 0.76), 18, 2))
    visit_root.add_child(dialogue_panel)

    var dialog_margin := MarginContainer.new()
    dialog_margin.add_theme_constant_override("margin_left", 18)
    dialog_margin.add_theme_constant_override("margin_right", 18)
    dialog_margin.add_theme_constant_override("margin_top", 14)
    dialog_margin.add_theme_constant_override("margin_bottom", 14)
    dialogue_panel.add_child(dialog_margin)

    dialogue_label = Label.new()
    dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    dialogue_label.add_theme_color_override("font_color", INK)
    dialogue_label.add_theme_font_size_override("font_size", 17)
    dialog_margin.add_child(dialogue_label)

func _build_dpad() -> void:
    _direction_button("↑", Vector2(76, -222), Vector2(142, -156), Vector2.UP)
    _direction_button("←", Vector2(12, -158), Vector2(78, -92), Vector2.LEFT)
    _direction_button("↓", Vector2(76, -158), Vector2(142, -92), Vector2.DOWN)
    _direction_button("→", Vector2(140, -158), Vector2(206, -92), Vector2.RIGHT)

func _direction_button(text_value: String, top_left: Vector2, bottom_right: Vector2, direction: Vector2) -> void:
    var button := Button.new()
    button.text = text_value
    button.anchor_top = 1.0
    button.anchor_bottom = 1.0
    button.offset_left = top_left.x
    button.offset_top = top_left.y
    button.offset_right = bottom_right.x
    button.offset_bottom = bottom_right.y
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 25)
    button.add_theme_color_override("font_color", INK)
    button.add_theme_stylebox_override("normal", _panel_style(Color("111126", 0.88), Color(VIOLET, 0.52), 18, 1))
    button.add_theme_stylebox_override("hover", _panel_style(Color("261d49", 0.94), Color(VIOLET, 0.84), 18, 1))
    button.add_theme_stylebox_override("pressed", _panel_style(Color("38275d", 0.98), Color(GOLD, 0.90), 18, 2))
    button.button_down.connect(_set_direction_held.bind(direction, true))
    button.button_up.connect(_set_direction_held.bind(direction, false))
    visit_root.add_child(button)

func _process(_delta: float) -> void:
    if main_node == null or village == null or player == null:
        return

    if not in_village:
        if launcher_button != null:
            var return_overlay := main_node.get("return_overlay") as Control
            launcher_button.visible = return_overlay == null or not return_overlay.visible
        return

    var clock := main_node.get("clock") as GameClock
    if clock != null:
        var year: int = int((clock.get_day() - 1) / 24) + 1
        village_status.text = _ui(
            "%04d年  %s   食糧 %d%% / 疫病 %d%% / 魔物 %d%%" % [year, clock.format_time(), int(village.food_security), int(village.disease_pressure), int(village.monster_threat)],
            "YEAR %04d  %s   FOOD %d%% / DISEASE %d%% / MONSTERS %d%%" % [year, clock.format_time(), int(village.food_security), int(village.disease_pressure), int(village.monster_threat)]
        )

    var nearest := _nearest_villager(115.0)
    talk_button.disabled = nearest == null
    if nearest == null:
        nearby_label.text = _ui("近くに話せる村人はいない", "NO VILLAGER NEARBY")
    else:
        nearby_label.text = _ui(
            "%s  |  %s  |  %d歳" % [nearest.display_name, _occupation_jp(nearest.occupation), nearest.age],
            "%s  |  %s  |  AGE %d" % [nearest.display_name, nearest.occupation.to_upper(), nearest.age]
        )

func _enter_village() -> void:
    if in_village or village == null or player == null:
        return

    in_village = true
    held_directions.clear()
    dialogue_panel.visible = false
    launcher_canvas.visible = false
    if research_canvas != null:
        research_canvas.visible = false

    village.visible = true
    player.visible = true
    player.set_touch_direction(Vector2.ZERO)
    player.set_physics_process(true)
    camera.enabled = true
    visit_canvas.visible = true

    var event_log := main_node.get("event_log") as VillageEventLog
    var clock := main_node.get("clock") as GameClock
    if event_log != null and clock != null:
        event_log.add_event("The immortal witch left the tower and walked into the village.", clock.get_day(), clock.get_minute_of_day(), "history")

func _exit_village() -> void:
    if not in_village:
        return

    in_village = false
    held_directions.clear()
    player.set_touch_direction(Vector2.ZERO)
    player.set_physics_process(false)
    camera.enabled = false
    player.visible = false
    village.visible = false
    visit_canvas.visible = false
    dialogue_panel.visible = false

    if research_canvas != null:
        research_canvas.visible = true
    launcher_canvas.visible = true

func _set_direction_held(direction: Vector2, held: bool) -> void:
    var key := str(direction)
    if held:
        held_directions[key] = direction
    else:
        held_directions.erase(key)

    var combined := Vector2.ZERO
    for value in held_directions.values():
        combined += Vector2(value)
    player.set_touch_direction(combined.normalized() if combined.length_squared() > 0.0 else Vector2.ZERO)

func _nearest_villager(max_distance: float) -> Villager:
    if village == null or player == null:
        return null

    var nearest: Villager = null
    var best_distance := max_distance
    for villager_value in village.villagers:
        var candidate := villager_value as Villager
        if candidate == null or not is_instance_valid(candidate):
            continue
        var distance: float = player.position.distance_to(candidate.position)
        if distance < best_distance:
            best_distance = distance
            nearest = candidate
    return nearest

func _talk_to_nearest() -> void:
    var villager := _nearest_villager(115.0)
    if villager == null:
        return

    village.interact_with_witch(villager)
    dialogue_panel.visible = true

    if _japanese_ui_enabled():
        if villager.respect_for_witch >= 92.0:
            dialogue_label.text = "%sは不老の魔女を見つけると、深々と頭を下げた。\n「お会いできて光栄です、魔女さま。」" % villager.display_name
        elif villager.generation >= 3:
            dialogue_label.text = "%s「あなたのお話は、祖父母の代から聞いています。\n本当に昔と同じ姿なんですね。」" % villager.display_name
        else:
            dialogue_label.text = "%s「おかえりなさい、魔女さま。村は今日も動いていますよ。」" % villager.display_name
    else:
        if villager.generation >= 3:
            dialogue_label.text = "%s says their family has told stories about the witch for generations." % villager.display_name
        else:
            dialogue_label.text = "%s greets the immortal witch with obvious respect." % villager.display_name

func _occupation_jp(occupation: String) -> String:
    return str({
        "Farmer": "農家",
        "Baker": "パン屋",
        "Blacksmith": "鍛冶師",
        "Doctor": "医師",
        "Shopkeeper": "商店主",
        "Innkeeper": "宿屋",
        "Carpenter": "大工",
        "Mayor": "村長",
        "Researcher": "研究者",
        "Hunter": "狩人",
        "Gatherer": "採集人",
        "Unemployed": "無職",
        "Apprentice": "見習い",
    }.get(occupation, occupation))

func _japanese_ui_enabled() -> bool:
    if not OS.has_feature("web"):
        return true
    return bool(UIFont.japanese_ready)

func _ui(japanese: String, english: String) -> String:
    return japanese if _japanese_ui_enabled() else english

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
    style.shadow_color = Color(0.0, 0.0, 0.0, 0.24)
    style.shadow_size = 8
    return style
