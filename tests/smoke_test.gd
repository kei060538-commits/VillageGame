extends SceneTree

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
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

    if clock == null:
        _fail("game clock was not created")
        return
    if village == null:
        _fail("village simulation was not created")
        return
    if player == null:
        _fail("player was not created")
        return
    if village.villagers.size() != 20:
        _fail("expected 20 initial villagers, got %d" % village.villagers.size())
        return
    if absf(clock.REAL_SECONDS_PER_DAY - 360.0) > 0.001:
        _fail("one day must equal 360 real seconds")
        return

    print("SMOKE TEST PASS: main scene, player, clock, and 20 villagers loaded")
    instance.queue_free()
    quit(0)

func _fail(message: String) -> void:
    push_error("SMOKE TEST FAIL: " + message)
    quit(1)
