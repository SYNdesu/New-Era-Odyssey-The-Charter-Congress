class_name SettingsPanel
extends CanvasLayer

## 设置面板
## 音量 / 画质 / 语言 / 按键映射

signal back_requested

@onready var slider_music: HSlider = %SliderMusic
@onready var slider_sfx: HSlider = %SliderSfx
@onready var btn_language: OptionButton = %BtnLanguage
@onready var btn_back: Button = %BtnBack

var _config: Variant
var _root: Control = null


func _ready() -> void:
	_root = get_child(0) as Control
	_config = CoreSystem.config_manager

	slider_music.value_changed.connect(_on_music_changed)
	slider_sfx.value_changed.connect(_on_sfx_changed)
	btn_language.item_selected.connect(_on_language_changed)
	btn_back.pressed.connect(func(): back_requested.emit())

	if _root:
		_root.visible = false
	_load_settings()


func _load_settings() -> void:
	slider_music.value = _config.get_value("audio", "music_volume", 80.0)
	slider_sfx.value = _config.get_value("audio", "sfx_volume", 80.0)
	
	btn_language.clear()
	btn_language.add_item("简体中文")
	btn_language.add_item("English")
	var lang = _config.get_value("game", "language", 0)
	btn_language.select(lang)


func _on_music_changed(val: float) -> void:
	_config.set_value("audio", "music_volume", val)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(val / 100.0))


func _on_sfx_changed(val: float) -> void:
	_config.set_value("audio", "sfx_volume", val)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(val / 100.0))


func _on_language_changed(idx: int) -> void:
	_config.set_value("game", "language", idx)


func save_settings() -> void:
	_config.save_config()
