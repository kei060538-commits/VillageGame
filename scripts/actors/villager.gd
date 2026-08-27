class_name Villager
extends CharacterBody2D

signal action_changed(villager: Villager, old_action: String, new_action: String)

const MOVE_SPEED := 62.0
const MAGIC_FIELDS := ["Healing", "Agriculture", "Construction", "Weather", "Combat"]

var display_name := "Villager"
var family_name := ""
var occupation := "Unemployed"
var generation := 1
var age := 25

var hunger := 20.0
var energy := 85.0
var health := 100.0
var social_need := 20.0
var sick := false
var illness_severity := 0.0

var sociability := 0.5
var diligence := 0.5
var curiosity := 0.5
var magic_aptitude := 0.5
var respect_for_witch := 80.0
var relationships: Dictionary = {}
var known_magic: Dictionary = {
    "Healing": 0,
    "Agriculture": 0,
    "Construction": 0,
    "Weather": 0,
    "Combat": 0,
}

var current_action := "idle"
var target_position := Vector2.ZERO
var home_position := Vector2.ZERO
var work_position := Vector2.ZERO
var plaza_position := Vector2.ZERO
var tavern_position := Vector2.ZERO
var food_position := Vector2.ZERO
var clinic_position := Vector2.ZERO
var clock: GameClock
var rng := RandomNumberGenerator.new()
var decision_cooldown := 0.0

func setup(new_name: String, new_family: String, new_occupation: String, new_age: int, new_generation: int, new_home: Vector2, new_work: Vector2, anchors: Dictionary, game_clock: GameClock) -> void:
    display_name = new_name
    family_name = new_family
    occupation = new_occupation
    age = new_age
    generation = new_generation
    home_position = new_home
    work_position = new_work
    plaza_position = Vector2(anchors.get("plaza", new_home))
    tavern_position = Vector2(anchors.get("tavern", new_home))
    food_position = Vector2(anchors.get("food", new_home))
    clinic_position = Vector2(anchors.get("clinic", new_home))
    clock = game_clock
    rng.seed = hash(display_name + family_name + str(generation))
    sociability = rng.randf_range(0.2, 0.95)
    diligence = rng.randf_range(0.25, 0.95)
    curiosity = rng.randf_range(0.15, 1.0)
    magic_aptitude = rng.randf_range(0.25, 1.0)
    respect_for_witch = rng.randf_range(72.0, 96.0)
    position = home_position
    target_position = position
    queue_redraw()

func _physics_process(delta: float) -> void:
    if clock == null:
        return

    var scaled_delta: float = delta * clock.time_scale
    hunger = clampf(hunger + scaled_delta * 0.11, 0.0, 100.0)
    social_need = clampf(social_need + scaled_delta * (0.035 + sociability * 0.04), 0.0, 100.0)
    energy = clampf(energy + scaled_delta * (0.24 if current_action == "sleep" else -0.075), 0.0, 100.0)

    if hunger > 90.0:
        health = maxf(0.0, health - scaled_delta * 0.035)
    if sick:
        health = maxf(0.0, health - scaled_delta * illness_severity * 0.018)
    elif int(known_magic.get("Healing", 0)) > 0:
        health = minf(100.0, health + scaled_delta * 0.006 * float(known_magic.get("Healing", 0)))

    decision_cooldown -= scaled_delta
    if decision_cooldown <= 0.0:
        decision_cooldown = rng.randf_range(2.0, 5.0)
        choose_action()

    if position.distance_to(target_position) > 5.0:
        velocity = position.direction_to(target_position) * MOVE_SPEED * minf(clock.time_scale, 4.0)
        move_and_slide()
    else:
        velocity = Vector2.ZERO
        perform_action(scaled_delta)

func choose_action() -> void:
    var hour: int = clock.get_hour()
    var work_magic_level: int = get_work_magic_level()
    var scores := {
        "eat": hunger * 1.35,
        "sleep": (100.0 - energy) * 1.25,
        "work": (42.0 + diligence * 18.0) if hour >= 7 and hour < 17 and occupation != "Unemployed" else 10.0,
        "magic_work": (48.0 + diligence * 14.0 + curiosity * 8.0) if hour >= 7 and hour < 17 and work_magic_level > 0 else -50.0,
        "socialize": social_need + sociability * 28.0 + (20.0 if hour >= 18 and hour < 23 else 0.0),
        "seek_healing": (115.0 - health) + illness_severity * 30.0 if sick else -40.0,
        "wander": 10.0 + curiosity * 20.0 + rng.randf_range(0.0, 8.0),
    }

    if hour >= 21 or hour < 5:
        scores["sleep"] = float(scores["sleep"]) + 52.0

    var best_action := "wander"
    var best_score := -999999.0
    for action in scores.keys():
        var score: float = float(scores[action]) + rng.randf_range(-4.0, 4.0)
        if score > best_score:
            best_score = score
            best_action = str(action)
    set_action(best_action)

