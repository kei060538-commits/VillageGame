extends Node

signal japanese_font_ready

const BUNDLED_WEB_FONT := "res://art/fonts/ZenKakuGothicNew-Regular.ttf"
const REQUIRED_JAPANESE_CODEPOINTS := [0x65E5, 0x3042, 0x9B54] # 日, あ, 魔

var japanese_ready := false
var _installed_font: Font
var _ui_theme: Theme

func _ready() -> void:
    if OS.has_feature("web"):
        japanese_ready = _install_bundled_web_font()
        if not japanese_ready:
            push_warning("Bundled Japanese Web font is unavailable or invalid; keeping the Web UI in English.")
            return
    else:
        _install_native_font()
        japanese_ready = true

    _build_ui_theme()
    get_tree().node_added.connect(_on_node_added)
    call_deferred("_apply_to_existing_tree")
    japanese_font_ready.emit()

func get_ui_font() -> Font:
    return _installed_font

func get_ui_theme() -> Theme:
    if _ui_theme == null and _installed_font != null:
        _build_ui_theme()
    return _ui_theme

func apply_to(root_control: Control, force_text_controls: bool = true) -> bool:
    if root_control == null or _installed_font == null:
        return false

    if _ui_theme == null:
        _build_ui_theme()
    if _ui_theme == null:
        return false

    # ThemeDB.fallback_font was not sufficient on iPhone Safari: the engine's
    # default font still produced tofu. Assign a real Theme.default_font and
    # make the bundled font the primary font of every text-bearing Control.
    root_control.theme = _ui_theme
    if force_text_controls:
        _apply_font_overrides(root_control)
    return true

func _on_node_added(node: Node) -> void:
    if not (node is Control) or _installed_font == null:
        return
    _apply_control(node as Control)

func _apply_to_existing_tree() -> void:
    if _installed_font == null:
        return
    _apply_existing_children(get_tree().root)

func _apply_existing_children(node: Node) -> void:
    if node is Control:
        _apply_control(node as Control)
    for child in node.get_children():
        _apply_existing_children(child)

func _apply_control(control: Control) -> void:
    if _ui_theme == null:
        _build_ui_theme()
    if _ui_theme == null:
        return

    # Root UI controls receive the shared theme. Descendants inherit it, while
    # text controls also get a direct override to avoid browser fallback paths.
    if not (control.get_parent() is Control):
        control.theme = _ui_theme
    _apply_font_override_to_control(control)

func _apply_font_override_to_control(control: Control) -> void:
    if control is RichTextLabel:
        var rich_text := control as RichTextLabel
        for theme_name in ["normal_font", "bold_font", "italics_font", "bold_italics_font", "mono_font"]:
            rich_text.add_theme_font_override(theme_name, _installed_font)
    elif control is Label or control is Button or control is LineEdit or control is TextEdit or control is ItemList or control is Tree:
        control.add_theme_font_override("font", _installed_font)

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

func _build_ui_theme() -> void:
    if _installed_font == null:
        _ui_theme = null
        return

    var theme := Theme.new()
    theme.default_font = _installed_font
    theme.default_font_size = 16
    _ui_theme = theme

func _apply_font_overrides(node: Node) -> void:
    if node is Control:
        _apply_font_override_to_control(node as Control)
    for child in node.get_children():
        _apply_font_overrides(child)
