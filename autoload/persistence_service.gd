extends Node
class_name PersistenceService

const SignalHub := preload("res://autoload/signal_hub.gd")

const SAVE_DIRECTORY := "user://claw_and_snackle"
const DEFAULT_SAVE_FILE := "save_v1.dat"
const BACKUP_SAVE_FILE := "save_v1.bak"
const TEMP_SUFFIX := ".tmp"
const FILE_MAGIC := "CMSV"
const FILE_VERSION := 1
const SCHEMA_VERSION := 1
const RUN_HISTORY_LIMIT := 25

const SALT_SIZE := 16
const IV_SIZE := 16
const AES_BLOCK_SIZE := 16
const KEY_LENGTH := 32
const HMAC_LENGTH := 32
const PBKDF2_ITERATIONS := 12000

signal save_failed(message: String)
signal save_completed()

static var _instance: PersistenceService

var _state: Dictionary = {}
var _dirty: bool = false
var _pending_flush: bool = false
var _flush_delay_sec: float = 0.5
var _override_save_path: String = ""
var _crypto := Crypto.new()
var _save_mutex := Mutex.new()
var _hub: SignalHub

func _ready() -> void:
	_instance = self
	_hub = SignalHub.get_instance()
	_state = _make_default_state()
	_load_from_disk()

static func get_instance() -> PersistenceService:
	return _instance

func set_override_save_path(path: String) -> void:
	_override_save_path = path
	if _override_save_path == "":
		return
	var base_dir := ProjectSettings.globalize_path(_override_save_path).get_base_dir()
	if base_dir != "":
		DirAccess.make_dir_recursive_absolute(base_dir)

func replace_state(new_state: Dictionary) -> void:
	_save_mutex.lock()
	_state = _initialize_state(new_state)
	_dirty = true
	_save_mutex.unlock()

func queue_flush() -> void:
	if not _dirty or _pending_flush:
		return
	_pending_flush = true
	var tree := get_tree()
	if tree == null:
		flush_now()
		return
	var timer := tree.create_timer(_flush_delay_sec)
	timer.timeout.connect(_on_flush_timeout, CONNECT_ONE_SHOT)

func flush_now() -> void:
	_on_flush_timeout()

func flush_if_dirty() -> void:
	if _dirty:
		_on_flush_timeout()

func set_tutorial_completion(completed: bool, metadata: Dictionary = {}) -> void:
	var tutorial := _state.get("tutorial", {}) as Dictionary
	tutorial["completed"] = bool(completed)
	tutorial["context"] = String(metadata.get("context", completed ? "complete" : "reset"))
	tutorial["completed_at_ms"] = int(metadata.get("completed_at_ms", Time.get_ticks_msec()))
	_state["tutorial"] = tutorial
	_mark_dirty()

func is_tutorial_completed() -> bool:
	var tutorial := _state.get("tutorial", {}) as Dictionary
	return bool(tutorial.get("completed", false))

func get_tutorial_state() -> Dictionary:
	return (_state.get("tutorial", {}) as Dictionary).duplicate(true)

func set_reduced_motion_enabled(enabled: bool) -> void:
	var accessibility := _state.get("accessibility", {}) as Dictionary
	if bool(accessibility.get("reduced_motion", false)) == bool(enabled):
		return
	accessibility["reduced_motion"] = bool(enabled)
	_state["accessibility"] = accessibility
	_mark_dirty()

func is_reduced_motion_enabled() -> bool:
	var accessibility := _state.get("accessibility", {}) as Dictionary
	return bool(accessibility.get("reduced_motion", false))

func set_colorblind_palette(palette: StringName) -> void:
	var accessibility := _state.get("accessibility", {}) as Dictionary
	if StringName(accessibility.get("palette", StringName("default"))) == palette:
		return
	accessibility["palette"] = String(palette)
	_state["accessibility"] = accessibility
	_mark_dirty()

func get_accessibility_state() -> Dictionary:
	return (_state.get("accessibility", {}) as Dictionary).duplicate(true)

func set_control_settings(settings: Dictionary) -> void:
	var controls := settings.duplicate(true)
	controls["haptics_enabled"] = bool(controls.get("haptics_enabled", true))
	controls["haptic_strength"] = clampf(float(controls.get("haptic_strength", 1.0)), 0.0, 1.0)
	controls["camera_sensitivity"] = clampf(float(controls.get("camera_sensitivity", 1.0)), 0.5, 2.0)
	controls["invert_x"] = bool(controls.get("invert_x", false))
	controls["invert_y"] = bool(controls.get("invert_y", false))
	controls["subtitles_enabled"] = bool(controls.get("subtitles_enabled", false))
	controls["caption_size"] = String(controls.get("caption_size", "medium"))
	_state["controls"] = controls
	_mark_dirty()