func set_action(new_action: String) -> void:
    var old_action := current_action
    current_action = new_action
    match new_action:
        "eat": target_position = food_position
        "sleep": target_position = home_position
        "work", "magic_work": target_position = work_position
        "seek_healing": target_position = clinic_position
        "socialize": target_position = tavern_position if rng.randf() < 0.6 else plaza_position
        _: target_position = plaza_position + Vector2(rng.randf_range(-150.0, 150.0), rng.randf_range(-110.0, 110.0))
    if old_action != new_action:
        action_changed.emit(self, old_action, new_action)

func perform_action(delta: float) -> void:
    match current_action:
        "eat":
            hunger = maxf(0.0, hunger - delta * 1.9)
        "socialize":
            social_need = maxf(0.0, social_need - delta * (0.8 + sociability))
        "magic_work":
            energy = maxf(0.0, energy - delta * 0.035)
        "seek_healing":
            health = minf(100.0, health + delta * (0.12 + float(known_magic.get("Healing", 0)) * 0.05))
            if health > 82.0:
                sick = false
                illness_severity = 0.0

func update_magic_knowledge(village_fields: Dictionary) -> void:
    var preferred: String = get_preferred_magic_field()
    for field_value in MAGIC_FIELDS:
        var field_name := str(field_value)
        var village_level: int = int(village_fields.get(field_name, 0))
        if village_level <= 0:
            known_magic[field_name] = 0
            continue

        var multiplier := magic_aptitude * (1.0 if field_name == preferred else 0.55)
        var learned: int = int(floor(float(village_level) * multiplier))
        if field_name == preferred and village_level > 0:
            learned = maxi(1, learned)
        known_magic[field_name] = mini(village_level, learned)
    queue_redraw()

func get_preferred_magic_field() -> String:
    match occupation:
        "Doctor": return "Healing"
        "Farmer", "Baker": return "Agriculture"
        "Carpenter", "Blacksmith": return "Construction"
        "Hunter", "Gatherer": return "Weather"
        "Mayor": return "Combat"
        "Researcher": return str(MAGIC_FIELDS[int(floor(curiosity * float(MAGIC_FIELDS.size()))) % MAGIC_FIELDS.size()])
        "Apprentice": return "Construction" if diligence >= curiosity else "Combat"
        _: return "Healing" if magic_aptitude > 0.75 else "Agriculture"

func get_work_magic_level() -> int:
    return int(known_magic.get(get_preferred_magic_field(), 0))

func initialize_relationship(other_name: String, value: float) -> void:
    if other_name == display_name:
        return
    relationships[other_name] = clampf(value, -100.0, 100.0)

func change_relationship(other_name: String, amount: float) -> float:
    var current: float = float(relationships.get(other_name, 0.0))
    current = clampf(current + amount, -100.0, 100.0)
    relationships[other_name] = current
    return current

func get_relationship(other_name: String) -> float:
    return float(relationships.get(other_name, 0.0))

func socialize_with(other: Villager) -> int:
    if other == null or other == self:
        return 0
    var compatibility: float = 0.5 - absf(sociability - other.sociability) * 0.35 - absf(curiosity - other.curiosity) * 0.25
    var delta: int = 2 if compatibility + rng.randf_range(-0.25, 0.25) >= 0.25 else -2
    change_relationship(other.display_name, float(delta))
    social_need = maxf(0.0, social_need - 18.0)
    return delta

func greet_witch() -> String:
    respect_for_witch = clampf(respect_for_witch + rng.randf_range(0.3, 1.2), 0.0, 100.0)
    social_need = maxf(0.0, social_need - 12.0)
    if respect_for_witch >= 92.0:
        return "%s bows deeply to the immortal witch." % display_name
    if generation >= 3:
        return "%s says their family has told stories about the witch for generations." % display_name
    return "%s greets the village witch with obvious respect." % display_name

func contract_illness(severity: float) -> void:
    sick = true
    illness_severity = clampf(maxf(illness_severity, severity), 0.1, 1.0)
    queue_redraw()

func apply_food_shortage(amount: float) -> void:
    hunger = clampf(hunger + amount, 0.0, 100.0)
    if hunger > 92.0:
        health = maxf(0.0, health - amount * 0.12)

func advance_years(years: int) -> void:
    age += years
    if sick:
        health = maxf(1.0, health - float(years) * illness_severity * 2.0)

func _draw() -> void:
    var skin_color := Color("d6b88b")
    if sick:
        skin_color = Color("b7c692")
    draw_circle(Vector2.ZERO, 7.0, skin_color)
    draw_rect(Rect2(-6.0, 5.0, 12.0, 11.0), Color("6f7f9c"))
    if get_work_magic_level() > 0:
        draw_arc(Vector2.ZERO, 11.0, 0.0, TAU, 20, Color("b99be8"), 1.5)
