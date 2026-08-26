extends Node

signal japanese_font_ready

const WEB_FONT_URL := "https://cdn.jsdelivr.net/npm/typeface-notosans-jp@1.0.1/NotoSansJP-Regular.otf"
const WEB_FONT_CACHE := "user://noto_sans_jp_regular_v2.otf"
const MIN_FONT_BYTES := 1000000
const REQUIRED_JAPANESE_CODEPOINTS := [0x65E5, 0x3042, 0x9B54] # 日, あ, 魔

var japanese_ready := false
var _request: HTTPRequest
var _installed_font: Font

func _ready() -> void:
    if not OS.has_feature("web"):
        _install_native_font()
        japanese_ready = true
        return

    if _install_font_file(WEB_FONT_CACHE):
        japanese_ready = true
        return

    if FileAccess.file_exists(WEB_FONT_CACHE):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(WEB_FONT_CACHE))

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
    _installed_font = font
    ThemeDB.fallback_font = font

func _start_download() -> void:
    _request = HTTPRequest.new()
    add_child(_request)
    _request.request_completed.connect(_on_request_completed)
    var error: Error = _request.request(WEB_FONT_URL)
    if error != OK:
        push_warning("Japanese Web font request could not start: %s" % error_string(error))
        _dispose_request()

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if result != HTTPRequest.RESULT_SUCCESS or response_code != 200 or body.size() < MIN_FONT_BYTES:
        push_warning("Japanese Web font download failed: result=%d status=%d bytes=%d" % [result, response_code, body.size()])
        _dispose_request()
        return

    var file := FileAccess.open(WEB_FONT_CACHE, FileAccess.WRITE)
    if file == null:
        push_warning("Japanese Web font cache could not be written.")
        _dispose_request()
        return

    file.store_buffer(body)
    file.close()

    if not _install_font_file(WEB_FONT_CACHE):
        push_warning("Downloaded Japanese Web font failed glyph validation; keeping English UI.")
        if FileAccess.file_exists(WEB_FONT_CACHE):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(WEB_FONT_CACHE))
        _dispose_request()
        return

    japanese_ready = true
    japanese_font_ready.emit()
    _dispose_request()
    call_deferred("_reload_scene_for_japanese")

func _install_font_file(path: String) -> bool:
    if not FileAccess.file_exists(path):
        return false

    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return false
    var byte_count := file.get_length()
    file.close()
    if byte_count < MIN_FONT_BYTES:
        return false

    var font := FontFile.new()
    var load_error: Error = font.load_dynamic_font(path)
    if load_error != OK or font.data.is_empty():
        push_warning("Japanese font loader rejected %s: %s" % [path, error_string(load_error)])
        return false

    font.allow_system_fallback = false
    for codepoint in REQUIRED_JAPANESE_CODEPOINTS:
        if not font.has_char(int(codepoint)):
            push_warning("Japanese font is missing required codepoint U+%04X" % int(codepoint))
            return false

    _installed_font = font
    ThemeDB.fallback_font = font
    return true

func _dispose_request() -> void:
    if _request != null:
        _request.queue_free()
        _request = null

func _reload_scene_for_japanese() -> void:
    if get_tree().current_scene != null:
        get_tree().reload_current_scene()
