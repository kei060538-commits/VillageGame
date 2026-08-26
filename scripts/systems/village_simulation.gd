class_name VillageSimulation
extends Node2D

const WORLD_SIZE := Vector2(1600, 900)
const TOWER_POSITION := Vector2(1430, 190)

const OCCUPATIONS := [
    "Farmer", "Farmer", "Farmer", "Farmer", "Farmer", "Farmer",
    "Baker", "Blacksmith", "Doctor", "Shopkeeper", "Innkeeper", "Carpenter",
    "Mayor", "Researcher", "Hunter", "Gatherer", "Unemployed", "Unemployed",
    "Apprentice", "Apprentice"
]

const GIVEN_NAMES := [
    "Ari", "Mira", "Elio", "Nia", "Toma", "Lina", "Soren", "Fia", "Noel", "Iris",
    "Rin", "Caro", "Vela", "Theo", "Mina", "Luca", "Ena", "Roa", "Sia", "Kiel",
    "Nera", "Olin", "Yuna", "Remi", "Ciel", "Tess", "Lio", "Meri", "Aster", "Nell"
]

const FAMILY_NAMES := [
    "Ash", "Bell", "Cedar", "Dawn", "Ember", "Field", "Grove", "Hearth", "Ivy", "Lake",
    "Moss", "North", "Oak", "Reed", "Stone", "Vale", "Wren", "Yew", "Brook", "Hill"
]

var clock: GameClock
var event_log: VillageEventLog
var villagers: Array[Villager] = []
var rng := RandomNumberGenerator.new()
var magic_level := 0
var magic_fields := {
    "Healing": 0,
    "Agriculture": 0,
    "Construction": 0,
    "Weather": 0,
    "Combat": 0,
}
var monster_threat := 5.0

var anchors := {
    "plaza": Vector2(760, 450),
    "food": Vector2(660, 405),
    "tavern": Vector2(860, 420),
    "farm": Vector2(350, 650),
    "bakery": Vector2(650, 390),
    "smithy": Vector2(955, 575),
    "clinic": Vector2(620, 535),
    "shop": Vector2(785, 355),
    "carpenter": Vector2(1020, 390),
    "hall": Vector2(760, 520),
    "research": Vector2(1080, 255),
    "forest": Vector2(1220, 680),
}

func setup(game_clock: GameClock, village_event_log: VillageEventLog) -> void:
    clock = game_clock
    event_log = village_event_log
    rng.seed = 913775
    clock.day_changed.connect(_on_day_changed)
    clock.years_skipped.connect(_on_years_skipped)
    _spawn_initial_population()
    queue_redraw()
    event_log.add_event("The village begins another quiet day.", clock.get_day(), clock.get_minute_of_day(), "history")

func _spawn_initial_population() -> void:
    for i in range(OCCUPATIONS.size()):
        var home: Vector2 = _home_position(i)
        var villager := Villager.new()
        var family: String = str(FAMILY_NAMES[i % FAMILY_NAMES.size()])
        var given: String = str(GIVEN_NAMES[i % GIVEN_NAMES.size()])
        var occupation: String = str(OCCUPATIONS[i])
        villager.setup(
            given + " " + family,
            family,
            occupation,
            rng.randi_range(18, 52),
            1,
            home,
            _work_position(occupation),
            anchors,
            clock
        )
        villager.action_changed.connect(_on_villager_action_changed)
        villagers.append(villager)
        add_child(villager)

func _home_position(index: int) -> Vector2:
    var column: int = index % 5
    var row: int = int(index / 5)
    return Vector2(500 + column * 135, 235 + row * 135)

func _work_position(occupation: String) -> Vector2:
    match occupation:
        "Farmer": return Vector2(anchors["farm"])
        "Baker": return Vector2(anchors["bakery"])
        "Blacksmith": return Vector2(anchors["smithy"])
        "Doctor": return Vector2(anchors["clinic"])
        "Shopkeeper": return Vector2(anchors["shop"])
        "Innkeeper": return Vector2(anchors["tavern"])
        "Carpenter": return Vector2(anchors["carpenter"])
        "Mayor": return Vector2(anchors["hall"])
        "Researcher": return Vector2(anchors["research"])
        "Hunter", "Gatherer": return Vector2(anchors["forest"])
        "Apprentice": return Vector2(anchors["smithy"] if rng.randf() < 0.5 else anchors["bakery"])
        _: return Vector2(anchors["plaza"])

func apply_magic_research(level: int, field_name: String) -> void:
    magic_level = maxi(magic_level, level)
    if magic_fields.has(field_name):
        magic_fields[field_name] = int(magic_fields[field_name]) + 1
    monster_threat = maxf(0.0, monster_threat - 10.0 - float(magic_fields["Combat"]) * 2.0)
    event_log.add_event(
        "%s magic entered the village tradition. Knowledge level is now %d." % [field_name, magic_level],
        clock.get_day(), clock.get_minute_of_day(), "magic"
    )

