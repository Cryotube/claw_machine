extends Node

signal locale_changed(locale: StringName)

static var _instance: Node

var _locale: StringName = StringName("en")
var _catalog: Dictionary = {}

func _ready() -> void:
	_instance = self
	set_locale_dictionary(_build_default_catalog())

static func get_instance() -> Node:
	return _instance

func get_locale() -> StringName:
	return _locale

func toggle_locale() -> void:
	var next_locale := StringName("ja") if _locale == StringName("en") else StringName("en")
	set_locale(next_locale)

func set_locale(locale: StringName) -> void:
	var normalized := locale if locale != StringName() else StringName("en")
	if normalized == _locale:
		return
	_locale = normalized
	locale_changed.emit(_locale)

func get_text(key: StringName, locale: StringName = StringName()) -> String:
	var entry_variant: Variant = _catalog.get(key)
	if entry_variant is Dictionary:
		var entry: Dictionary = entry_variant
		var lookup_locale: StringName = locale if locale != StringName() else _locale
		if entry.has(lookup_locale):
			return String(entry[lookup_locale])
		var english := StringName("en")
		if entry.has(english):
			return String(entry[english])
		for value in entry.values():
			return String(value)
	return String(key)

func set_locale_dictionary(strings: Dictionary) -> void:
	_catalog.clear()
	for key_variant in strings.keys():
		var key := StringName(key_variant)
		var value: Variant = strings[key_variant]
		_catalog[key] = _normalize_entry(value)

func merge_locale_dictionary(strings: Dictionary) -> void:
	for key_variant in strings.keys():
		var key := StringName(key_variant)
		var value: Variant = strings[key_variant]
		var normalized := _normalize_entry(value)
		var existing_variant: Variant = _catalog.get(key, {})
		if existing_variant is Dictionary:
			var existing: Dictionary = existing_variant
			for locale_key in normalized.keys():
				existing[locale_key] = normalized[locale_key]
			_catalog[key] = existing
		else:
			_catalog[key] = normalized

func _normalize_entry(value: Variant) -> Dictionary:
	var entry: Dictionary = {}
	if value is Dictionary:
		var dict_value: Dictionary = value
		for locale_key in dict_value.keys():
			var locale_name := StringName(locale_key)
			entry[locale_name] = String(dict_value[locale_key])
	else:
		entry[StringName("en")] = String(value)
	return entry