func get_control_settings() -> Dictionary:
	return (_state.get("controls", {}) as Dictionary).duplicate(true)

func set_audio_settings(settings: Dictionary) -> void:
	var audio := settings.duplicate(true)
	audio["master"] = clampf(float(audio.get("master", 1.0)), 0.0, 1.0)
	audio["music"] = clampf(float(audio.get("music", 1.0)), 0.0, 1.0)
	audio["sfx"] = clampf(float(audio.get("sfx", 1.0)), 0.0, 1.0)
	_state["audio"] = audio
	_mark_dirty()

func get_audio_settings() -> Dictionary:
	return (_state.get("audio", {}) as Dictionary).duplicate(true)

func append_run_record(record: Dictionary) -> Dictionary:
	var runs: Array = _state.get("runs", []) as Array
	var entry := record.duplicate(true)
	if not entry.has("timestamp_sec"):
		entry["timestamp_sec"] = Time.get_unix_time_from_system()
	if not entry.has("duration_sec"):
		entry["duration_sec"] = float(entry.get("duration_sec", 0.0))
	runs.insert(0, entry)
	if runs.size() > RUN_HISTORY_LIMIT:
		runs.resize(RUN_HISTORY_LIMIT)
	_state["runs"] = runs
	var summary := _recalculate_summary(runs)
	_state["summary"] = summary
	_mark_dirty()
	var result := {
		"high_score": int(summary.get("high_score", 0)),
		"previous_high_score": int(summary.get("previous_high_score", 0)),
		"summary": summary.duplicate(true),
	}
	_notify_summary(summary)
	return result

func get_run_records(limit: int = 0) -> Array:
	var runs: Array = _state.get("runs", []) as Array
	var selection: Array = runs
	if limit > 0 and runs.size() > limit:
		selection = runs.slice(0, limit)
	var copy: Array = []
	for run in selection:
		if run is Dictionary:
			copy.append((run as Dictionary).duplicate(true))
	return copy

func get_records_summary() -> Dictionary:
	var summary := _state.get("summary", {}) as Dictionary
	return summary.duplicate(true)

func get_save_state() -> Dictionary:
	return _state.duplicate(true)

func _on_flush_timeout() -> void:
	var snapshot: Dictionary
	var dirty := false
	_save_mutex.lock()
	if _dirty:
		snapshot = _state.duplicate(true)
		dirty = true
		_dirty = false
	_pending_flush = false
	_save_mutex.unlock()
	if not dirty:
		return
	var result := _write_snapshot(snapshot)
	if result != OK:
		var message := "Failed to write save file (err=%d)" % result
		save_failed.emit(message)
		if _hub:
			_hub.broadcast_save_failed(result, message)
	else:
		save_completed.emit()

func _mark_dirty() -> void:
	_save_mutex.lock()
	_dirty = true
	_save_mutex.unlock()
	queue_flush()

func _write_snapshot(snapshot: Dictionary) -> int:
	var path := _resolve_save_path()
	if path == "":
		return ERR_INVALID_DATA
	var payload := snapshot.duplicate(true)
	payload["schema_version"] = SCHEMA_VERSION
	payload["saved_at_ms"] = Time.get_ticks_msec()
	var data := _serialize_payload(payload)
	if data.is_empty():
		return ERR_CANT_CREATE
	var tmp_path := path + TEMP_SUFFIX
	var dir_path := ProjectSettings.globalize_path(path).get_base_dir()
	if dir_path != "":
		var mk_err := DirAccess.make_dir_recursive_absolute(dir_path)
		if mk_err != OK and mk_err != ERR_ALREADY_EXISTS:
			return mk_err
	var tmp_file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if tmp_file == null:
		return ERR_CANT_CREATE
	tmp_file.store_buffer(data)
	tmp_file.flush()
	tmp_file.close()
	var backup_path := _resolve_backup_path()
	if FileAccess.file_exists(path):
		var copy_err := FileAccess.copy(path, backup_path)
		if copy_err != OK:
			push_warning("PersistenceService: failed to copy backup (%d)" % copy_err)
	var remove_err := DirAccess.remove_absolute(path)
	if remove_err != OK and remove_err != ERR_DOES_NOT_EXIST:
		push_warning("PersistenceService: failed to remove old save (%d)" % remove_err)
	var rename_err := DirAccess.rename_absolute(tmp_path, path)
	if rename_err != OK:
		return rename_err
	return OK

