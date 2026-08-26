extends Node

signal japanese_font_ready

const WEB_FONT_URL := "https://cdn.jsdelivr.net/gh/notofonts/noto-cjk@Sans2.004/Sans/SubsetOTF/JP/NotoSansJP-Regular.otf"
const WEB_FONT_CACHE := "user://noto_sans_jp_regular.otf"
const MIN_FONT_BYTES := 100000

var japanese_ready := false
var _request: HTTPRequest

func _ready() -> void:
    if not OS.has_feature("web"):
        _install_native_font()
        japanese_ready = true
        return

    var cached: PackedByteArray = _read_bytes(WEB_FONT_CACHE)
    if cached.size() >= MIN_FONT_BYTES and _install_font_bytes(cached):
        japanese_ready = true
        return

    _start_download()

func _install_native_font() -> void:
    var font := SystemFont.new()
    font.font_names = PackedStringArray([
        "Hiragino Sans",
        "Yu Gothic UI",
        "Yu Gothic",
        "Meiryo",
        "Noto Sans CJK JP",
        "Noto Sans JP",
    ])
    font.allow_system_fallback = true
    ThemeDB.fallback_font = font

func _start_download() -> void:
    _request = HTTPRequest.new()
    add_child(_request)
    _request.request_completed.connect(_on_request_completed)
    var error: Error = _request.request(WEB_FONT_URL)
    if error != OK:
        push_warning("Japanese Web font request could not start: %s" % error_string(error))
        _request.queue_free()
        _request = null

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if result != HTTPRequest.RESULT_SUCCESS or response_code != 200 or body.size() < MIN_FONT_BYTES:
        push_warning("Japanese Web font download failed: result=%d status=%d bytes=%d" % [result, response_code, body.size()])
        return

    var file := FileAccess.open(WEB_FONT_CACHE, FileAccess.WRITE)
    if file != null:
        file.store_buffer(body)
        file.close()

    if not _install_font_bytes(body):
        push_warning("Downloaded Japanese Web font could not be installed.")
        return

    japanese_ready = true
    japanese_font_ready.emit()
    call_deferred("_reload_scene_for_japanese")

func _install_font_bytes(bytes: PackedByteArray) -> bool:
    if bytes.size() < MIN_FONT_BYTES:
        return false
    var font := FontFile.new()
    font.data = bytes
    font.allow_system_fallback = false
    ThemeDB.fallback_font = font
    return true

func _read_bytes(path: String) -> PackedByteArray:
    if not FileAccess.file_exists(path):
        return PackedByteArray()
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return PackedByteArray()
    var bytes: PackedByteArray = file.get_buffer(file.get_length())
    file.close()
    return bytes

func _reload_scene_for_japanese() -> void:
    if get_tree().current_scene != null:
        get_tree().reload_current_scene()
