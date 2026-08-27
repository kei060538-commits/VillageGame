extends Node

const WITCH_VISUAL := preload("res://scripts/art/witch_world_visual.gd")

var main_node: Node2D
var village: VillageSimulation
var player: WitchPlayer
var backdrop: Sprite2D

func _ready() -> void:
    call_deferred("_attach_world_art")

func _attach_world_art() -> void:
    main_node = get_parent() as Node2D
    if main_node == null:
        return

    village = main_node.get("village") as VillageSimulation
    player = main_node.get("player") as WitchPlayer
    if village == null or player == null:
        call_deferred("_attach_world_art")
        return

    _attach_village_background()
    _attach_witch_visual()

    if village.has_method("get_visit_spawn_position"):
        player.position = village.get_visit_spawn_position()
    if player.has_method("set_world_size"):
        player.set_world_size(VillageSimulation.WORLD_SIZE)

func _attach_village_background() -> void:
    var texture := VillageArtData.get_texture()
    if texture == null:
        push_warning("Approved village concept art texture is unavailable; procedural village remains active.")
        return

    backdrop = Sprite2D.new()
    backdrop.name = "ApprovedVillageBackdrop"
    backdrop.texture = texture
    backdrop.centered = false
    backdrop.position = Vector2.ZERO
    backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    backdrop.scale = Vector2(
        VillageSimulation.WORLD_SIZE.x / float(texture.get_width()),
        VillageSimulation.WORLD_SIZE.y / float(texture.get_height())
    )
    backdrop.z_index = 0
    village.add_child(backdrop)
    village.move_child(backdrop, 0)

    # Mask the baked showcase witch so only the controllable player appears there.
    var seal := ArrivalSeal.new()
    seal.name = "ArrivalSeal"
    seal.position = VillageSimulation.VISIT_SPAWN_POSITION
    seal.z_index = 1
    village.add_child(seal)
    village.move_child(seal, mini(1, village.get_child_count() - 1))

func _attach_witch_visual() -> void:
    player.self_modulate = Color(1, 1, 1, 0)
    var visual := WITCH_VISUAL.new()
    visual.name = "WitchVisual"
    player.add_child(visual)

class ArrivalSeal:
    extends Node2D

    func _ready() -> void:
        queue_redraw()

    func _draw() -> void:
        draw_circle(Vector2.ZERO, 62.0, Color(0.035, 0.025, 0.09, 0.94))
        draw_arc(Vector2.ZERO, 54.0, 0.0, TAU, 64, Color("8e55e8"), 3.0, true)
        draw_arc(Vector2.ZERO, 43.0, 0.0, TAU, 64, Color("dcb56f"), 1.6, true)
        for ray in range(8):
            var angle := TAU * float(ray) / 8.0
            var inner := Vector2(cos(angle), sin(angle)) * 25.0
            var outer := Vector2(cos(angle), sin(angle)) * 49.0
            draw_line(inner, outer, Color("b891ff"), 1.4, true)
        draw_circle(Vector2.ZERO, 4.0, Color("eeeaff"))
