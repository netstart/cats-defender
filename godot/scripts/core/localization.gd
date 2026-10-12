extends Node
## Localization — textos PT-BR/EN via JSON (res://data/localization.json)
## {chave: {pt_BR: "..."}} — JSON é embutido no export (CSV não é).
## Autoload: Localization

var _strings: Dictionary = {}

func _ready() -> void:
	load_json("res://data/localization.json")
	set_locale(GameSettings.locale if GameSettings else "pt_BR")

func set_locale(loc: String) -> void:
	GameSettings.locale = loc
	TranslationServer.set_locale(loc)
	EventBus.language_changed.emit(loc)

func tr_key(key: String) -> String:
	var loc: String = GameSettings.locale if GameSettings else "pt_BR"
	var entry: Dictionary = _strings.get(key, {})
	if entry.has(loc) and entry[loc] != "":
		return entry[loc]
	if entry.has("pt_BR"):
		return entry["pt_BR"]
	return key

func load_json(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("Localization: JSON não encontrado: " + path)
		return false
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Localization: JSON inválido: " + path)
		return false
	_strings = parsed
	return true

func keys_missing() -> Array:
	## Retorna chaves sem tradução em algum idioma (teste de localização).
	var out := []
	for k in _strings:
		var d: Dictionary = _strings[k]
		if String(d.get("pt_BR", "")) == "" or String(d.get("en", "")) == "":
			out.append(k)
	return out
