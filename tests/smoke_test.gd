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

    var profile: Dictionary = research_panel.get_circle_profile()
    if not bool(profile.get("aligned", false)):
        _fail("healing research should align when the center uses the circle glyph")
        return
    if not profile.has("power") or not profile.has("range") or not profile.has("stability"):
        _fail("magic circle profile is missing semantic puzzle statistics")
        return

    village.magic_fields["Agriculture"] = 2
    first_villager.update_magic_knowledge(village.magic_fields)
    if first_villager.occupation == "Farmer" and first_villager.get_work_magic_level() < 1:
        _fail("farmers should learn agriculture magic when village knowledge exists")
        return

    print("SMOKE TEST PASS: font bootstrap, glyph picker, village, relationships, pressures, and semantic magic-circle research loaded")
    instance.queue_free()
    quit(0)

func _fail(message: String) -> void:
    push_error("SMOKE TEST FAIL: " + message)
    quit(1)
