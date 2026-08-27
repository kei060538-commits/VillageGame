# Web Japanese font

The Web preview cannot rely on Godot system-font fallback because system font loading is not implemented for Web exports.

To keep the repository small while still rendering Japanese on phones, the Web build fetches the Japanese subset of **Noto Sans CJK JP Regular** on first use and caches it in `user://`.

- Source project: notofonts/noto-cjk
- Pinned release: `Sans2.004`
- Runtime asset: `Sans/SubsetOTF/JP/NotoSansJP-Regular.otf`
- Delivery: jsDelivr GitHub CDN
- License: SIL Open Font License 1.1, as distributed by the Noto CJK project

Native iOS/macOS/Windows/Linux builds use an installed Japanese system font instead and do not need this download.

If the Web font request fails, the prototype remains usable in its English fallback UI rather than displaying missing-glyph boxes.
