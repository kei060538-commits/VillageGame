class_name GameClock
extends Node

signal minute_changed(day: int, minute_of_day: int)
signal day_changed(day: int)
signal year_changed(year: int)
signal years_skipped(years: int, from_year: int, to_year: int)

const REAL_SECONDS_PER_DAY := 360.0
const GAME_MINUTES_PER_DAY := 1440.0
const DAYS_PER_YEAR := 24

var time_scale := 1.0
var total_minutes := 8.0 * 60.0

var _last_minute := -1
var _last_day := -1
var _last_year := -1

func _ready() -> void:
    _sync_signals(true)

func _process(delta: float) -> void:
    total_minutes += delta * time_scale * GAME_MINUTES_PER_DAY / REAL_SECONDS_PER_DAY
    _sync_signals(false)

func get_day() -> int:
    return int(total_minutes / GAME_MINUTES_PER_DAY) + 1

func get_day_of_year() -> int:
    return ((get_day() - 1) % DAYS_PER_YEAR) + 1

func get_year() -> int:
    return int((get_day() - 1) / DAYS_PER_YEAR) + 1

func get_minute_of_day() -> int:
    return int(total_minutes) % int(GAME_MINUTES_PER_DAY)

func get_hour() -> int:
    return get_minute_of_day() / 60

func get_minute() -> int:
    return get_minute_of_day() % 60

func format_time() -> String:
    return "Year %d  Day %d  %02d:%02d" % [get_year(), get_day_of_year(), get_hour(), get_minute()]

func set_speed(multiplier: float) -> void:
    time_scale = clampf(multiplier, 0.0, 32.0)

func fast_forward_years(years: int) -> void:
    if years <= 0:
        return
    var from_year := get_year()
    total_minutes += float(years * DAYS_PER_YEAR) * GAME_MINUTES_PER_DAY
    var to_year := get_year()
    _sync_signals(true)
    years_skipped.emit(years, from_year, to_year)

func _sync_signals(force: bool) -> void:
    var minute_of_day := get_minute_of_day()
    var day := get_day()
    var year := get_year()

    if force or minute_of_day != _last_minute:
        _last_minute = minute_of_day
        minute_changed.emit(day, minute_of_day)
    if force or day != _last_day:
        _last_day = day
        day_changed.emit(day)
    if force or year != _last_year:
        _last_year = year
        year_changed.emit(year)