func _serialize_payload(payload: Dictionary) -> PackedByteArray:
	var json := JSON.stringify(payload, "\t")
	var plain := json.to_utf8_buffer()
	var salt := _crypto.generate_random_bytes(SALT_SIZE)
	var iv := _crypto.generate_random_bytes(IV_SIZE)
	var key := _derive_key(_get_master_passphrase(), salt, KEY_LENGTH)
	if key.size() != KEY_LENGTH:
		return PackedByteArray()
	var aes := AESContext.new()
	var start_result := aes.start(AESContext.MODE_ENCRYPT, key, iv)
	if start_result != OK:
		return PackedByteArray()
	var padded := _apply_pkcs7(plain)
	var cipher := aes.update(padded)
	cipher.append_array(aes.finish())
	var body := PackedByteArray()
	body.append_array(salt)
	body.append_array(iv)
	body.append_array(cipher)
	var hmac := _crypto.hmac_sha256(key, body)
	var header := PackedByteArray()
	header.append_array(FILE_MAGIC.to_utf8_buffer())
	header.append(FILE_VERSION)
	header.append_array(body)
	header.append_array(hmac)
	return header

func _load_from_disk() -> void:
	var path := _resolve_save_path()
	if path == "":
		return
	var data := FileAccess.get_file_as_bytes(path)
	if data.is_empty():
		var backup := FileAccess.get_file_as_bytes(_resolve_backup_path())
		if not backup.is_empty():
			data = backup
	if data.is_empty():
		return
	var loaded := _deserialize_payload(data)
	if loaded.is_empty():
		_signal_failure("Save data invalid or corrupted; reverting to defaults")
		return
	_state = _initialize_state(loaded)

func _deserialize_payload(buffer: PackedByteArray) -> Dictionary:
	var magic_len := FILE_MAGIC.length()
	var header_len := magic_len + 1
	if buffer.size() <= header_len + SALT_SIZE + IV_SIZE + HMAC_LENGTH:
		return {}
	var magic := buffer.slice(0, magic_len).get_string_from_utf8()
	if magic != FILE_MAGIC:
		return {}
	var version := buffer[magic_len]
	if version > FILE_VERSION:
		push_warning("PersistenceService: unsupported save version %d" % version)
	var body_start := header_len
	var body_end := buffer.size() - HMAC_LENGTH
	var body := buffer.slice(body_start, body_end)
	if body.size() <= SALT_SIZE + IV_SIZE:
		return {}
	var salt := body.slice(0, SALT_SIZE)
	var iv := body.slice(SALT_SIZE, SALT_SIZE + IV_SIZE)
	var cipher := body.slice(SALT_SIZE + IV_SIZE, body.size())
	var hmac := buffer.slice(body_end, buffer.size())
	var key := _derive_key(_get_master_passphrase(), salt, KEY_LENGTH)
	if key.size() != KEY_LENGTH:
		return {}
	var expected_hmac := _crypto.hmac_sha256(key, body)
	if expected_hmac != hmac:
		return {}
	var aes := AESContext.new()
	var start_result := aes.start(AESContext.MODE_DECRYPT, key, iv)
	if start_result != OK:
		return {}
	var padded := aes.update(cipher)
	padded.append_array(aes.finish())
	var plain := _remove_pkcs7(padded)
	if plain.is_empty():
		return {}
	var json_string := plain.get_string_from_utf8()
	var parsed := JSON.parse_string(json_string)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary

func _initialize_state(source: Dictionary) -> Dictionary:
	var defaults := _make_default_state()
	return _deep_merge(defaults, source)

func _make_default_state() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"tutorial": {
			"completed": false,
			"context": "bootstrap",
			"completed_at_ms": 0,
		},
		"accessibility": {
			"reduced_motion": false,
			"palette": "default",
		},
		"controls": {},
		"audio": {},
		"runs": [],
		"summary": _default_summary(),
	}

func _default_summary() -> Dictionary:
	return {
		"high_score": 0,
		"previous_high_score": 0,
		"best_wave": 0,
		"fastest_duration_sec": 0.0,
		"last_run": {},
		"previous_score": 0,
	}

