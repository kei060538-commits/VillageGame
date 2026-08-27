class_name ResearchRequestPlanner
extends RefCounted

const FIELDS := ["Healing", "Agriculture", "Construction", "Weather", "Combat"]

static func choose_request(
    food_security: float,
    disease_pressure: float,
    monster_threat: float,
    magic_fields: Dictionary,
    research_level: int
) -> Dictionary:
    var healing: int = int(magic_fields.get("Healing", 0))
    var agriculture: int = int(magic_fields.get("Agriculture", 0))
    var construction: int = int(magic_fields.get("Construction", 0))
    var weather: int = int(magic_fields.get("Weather", 0))
    var combat: int = int(magic_fields.get("Combat", 0))

    if research_level <= 0 and healing <= 0:
        return _request(
            "clinic-foundation",
            "Healing",
            "診療所からの依頼",
            "CLINIC REQUEST",
            "傷や病に備える基礎治癒術が必要とされている。",
            "The clinic needs a basic healing art for wounds and illness.",
            1
        )

    if monster_threat >= 70.0:
        if combat <= construction:
            return _request(
                "monster-surge",
                "Combat",
                "狩人からの急報",
                "HUNTER WARNING",
                "森の魔物が急増している。村を守る戦闘術式が必要だ。",
                "Monsters are surging near the forest. The village needs a combat art.",
                3
            )
        return _request(
            "ward-reinforcement",
            "Construction",
            "村長からの依頼",
            "MAYOR REQUEST",
            "襲撃に備え、防壁と結界を強化する構築術式が求められている。",
            "The mayor wants stronger walls and wards before the next attack.",
            3
        )

    if disease_pressure >= 42.0:
        return _request(
            "disease-wave",
            "Healing",
            "診療所からの急報",
            "CLINIC WARNING",
            "病が広がり始めた。より強い治癒術式が必要だ。",
            "Illness is spreading. The clinic needs a stronger healing art.",
            3
        )

    if food_security <= 42.0:
        if agriculture <= weather:
            return _request(
                "food-shortage",
                "Agriculture",
                "農家からの依頼",
                "FARM REQUEST",
                "備蓄が減っている。収穫量を底上げする農耕術式が必要だ。",
                "Food stores are falling. Farmers need magic that improves the harvest.",
                3
            )
        return _request(
            "weather-shortage",
            "Weather",
            "農家からの依頼",
            "FARM REQUEST",
            "不安定な天候が畑を痛めている。気象術式で季節を支えたい。",
            "Unstable weather is hurting the fields. Farmers need weather magic.",
            2
        )

    if monster_threat >= 32.0:
        if construction <= combat:
            return _request(
                "early-wards",
                "Construction",
                "村長からの相談",
                "MAYOR REQUEST",
                "魔物の気配が増えている。今のうちに防壁と結界を整えたい。",
                "Monster signs are increasing. The mayor wants defensive wards prepared early.",
                2
            )
        return _request(
            "hunter-preparation",
            "Combat",
            "狩人からの相談",
            "HUNTER REQUEST",
            "森の奥で強い魔物が目撃された。対処できる戦闘術式を備えたい。",
            "Hunters spotted stronger monsters deeper in the forest and want a combat art ready.",
            2
        )

    if disease_pressure >= 18.0:
        return _request(
            "clinic-prevention",
            "Healing",
            "診療所からの相談",
            "CLINIC REQUEST",
            "体調を崩す村人が増えている。流行前に治癒術を改良したい。",
            "More villagers are falling ill. The clinic wants better healing before an outbreak.",
            2
        )

    if food_security <= 65.0:
        if agriculture <= weather:
            return _request(
                "harvest-support",
                "Agriculture",
                "農家からの相談",
                "FARM REQUEST",
                "今年の収穫には余裕が少ない。農耕術式を改良して備えたい。",
                "This harvest has little margin. Farmers want stronger agriculture magic.",
                1
            )
        return _request(
            "season-support",
            "Weather",
            "農家からの相談",
            "FARM REQUEST",
            "畑を安定させるため、雨と風を整える気象術式が求められている。",
            "Farmers want weather magic that steadies rain and wind around the fields.",
            1
        )

    var lowest_field: String = str(FIELDS[0])
    var lowest_level: int = int(magic_fields.get(lowest_field, 0))
    for field_name in FIELDS:
        var level: int = int(magic_fields.get(field_name, 0))
        if level < lowest_level:
            lowest_level = level
            lowest_field = str(field_name)

    return _quiet_request(lowest_field)

static func _quiet_request(field_name: String) -> Dictionary:
    match field_name:
        "Healing":
            return _request("quiet-healing", field_name, "診療所からの研究依頼", "CLINIC RESEARCH", "平穏なうちに治癒術の基礎を深めておきたい。", "The clinic wants deeper healing knowledge while the village is calm.", 0)
        "Agriculture":
            return _request("quiet-agriculture", field_name, "農家からの研究依頼", "FARM RESEARCH", "次の世代のため、より安定した農耕術式を残したい。", "Farmers want a more reliable agriculture art for future generations.", 0)
        "Construction":
            return _request("quiet-construction", field_name, "村長からの研究依頼", "MAYOR RESEARCH", "村の建物と結界を長く保つ構築術式を研究したい。", "The mayor wants construction magic that keeps buildings and wards sound for decades.", 0)
        "Weather":
            return _request("quiet-weather", field_name, "農家からの研究依頼", "WEATHER RESEARCH", "季節の変化を穏やかにする気象術式を研究したい。", "Farmers want weather magic that softens harsh seasonal changes.", 0)
        "Combat":
            return _request("quiet-combat", field_name, "狩人からの研究依頼", "HUNTER RESEARCH", "大きな脅威が来る前に、戦闘術式を磨いておきたい。", "Hunters want better combat magic before a major threat arrives.", 0)
        _:
            return _request("quiet-generic", "Healing", "村からの研究依頼", "VILLAGE RESEARCH", "村の暮らしを支える新しい魔法が求められている。", "The village is asking for a new practical magic art.", 0)

static func _request(
    id: String,
    field_name: String,
    title_jp: String,
    title_en: String,
    detail_jp: String,
    detail_en: String,
    severity: int
) -> Dictionary:
    return {
        "id": id,
        "field": field_name,
        "title_jp": title_jp,
        "title_en": title_en,
        "detail_jp": detail_jp,
        "detail_en": detail_en,
        "severity": severity,
    }
