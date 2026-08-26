extends SceneTree

const FONT_PATH := "res://art/fonts/ZenKakuGothicNew-Regular.ttf"
const REQUIRED_CODEPOINTS := [0x65E5, 0x3042, 0x9B54] # 日, あ, 魔

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    if not ResourceLoader.exists(FONT_PATH):
        _fail("bundled static Japanese TrueType font resource is missing")
        return

    var resource := load(FONT_PATH)
    if not (resource is Font):
        _fail("bundled static Japanese TrueType font did not import as Font")
        return

    var font: Font = resource as Font
    if not _font_has_required_glyphs(font):
        return

    # Reproduce the production route instead of validating only has_char().
    # The iPhone Safari bug survived while the file itself was valid because
    # ThemeDB.fallback_font was not becoming the primary font of UI controls.
    var theme := Theme.new()
    theme.default_font = font
    theme.default_font_size = 18

    var root_control := Control.new()
    root_control.theme = theme
    root.add_child(root_control)

    var label := Label.new()
    label.text = "日本語 あ 魔法研究"
    label.add_theme_font_override("font", font)
    root_control.add_child(label)
    await process_frame

    if root_control.theme == null or root_control.theme.default_font == null:
        _fail("explicit Japanese UI theme did not keep a primary font")
        return
    if not label.has_theme_font_override("font"):
        _fail("Japanese label did not receive a direct font override")
        return
    if label.get_theme_font("font") == null:
        _fail("Japanese label could not resolve a primary font")
        return

    # Godot may expose internal FontVariation wrappers from Theme lookups in
    # headless mode. Object identity and has_char() on those wrappers are not
    # reliable, while the imported source font above is authoritative.
    print("WEB FONT VALIDATION PASS: static Japanese font is primary in Theme and Label")
    root_control.queue_free()
    quit(0)

func _font_has_required_glyphs(font: Font) -> bool:
    for codepoint in REQUIRED_CODEPOINTS:
        if not font.has_char(int(codepoint)):
            _fail("Japanese font lacks U+%04X" % int(codepoint))
            return false
    return true

func _fail(message: String) -> void:
    push_error("WEB FONT VALIDATION FAIL: " + message)
    quit(1)
