extends Node

signal japanese_font_ready

const BUNDLED_WEB_FONT := "res://art/fonts/NotoSansJP-Regular.otf"
const REQUIRED_JAPANESE_CODEPOINTS := [0x65E5, 0x3042, 0x9B54] # 日, あ, 魔

var japanese_ready := false
var _installed_font: Font

func _ready() -> void:
    if OS.has_feature("web"):
        japanese_ready = _install_bundled_web_font()
        if not japanese_ready:
            push_warning("Bundled Japanese Web font is unavailable or invalid; keeping the Web UI in English.")
        return

    _install_native_font()
    japanese_ready = true

func _install_bundled_web_font() -> bool:
    if not ResourceLoader.exists(BUNDLED_WEB_FONT):
        return false

    var font_resource := load(BUNDLED_WEB_FONT)
    if not (font_resource is Font):
        push_warning("Bundled Japanese font did not import as a Font resource.")
        return false

    var font: Font = font_resource as Font
    for codepoint in REQUIRED_JAPANESE_CODEPOINTS:
        if not font.has_char(int(codepoint)):
            push_warning("Bundled Japanese font is missing required codepoint U+%04X" % int(codepoint))
            return false

    _installed_font = font
    ThemeDB.fallback_font = font
    japanese_font_ready.emit()
    return true

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