func _recalculate_summary(runs: Array) -> Dictionary:
	var summary := _default_summary()
	if runs.is_empty():
		return summary
	var high_score := 0
	var previous_high := 0
	var best_wave := 0
	var fastest := 0.0
	for i in runs.size():
		var run := runs[i] as Dictionary
		if not run:
			continue
		var score := int(run.get("score", 0))
		if score > high_score:
			previous_high = high_score
			high_score = score
		elif score > previous_high:
			previous_high = score
		var wave := int(run.get("wave", 0))
		if wave > best_wave:
			best_wave = wave
		var duration := float(run.get("duration_sec", 0.0))
		if duration > 0.0 and (fastest <= 0.0 or duration < fastest):
			fastest = duration
	if runs.size() > 1 and runs[1] is Dictionary:
		summary["previous_score"] = int((runs[1] as Dictionary).get("score", 0))
	else:
		summary["previous_score"] = 0
	summary["high_score"] = high_score
	summary["previous_high_score"] = previous_high
	summary["best_wave"] = best_wave
	summary["fastest_duration_sec"] = fastest
	summary["last_run"] = (runs[0] as Dictionary).duplicate(true)
	return summary

func _notify_summary(summary: Dictionary) -> void:
	if _hub == null:
		return
	var high_score := int(summary.get("high_score", 0))
	var previous_high := int(summary.get("previous_high_score", 0))
	_hub.broadcast_run_summary(summary.duplicate(true))
	if high_score > previous_high:
		_hub.broadcast_high_score_updated(high_score, previous_high)

func _deep_merge(target: Dictionary, source: Dictionary) -> Dictionary:
	var result := target.duplicate(true)
	for key in source.keys():
		var value := source[key]
		if result.has(key) and result[key] is Dictionary and value is Dictionary:
			result[key] = _deep_merge(result[key], value)
		else:
			result[key] = value
	return result

func _apply_pkcs7(data: PackedByteArray) -> PackedByteArray:
	var padded := data.duplicate()
	var padding := AES_BLOCK_SIZE - (padded.size() % AES_BLOCK_SIZE)
	if padding == 0:
		padding = AES_BLOCK_SIZE
	for _i in padding:
		padded.append(padding)
	return padded

func _remove_pkcs7(data: PackedByteArray) -> PackedByteArray:
	if data.is_empty():
		return PackedByteArray()
	var padding := data[data.size() - 1]
	if padding <= 0 or padding > AES_BLOCK_SIZE or padding > data.size():
		return PackedByteArray()
	for i in range(data.size() - padding, data.size()):
		if data[i] != padding:
			return PackedByteArray()
	return data.slice(0, data.size() - padding)

func _derive_key(passphrase: String, salt: PackedByteArray, length: int) -> PackedByteArray:
	var password_bytes := passphrase.to_utf8_buffer()
	if _crypto.has_method("derive_pbkdf2_hmac_sha256"):
		return _crypto.derive_pbkdf2_hmac_sha256(password_bytes, salt, PBKDF2_ITERATIONS, length)
	if _crypto.has_method("pbkdf2_hmac_sha256"):
		return _crypto.pbkdf2_hmac_sha256(password_bytes, salt, PBKDF2_ITERATIONS, length)
	var digest := _crypto.hmac_sha256(password_bytes, salt)
	while digest.size() < length:
		digest.append_array(_crypto.hmac_sha256(password_bytes, digest))
	return digest.slice(0, length)

func _get_master_passphrase() -> String:
	var app_name := ProjectSettings.get_setting("application/config/name", "claw_machine")
	var device := ""
	if OS.has_feature("mobile"):
		device = OS.get_model_name()
	if device == "":
		device = OS.get_unique_id()
	if device == "":
		device = ProjectSettings.get_setting("application/config/description", "claw_machine")
	return "%s::%s::%s" % [app_name, OS.get_user_data_dir(), device]

func _resolve_save_path() -> String:
	if _override_save_path != "":
		return _override_save_path
	return "%s/%s" % [SAVE_DIRECTORY, DEFAULT_SAVE_FILE]

func _resolve_backup_path() -> String:
	if _override_save_path != "":
		return "%s.bak" % _override_save_path
	return "%s/%s" % [SAVE_DIRECTORY, BACKUP_SAVE_FILE]

func _signal_failure(message: String) -> void:
	save_failed.emit(message)
	if _hub:
		_hub.broadcast_save_failed(ERR_FILE_CORRUPT, message)
