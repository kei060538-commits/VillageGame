class_name VillageArtData
extends RefCounted

const CHUNK_0 := preload("res://scripts/art/village_art_chunk_0.gd")
const CHUNK_1 := preload("res://scripts/art/village_art_chunk_1.gd")

static var _texture: Texture2D

static func get_texture() -> Texture2D:
    if _texture != null:
        return _texture

    var encoded := CHUNK_0.DATA + CHUNK_1.DATA
    var bytes := Marshalls.base64_to_raw(encoded)
    if bytes.is_empty():
        push_warning("Embedded village art could not be decoded.")
        return null

    var image := Image.new()
    var error := image.load_jpg_from_buffer(bytes)
    if error != OK:
        push_warning("Embedded village art could not be loaded as JPEG: %s" % error_string(error))
        return null

    _texture = ImageTexture.create_from_image(image)
    return _texture
