class_name Villager
extends CharacterBody2D

signal action_changed(villager: Villager, old_action: String, new_action: String)

const MOVE_SPEED := 62.0

var display_name := "Villager"
var family_name := ""
var occupation := "Unemployed"
var generation := 1
var age := 25
var hunger := 20.0
var energy := 85.0
var health := 100.0
var social_need := 20.0
var current_action := "idle"
var target_position := Vector2.ZERO
var home_position := Vector2.ZERO
var work_position := Vector2.ZERO
var plaza_position := Vector2.ZERO
var tavern_position := Vector2.ZERO
var food_position := Vector2.ZERO
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
    plaza_position = anchors.get("plaza", new_home)
    tavern_position = anchors.get("tavern", new_home)
    food_position = anchors.get("food", new_home)
    clock = game_clock
    rng.seed = hash(display_name + family_name + str(generation))
    position = home_position
    target_position = position
    queue_redraw()

func _physics_process(delta: float) -> void:
    if clock == null:
        return
    var scaled_delta := delta * clock.time_scale
    hunger = clampf(hunger + scaled_delta * 0.11, 0.0, 100.0)
    social_need = clampf(social_need + scaled_delta * 0.055, 0.0, 100.0)
    energy = clampf(energy + scaled_delta * (0.24 if current_action == "sleep" else -0.075), 0.0, 100.0)
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
    var hour := clock.get_hour()
    var scores := {
        "eat": hunger * 1.35,
        "sleep": (100.0 - energy) * 1.25,
        "work": 52.0 if hour >= 7 and hour < 17 and occupation != "Unemployed" else 12.0,
        "socialize": social_need + (22.0 if hour >= 18 and hour < 23 else 0.0),
        "wander": 12.0 + rng.randf_range(0.0, 12.0),
    }
    if hour >= 21 or hour < 5:
        scores["sleep"] += 52.0
    var best_action := "wander"
    var best_score := -999999.0
    for action in scores.keys():
        var score := float(scores[action]) + rng.randf_range(-4.0, 4.0)
        if score > best_score:
            best_score = score
            best_action = action
    set_action(best_action)

func set_action(new_action: String) -> void:
    var old_action := current_action
    current_action = new_action
    match new_action:
        "eat": target_position = food_position
        "sleep": target_position = home_position
        "work": target_position = work_position
        "socialize": target_position = tavern_position if rng.randf() < 0.6 else plaza_position
        _: target_position = plaza_position + Vector2(rng.randf_range(-150.0, 150.0), rng.randf_range(-110.0, 110.0))
    if old_action != new_action:
        action_changed.emit(self, old_action, new_action)

func perform_action(delta: float) -> void:
    match current_action:
        "eat": hunger = maxf(0.0, hunger - delta * 1.9)
        "socialize": social_need = maxf(0.0, social_need - delta)

func advance_years(years: int) -> void:
    age += years

func _draw() -> void:
    draw_circle(Vector2.ZERO, 7.0, Color("d6b88b"))
    draw_rect(Rect2(-6.0, 5.0, 12.0, 11.0), Color("6f7f9c"))
