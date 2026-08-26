extends SceneTree

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    await process_frame

    var ui_font = root.get_node_or_null("UIFont")
    if ui_font == null:
        _fail("UIFont autoload was not created")
        return
    if not bool(ui_font.get("japanese_ready")):
        _fail("native smoke test should initialize a Japanese-capable fallback font")
        return
    if ThemeDB.fallback_font == null:
        _fail("global fallback font was not installed")
        return

    var packed_scene := load("res://scenes/main.tscn") as PackedScene
    if packed_scene == null:
        _fail("main scene could not be loaded")
        return

    var instance := packed_scene.instantiate()
    root.add_child(instance)
    await process_frame
    await process_frame

    var clock = instance.get("clock")
    var village = instance.get("village")
    var player = instance.get("player")
    var research_panel = instance.get("research_panel")

    if clock == null:
        _fail("game clock was not created")
        return
    if village == null:
        _fail("village simulation was not created")
        return
    if player == null:
        _fail("player was not created")
        return
    if research_panel == null:
        _fail("magic research panel was not created")
        return
    if not bool(research_panel.get("japanese_ui")):
        _fail("native research UI should use Japanese when the fallback font is ready")
        return
    if village.villagers.size() != 20:
        _fail("expected 20 initial villagers, got %d" % village.villagers.size())
        return
    if absf(clock.REAL_SECONDS_PER_DAY - 360.0) > 0.001:
        _fail("one day must equal 360 real seconds")
        return

    var initial_request: Dictionary = research_panel.get("village_request")
    if str(initial_request.get("field", "")) != "Healing":
        _fail("the first village request should establish basic healing magic")
        return
    if research_panel.get_current_field() != "Healing":
        _fail("the first research challenge should follow the village healing request")
        return

    var severe_threat_request: Dictionary = ResearchRequestPlanner.choose_request(
        72.0,
        4.0,
        90.0,
        {"Healing": 1, "Agriculture": 0, "Construction": 0, "Weather": 0, "Combat": 0},
        1
    )
    if str(severe_threat_request.get("field", "")) != "Combat":
        _fail("an undefended village under severe monster threat should request combat research")
        return

    var ward_request: Dictionary = ResearchRequestPlanner.choose_request(
        72.0,
        4.0,
        90.0,
        {"Healing": 1, "Agriculture": 0, "Construction": 0, "Weather": 0, "Combat": 1},
        2
    )
    if str(ward_request.get("field", "")) != "Construction":
        _fail("after combat knowledge exists, severe monster threat should also drive ward construction")
        return

    var first_villager = village.villagers[0]
    if first_villager.relationships.size() < 18:
        _fail("initial villagers should know most other villagers")
        return
    if village.food_security <= 0.0 or village.disease_pressure < 0.0:
        _fail("village pressure systems were not initialized")
        return

    research_panel.call("_open_glyph_picker", 4)
    var glyph_picker = research_panel.get("glyph_picker")
    if glyph_picker == null or not glyph_picker.visible:
        _fail("tapping a magic-circle slot should open the glyph picker")
        return
    if int(research_panel.get("selected_slot")) != 4:
        _fail("glyph picker should remember the selected magic-circle slot")
        return
    research_panel.call("_choose_glyph", 1)
    if int(research_panel.glyph_states[4]) != 1:
        _fail("choosing a glyph should update the selected slot")
        return
    if glyph_picker.visible:
        _fail("glyph picker should close after a glyph is chosen")
        return

    var profile_before_rotation: Dictionary = research_panel.get_circle_profile()
    research_panel.call("_open_glyph_picker", 4)
    research_panel.call("_rotate_selected", 1)
    if int(research_panel.glyph_rotations[4]) != 1:
        _fail("rotation controls should rotate the selected glyph by one quarter turn")
        return
    var profile_after_rotation: Dictionary = research_panel.get_circle_profile()
    if int(profile_after_rotation.get("duration", 0)) <= int(profile_before_rotation.get("duration", 0)):
        _fail("clockwise glyph rotation should contribute to spell duration")
        return

    research_panel.call("_open_glyph_picker", 1)
    research_panel.call("_choose_glyph", 1)
    var profile_before_link: Dictionary = research_panel.get_circle_profile()
    research_panel.call("_toggle_connection", 4, 1)
    if research_panel.connections.size() != 1:
        _fail("drag wiring should create one normalized mana link")
        return
    var profile_after_link: Dictionary = research_panel.get_circle_profile()
    if int(profile_after_link.get("links", 0)) != 1:
        _fail("magic-circle profile should count active mana links")
        return
    if int(profile_after_link.get("stability", 0)) <= int(profile_before_link.get("stability", 0)):
        _fail("matching linked glyphs should improve spell stability")
        return

    var profile: Dictionary = research_panel.get_circle_profile()
    if not bool(profile.get("aligned", false)):
        _fail("healing research should align when the center uses the circle glyph")
        return
    if not profile.has("power") or not profile.has("range") or not profile.has("stability") or not profile.has("links"):
        _fail("magic circle profile is missing semantic puzzle statistics")
        return

    village.magic_fields["Agriculture"] = 2
    first_villager.update_magic_knowledge(village.magic_fields)
    if first_villager.occupation == "Farmer" and first_villager.get_work_magic_level() < 1:
        _fail("farmers should learn agriculture magic when village knowledge exists")
        return

    print("SMOKE TEST PASS: font bootstrap, village requests, glyph picker, rotation, mana links, relationships, pressures, and semantic research loaded")
    instance.queue_free()
    quit(0)

func _fail(message: String) -> void:
    push_error("SMOKE TEST FAIL: " + message)
    quit(1)
