extends SceneTree

const FONT_PATH := "res://art/fonts/NotoSansJP-Variable.ttf"
const REQUIRED_CODEPOINTS := [0x65E5, 0x3042, 0x9B54] # 日, あ, 魔

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    if not ResourceLoader.exists(FONT_PATH):
        _fail("bundled Japanese TrueType font resource is missing")
        return

    var resource := load(FONT_PATH)
    if not (resource is Font):
        _fail("bundled Japanese TrueType font did not import as Font")
        return

    var font: Font = resource as Font
    for codepoint in REQUIRED_CODEPOINTS:
        if not font.has_char(int(codepoint)):
            _fail("bundled Japanese TrueType font lacks U+%04X" % int(codepoint))
            return

    print("WEB FONT VALIDATION PASS: bundled TrueType font contains Japanese glyphs")
    quit(0)

func _fail(message: String) -> void:
    push_error("WEB FONT VALIDATION FAIL: " + message)
    quit(1)
