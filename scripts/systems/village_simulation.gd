class_name VillageSimulation
extends Node2D

const WORLD_SIZE := Vector2(864, 1536)
const TOWER_POSITION := Vector2(585, 170)
const VISIT_SPAWN_POSITION := Vector2(430, 1015)
const VILLAGE_ART_PATH := "res://art/village/village_night.jpg"

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
var village_texture: Texture2D

var magic_level := 0
var magic_fields := {
    "Healing": 0,
    "Agriculture": 0,
    "Construction": 0,
    "Weather": 0,
    "Combat": 0,
}

var monster_threat := 5.0
var food_security := 72.0
var disease_pressure := 4.0

# Coordinates now follow the approved vertical village artwork.
var anchors := {
    "plaza": Vector2(430, 760),
    "food": Vector2(700, 865),
    "tavern": Vector2(690, 1190),
    "farm": Vector2(185, 1240),
    "bakery": Vector2(235, 585),
    "smithy": Vector2(700, 1190),
    "clinic": Vector2(675, 620),
    "shop": Vector2(710, 875),
    "carpenter": Vector2(690, 1210),
    "hall": Vector2(430, 770),
    "research": TOWER_POSITION,
    "forest": Vector2(760, 1390),
}

func setup(game_clock: GameClock, village_event_log: VillageEventLog) -> void:
    clock = game_clock
    event_log = village_event_log
    rng.seed = 913775
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    if ResourceLoader.exists(VILLAGE_ART_PATH):
        village_texture = load(VILLAGE_ART_PATH)
    clock.day_changed.connect(_on_day_changed)
    clock.years_skipped.connect(_on_years_skipped)
    _spawn_initial_population()
    _initialize_relationships()
    _teach_village_magic()
    queue_redraw()
    event_log.add_event("The village begins another quiet day.", clock.get_day(), clock.get_minute_of_day(), "history")

func get_status_summary() -> String:
    return "Food %d%%  Disease %d%%  Monsters %d%%" % [int(food_security), int(disease_pressure), int(monster_threat)]

func get_visit_spawn_position() -> Vector2:
    return VISIT_SPAWN_POSITION

func interact_with_witch(villager: Villager) -> String:
    if villager == null or not is_instance_valid(villager):
        return ""
    var message: String = villager.greet_witch()
    event_log.add_event(message, clock.get_day(), clock.get_minute_of_day(), "life")
    return message

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

func _initialize_relationships() -> void:
    for i in range(villagers.size()):
        var first: Villager = villagers[i]
        for j in range(i + 1, villagers.size()):
            var second: Villager = villagers[j]
            var base: float = rng.randf_range(-8.0, 22.0)
            first.initialize_relationship(second.display_name, base)
            second.initialize_relationship(first.display_name, base + rng.randf_range(-4.0, 4.0))

func _initialize_new_villager_relationships(new_villager: Villager) -> void:
    for other in villagers:
        if other == new_villager or not is_instance_valid(other):
            continue
        var base: float = rng.randf_range(-4.0, 16.0)
        new_villager.initialize_relationship(other.display_name, base)
        other.initialize_relationship(new_villager.display_name, base + rng.randf_range(-3.0, 3.0))

func _home_position(index: int) -> Vector2:
    var column: int = index % 5
    var row: int = int(index / 5)
    return Vector2(150 + column * 140, 900 + row * 112)

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

    match field_name:
        "Healing":
            disease_pressure = maxf(0.0, disease_pressure - 8.0 - float(magic_fields["Healing"]) * 1.5)
        "Agriculture":
            food_security = minf(100.0, food_security + 9.0 + float(magic_fields["Agriculture"]) * 1.5)
        "Construction":
            monster_threat = maxf(0.0, monster_threat - 5.0 - float(magic_fields["Construction"]))
        "Weather":
            food_security = minf(100.0, food_security + 5.0 + float(magic_fields["Weather"]))
            disease_pressure = maxf(0.0, disease_pressure - 2.0)
        "Combat":
            monster_threat = maxf(0.0, monster_threat - 12.0 - float(magic_fields["Combat"]) * 2.0)

    _teach_village_magic()
    event_log.add_event(
        "%s magic entered the village tradition. Village research level is now %d." % [field_name, magic_level],
        clock.get_day(), clock.get_minute_of_day(), "magic"
    )

