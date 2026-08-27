class_name VillageEventLog
extends Node

signal event_added(entry: Dictionary)

const MAX_ENTRIES := 300
var entries: Array[Dictionary] = []

func add_event(message: String, day: int, minute_of_day: int, category: String = "general") -> void:
    var entry := {
        "day": day,
        "minute": minute_of_day,
        "category": category,
        "message": message,
    }
    entries.append(entry)
    if entries.size() > MAX_ENTRIES:
        entries.pop_front()
    event_added.emit(entry)

func latest(count: int = 8) -> Array[Dictionary]:
    var start := maxi(0, entries.size() - count)
    return entries.slice(start, entries.size())

func format_entry(entry: Dictionary) -> String:
    var minute_of_day := int(entry.get("minute", 0))
    var hour := minute_of_day / 60
    var minute := minute_of_day % 60
    return "Day %d %02d:%02d  %s" % [
        int(entry.get("day", 1)),
        hour,
        minute,
        str(entry.get("message", "")),
    ]