func _on_day_changed(day: int) -> void:
    if day <= 1:
        return
    var protection: float = float(magic_fields["Combat"]) * 0.18
    monster_threat = clampf(monster_threat + maxf(0.35, 1.25 - protection), 0.0, 100.0)

    if monster_threat >= 75.0 and day % 3 == 0:
        event_log.add_event("Tracks and broken fences suggest powerful monsters nearby.", day, clock.get_minute_of_day(), "threat")
    elif monster_threat >= 40.0 and day % 5 == 0:
        event_log.add_event("Hunters report more monsters at the forest edge.", day, clock.get_minute_of_day(), "threat")

func _on_years_skipped(years: int, _from_year: int, _to_year: int) -> void:
    var replacements: Array[Dictionary] = []
    for villager in villagers:
        villager.advance_years(years)
        if villager.age >= 78:
            replacements.append({
                "villager": villager,
                "family": villager.family_name,
                "occupation": villager.occupation,
                "generation": villager.generation + 1,
                "home": villager.home_position,
            })

    for replacement in replacements:
        var old_villager := replacement["villager"] as Villager
        if old_villager == null:
            continue
        event_log.add_event(
            "%s is now remembered as part of village history." % old_villager.display_name,
            clock.get_day(), clock.get_minute_of_day(), "generation"
        )
        villagers.erase(old_villager)
        old_villager.queue_free()
        _spawn_descendant(replacement)

    monster_threat = clampf(monster_threat + float(years) * maxf(1.0, 3.0 - float(magic_fields["Combat"]) * 0.25), 0.0, 100.0)
    event_log.add_event(
        "%d years passed while the witch studied. The village has changed." % years,
        clock.get_day(), clock.get_minute_of_day(), "history"
    )

func _spawn_descendant(data: Dictionary) -> void:
    var villager := Villager.new()
    var given: String = str(GIVEN_NAMES[rng.randi_range(0, GIVEN_NAMES.size() - 1)])
    var family: String = str(data["family"])
    var occupation: String = str(data["occupation"])
    var home: Vector2 = Vector2(data["home"])
    villager.setup(
        given + " " + family,
        family,
        occupation,
        rng.randi_range(18, 27),
        int(data["generation"]),
        home,
        _work_position(occupation),
        anchors,
        clock
    )
    villager.action_changed.connect(_on_villager_action_changed)
    villagers.append(villager)
    add_child(villager)
    event_log.add_event(
        "%s of the %s family has taken a place in village life." % [given, family],
        clock.get_day(), clock.get_minute_of_day(), "generation"
    )

func _on_villager_action_changed(villager: Villager, _old_action: String, new_action: String) -> void:
    if new_action == "socialize" and rng.randf() < 0.08:
        event_log.add_event(
            "%s headed out to spend time with the village." % villager.display_name,
            clock.get_day(), clock.get_minute_of_day(), "life"
        )

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("6f9654"))
    draw_rect(Rect2(390, 430, 760, 48), Color("b89b71"))
    draw_rect(Rect2(735, 160, 52, 590), Color("b89b71"))
    draw_rect(Rect2(0, 760, 1600, 140), Color("5c91a8"))
    draw_rect(Rect2(700, 748, 130, 36), Color("8f6848"))

    for row in range(4):
        draw_rect(Rect2(120, 555 + row * 42, 300, 28), Color("80623f"))

    _draw_building(Vector2(610, 365), Vector2(90, 70), Color("d1ad78"))
    _draw_building(Vector2(825, 385), Vector2(110, 82), Color("a86d55"))
    _draw_building(Vector2(910, 535), Vector2(105, 78), Color("77777f"))
    _draw_building(Vector2(570, 500), Vector2(100, 76), Color("d9d2b0"))
    _draw_building(Vector2(735, 315), Vector2(100, 72), Color("c9a66b"))
    _draw_building(Vector2(970, 355), Vector2(105, 72), Color("9a765e"))
    _draw_building(Vector2(700, 485), Vector2(120, 92), Color("c7b589"))
    _draw_building(Vector2(1035, 220), Vector2(95, 75), Color("8b779e"))

    draw_circle(TOWER_POSITION, 52.0, Color("4f486d"))
    draw_circle(TOWER_POSITION, 39.0, Color("26283e"))
    draw_line(TOWER_POSITION + Vector2(-30, 18), TOWER_POSITION + Vector2(30, -18), Color("bda9e8"), 4.0)
    draw_line(TOWER_POSITION + Vector2(-30, -18), TOWER_POSITION + Vector2(30, 18), Color("bda9e8"), 4.0)

func _draw_building(center: Vector2, size: Vector2, color: Color) -> void:
    draw_rect(Rect2(center - size * 0.5, size), color)
    var roof := PackedVector2Array([
        center + Vector2(-size.x * 0.6, -size.y * 0.45),
        center + Vector2(size.x * 0.6, -size.y * 0.45),
        center + Vector2(0, -size.y * 0.85),
    ])
    draw_colored_polygon(roof, Color("644b43"))