func _teach_village_magic() -> void:
    for villager in villagers:
        if is_instance_valid(villager):
            villager.update_magic_knowledge(magic_fields)

func _on_day_changed(day: int) -> void:
    if day <= 1:
        return

    _update_food_security(day)
    _update_disease_pressure(day)
    _update_monster_pressure(day)
    _simulate_social_day(day)
    _remove_dead_villagers()

func _update_food_security(day: int) -> void:
    var farmer_count := 0
    var support_count := 0
    for villager in villagers:
        if not is_instance_valid(villager):
            continue
        if villager.occupation == "Farmer":
            farmer_count += 1
        elif villager.occupation == "Hunter" or villager.occupation == "Gatherer":
            support_count += 1

    var production: float = float(farmer_count) * 0.22 + float(support_count) * 0.10
    production += float(magic_fields["Agriculture"]) * 0.72 + float(magic_fields["Weather"]) * 0.30
    var consumption: float = float(villagers.size()) * 0.075
    var natural_variation: float = rng.randf_range(-0.45, 0.35)
    food_security = clampf(food_security + production - consumption + natural_variation, 0.0, 100.0)

    if food_security < 35.0:
        var shortage: float = (35.0 - food_security) * 0.12
        for villager in villagers:
            if is_instance_valid(villager):
                villager.apply_food_shortage(shortage)
        if day % 3 == 0:
            event_log.add_event("Food stores are running low and some families are skipping meals.", day, clock.get_minute_of_day(), "hunger")
    elif food_security > 88.0 and day % 8 == 0:
        event_log.add_event("The granaries are full after a good run of harvests.", day, clock.get_minute_of_day(), "life")

func _update_disease_pressure(day: int) -> void:
    var healing: float = float(magic_fields["Healing"])
    var food_stress: float = maxf(0.0, 45.0 - food_security) * 0.025
    disease_pressure = clampf(disease_pressure + 0.42 + food_stress - healing * 0.32 + rng.randf_range(-0.25, 0.35), 0.0, 100.0)

    var infection_chance: float = clampf(disease_pressure / 260.0, 0.0, 0.38)
    if villagers.size() > 0 and rng.randf() < infection_chance:
        var target: Villager = villagers[rng.randi_range(0, villagers.size() - 1)]
        if is_instance_valid(target) and not target.sick:
            var severity: float = rng.randf_range(0.25, 0.85)
            target.contract_illness(severity)
            event_log.add_event("%s has fallen ill." % target.display_name, day, clock.get_minute_of_day(), "disease")

    if disease_pressure >= 55.0 and day % 4 == 0:
        event_log.add_event("Illness is spreading through the village.", day, clock.get_minute_of_day(), "disease")

func _update_monster_pressure(day: int) -> void:
    var combat_protection: float = float(magic_fields["Combat"]) * 0.22
    var construction_protection: float = float(magic_fields["Construction"]) * 0.08
    var growth: float = maxf(0.25, 1.25 - combat_protection - construction_protection)
    monster_threat = clampf(monster_threat + growth, 0.0, 100.0)

    if monster_threat >= 75.0 and day % 3 == 0:
        event_log.add_event("Tracks and broken fences suggest powerful monsters nearby.", day, clock.get_minute_of_day(), "threat")
    elif monster_threat >= 40.0 and day % 5 == 0:
        event_log.add_event("Hunters report more monsters at the forest edge.", day, clock.get_minute_of_day(), "threat")

func _simulate_social_day(day: int) -> void:
    if villagers.size() < 2:
        return

    var interactions: int = mini(3, int(villagers.size() / 4))
    for _i in range(interactions):
        var first_index: int = rng.randi_range(0, villagers.size() - 1)
        var second_index: int = rng.randi_range(0, villagers.size() - 1)
        if first_index == second_index:
            continue
        var first: Villager = villagers[first_index]
        var second: Villager = villagers[second_index]
        if not is_instance_valid(first) or not is_instance_valid(second):
            continue

        var delta: int = first.socialize_with(second)
        second.change_relationship(first.display_name, float(delta))
        var relation: float = first.get_relationship(second.display_name)
        if delta > 0 and relation >= 45.0 and rng.randf() < 0.22:
            event_log.add_event("%s and %s have become close companions." % [first.display_name, second.display_name], day, clock.get_minute_of_day(), "relationship")
        elif delta < 0 and relation <= -28.0 and rng.randf() < 0.28:
            event_log.add_event("%s and %s argued in the village." % [first.display_name, second.display_name], day, clock.get_minute_of_day(), "relationship")