func _build_default_catalog() -> Dictionary:
	return {
		StringName("order_salmon_nigiri"): {
			StringName("en"): "Salmon Nigiri",
			StringName("ja"): "サーモン握り",
		},
		StringName("order_tuna_roll"): {
			StringName("en"): "Tuna Roll",
			StringName("ja"): "ツナ巻き",
		},
		StringName("tutorial_hint_default"): {
			StringName("en"): "Serve quickly to keep customers happy!",
			StringName("ja"): "素早く提供して猫を喜ばせよう！",
		},
		StringName("tutorial_overlay_title"): {
			StringName("en"): "Welcome to Claw & Snackle",
			StringName("ja"): "ようこそ クロー＆スナックルへ",
		},
		StringName("tutorial_overlay_cta"): {
			StringName("en"): "Got it — Let's Serve Cats!",
			StringName("ja"): "了解！猫に提供しよう！",
		},
		StringName("tutorial_overlay_default_callouts"): {
			StringName("en"): "[b]Swipe[/b] the joystick to move the claw arm.\n[b]Hold[/b] the grab button to lower the rig, then [b]release[/b] to clamp.\n[b]Drop[/b] above the chute to serve the order before patience runs out.",
			StringName("ja"): "[b]スワイプ[/b]して爪を動かそう。\n[b]長押し[/b]で下降し、[b]離して[/b]キャッチ！\n[b]ドロップ[/b]でチュート上に運び、忍耐が尽きる前に提供しよう。",
		},
		StringName("tutorial_step_intro"): {
			StringName("en"): "Welcome to Claw & Snackle!\nWe'll guide you through your first order.",
			StringName("ja"): "クロー＆スナックルへようこそ！\n最初の注文を案内するよ。",
		},
		StringName("tutorial_step_aim"): {
			StringName("en"): "Step 1: Drag the joystick to aim the claw above the seafood.",
			StringName("ja"): "ステップ1: ジョイスティックで爪を動かし、海鮮の上に狙おう。",
		},
		StringName("tutorial_step_lower"): {
			StringName("en"): "Step 2: Hold the GRAB button to lower the claw.",
			StringName("ja"): "ステップ2: グラブボタンを長押しして爪を下げよう。",
		},
		StringName("tutorial_step_grip"): {
			StringName("en"): "Step 3: Release GRAB to close the claw around the seafood.",
			StringName("ja"): "ステップ3: ボタンを離して海鮮をつかもう。",
		},
		StringName("tutorial_step_drop"): {
			StringName("en"): "Step 4: Move to the chute and tap DROP to carry the seafood over.",
			StringName("ja"): "ステップ4: シュートへ移動し、ドロップで運ぼう。",
		},
		StringName("tutorial_step_serve"): {
			StringName("en"): "Final Step: Drop the seafood in the chute to serve the cat!",
			StringName("ja"): "最終ステップ: シュートに落として猫に提供しよう！",
		},
		StringName("tutorial_step_complete"): {
			StringName("en"): "Tutorial complete! Tap to return to the menu.",
			StringName("ja"): "チュートリアル完了！タップでメニューへ戻ろう。",
		},
		StringName("tutorial_step_retry"): {
			StringName("en"): "Almost! Let's try again.\nAim the claw and keep an eye on the patience meter.",
			StringName("ja"): "惜しい！もう一度挑戦しよう。\n爪を狙って忍耐メーターを確認だ。",
		},
		StringName("tutorial_summary_complete"): {
			StringName("en"): "Nice work! You completed onboarding.\nHead back to the menu to start a score run.",
			StringName("ja"): "お疲れさま！チュートリアル完了です。\nメニューに戻ってスコアランを始めよう！",
		},
		StringName("practice_overlay_instructions"): {
			StringName("en"): "Practice freely! Grab seafood, test the claw, and perfect your drops.",
			StringName("ja"): "自由に練習しよう！\n爪を操作して海鮮を掴み、ドロップを極めてみてね。",
		},
		StringName("title_screen_title"): {
			StringName("en"): "Claw & Snackle",
			StringName("ja"): "クロー＆スナックル",
		},
		StringName("title_screen_subtitle"): {
			StringName("en"): "Tap to begin your shift",
			StringName("ja"): "タップしてシフトを開始しよう",
		},
		StringName("title_screen_start"): {
			StringName("en"): "Start",
			StringName("ja"): "スタート",
		},
		StringName("title_screen_toggle_locale"): {
			StringName("en"): "Toggle Locale",
			StringName("ja"): "言語を切り替え",
		},
		StringName("title_screen_tutorial"): {
			StringName("en"): "Tutorial",
			StringName("ja"): "チュートリアル",
		},
		StringName("title_screen_practice"): {
			StringName("en"): "Practice",
			StringName("ja"): "練習場",
		},
		StringName("title_screen_options"): {
			StringName("en"): "Options",
			StringName("ja"): "オプション",
		},
		StringName("title_screen_records"): {
			StringName("en"): "Records",
			StringName("ja"): "記録",
		},
		StringName("main_menu_header"): {
			StringName("en"): "Main Menu",
			StringName("ja"): "メインメニュー",
		},
		StringName("main_menu_start"): {
			StringName("en"): "Start Score Run",
			StringName("ja"): "スコアラン開始",
		},
		StringName("main_menu_tutorial"): {
			StringName("en"): "Tutorial",
			StringName("ja"): "チュートリアル",
		},
		StringName("main_menu_practice"): {
			StringName("en"): "Practice",
			StringName("ja"): "練習",
		},
		StringName("main_menu_options"): {
			StringName("en"): "Options",
			StringName("ja"): "オプション",
		},
		StringName("main_menu_records"): {
			StringName("en"): "Records",
			StringName("ja"): "記録",
		},
		StringName("main_menu_quit"): {
			StringName("en"): "Quit",
			StringName("ja"): "終了",
		},
	}