func _remove_dead_villagers() -> void:
    var replacements: Array[Dictionary] = []
    for villager in villagers:
        if is_instance_valid(villager) and villager.health <= 0.0:
            replacements.append(_replacement_data(villager))

    for replacement in replacements:
        _replace_with_descendant(replacement, "died during a hard season")

func _on_years_skipped(years: int, _from_year: int, _to_year: int) -> void:
    var replacements: Array[Dictionary] = []
    for villager in villagers:
        if not is_instance_valid(villager):
            continue
        villager.advance_years(years)
        if villager.age >= 78 or villager.health <= 0.0:
            replacements.append(_replacement_data(villager))

    for replacement in replacements:
        _replace_with_descendant(replacement, "passed into village memory while the witch was away")

    food_security = clampf(
        food_security + float(years) * (float(magic_fields["Agriculture"]) * 1.2 + float(magic_fields["Weather"]) * 0.45 - 0.65),
        0.0,
        100.0
    )
    disease_pressure = clampf(
        disease_pressure + float(years) * (1.1 - float(magic_fields["Healing"]) * 0.55),
        0.0,
        100.0
    )
    monster_threat = clampf(
        monster_threat + float(years) * maxf(0.8, 2.8 - float(magic_fields["Combat"]) * 0.35 - float(magic_fields["Construction"]) * 0.12),
        0.0,
        100.0
    )

    event_log.add_event(
        "%d years passed while the witch studied. The village has changed." % years,
        clock.get_day(), clock.get_minute_of_day(), "history"
    )

func _replacement_data(villager: Villager) -> Dictionary:
    return {
        "villager": villager,
        "family": villager.family_name,
        "occupation": villager.occupation,
        "generation": villager.generation + 1,
        "home": villager.home_position,
    }

func _replace_with_descendant(data: Dictionary, reason: String) -> void:
    var old_villager := data["villager"] as Villager
    if old_villager == null or not is_instance_valid(old_villager):
        return
    event_log.add_event(
        "%s %s." % [old_villager.display_name, reason],
        clock.get_day(), clock.get_minute_of_day(), "generation"
    )
    villagers.erase(old_villager)
    old_villager.queue_free()
    _spawn_descendant(data)

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
    villager.update_magic_knowledge(magic_fields)
    _initialize_new_villager_relationships(villager)
    event_log.add_event(
        "%s of the %s family has taken a place in village life." % [given, family],
        clock.get_day(), clock.get_minute_of_day(), "generation"
    )

func _on_villager_action_changed(villager: Villager, _old_action: String, new_action: String) -> void:
    if new_action == "socialize" and rng.randf() < 0.06:
        event_log.add_event(
            "%s headed out to spend time with the village." % villager.display_name,
            clock.get_day(), clock.get_minute_of_day(), "life"
        )
    elif new_action == "magic_work" and rng.randf() < 0.08:
        event_log.add_event(
            "%s used %s magic while working as a %s." % [villager.display_name, villager.get_preferred_magic_field(), villager.occupation],
            clock.get_day(), clock.get_minute_of_day(), "magic"
        )

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("09091a"))
    if village_texture != null:
        draw_texture_rect(village_texture, Rect2(Vector2.ZERO, WORLD_SIZE), false)
    else:
        draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("252746"))

    # The concept image originally contains a showcase witch at this location.
    # Cover it with an in-world arrival seal so the live animated player owns the space.
    var seal_center := VISIT_SPAWN_POSITION
    draw_circle(seal_center, 72.0, Color(0.035, 0.025, 0.09, 0.96))
    draw_arc(seal_center, 61.0, 0.0, TAU, 64, Color("9a61ff"), 3.0, true)
    draw_arc(seal_center, 48.0, 0.0, TAU, 64, Color("dcb56f"), 1.8, true)
    for ray in range(8):
        var angle := TAU * float(ray) / 8.0
        var inner := seal_center + Vector2(cos(angle), sin(angle)) * 28.0
        var outer := seal_center + Vector2(cos(angle), sin(angle)) * 56.0
        draw_line(inner, outer, Color("b891ff"), 1.8, true)
    draw_circle(seal_center, 5.0, Color("ece7ff"))
