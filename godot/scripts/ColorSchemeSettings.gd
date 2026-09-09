extends Node
## Autoload — guarda QUAL esquema de cor está ativo e as 12 cores do esquema
## "personalizado". Espelha o padrão de CueSettings/InputModeSettings.
##
## O padrão de fábrica é "pedagogico" (escolha do usuário na maquete
## comparativa), não "classico" -- este último existe para quem prefira a
## paleta original e como fallback quando o autoload não está disponível.

signal scheme_changed(scheme_id: String)

const DEFAULT_SCHEME := "pedagogico"
const CUSTOM_ID := "personalizado"
const CONFIG_PATH := "user://color_scheme.cfg"

var scheme_id: String = DEFAULT_SCHEME
var _custom: Array[Color] = []

func _ready() -> void:
	# Guarda essencial: os testes instanciam este script solto
	# (ColorSchemeSettingsScript.new() + add_child_autofree) para não encostar no
	# singleton. Sem esta checagem, cada instância isolada leria o user:// do dev
	# no _ready() e a suíte passaria a depender do que estiver salvo na máquina --
	# o clássico "passa na minha máquina". Só o autoload carrega do disco;
	# instâncias de teste chamam load_from_disk() explicitamente quando querem.
	if get_path() == ^"/root/ColorSchemeSettings":
		load_from_disk()

func set_scheme(id: String) -> void:
	if id != CUSTOM_ID and not ColorSchemes.SCHEME_IDS.has(id):
		return
	if id == CUSTOM_ID and _custom.is_empty():
		# Entrar no editor parte do esquema que estava ativo, não do zero.
		_custom = ColorSchemes.colors_for(scheme_id).duplicate()
	scheme_id = id
	scheme_changed.emit(scheme_id)

func color_for(note_key: String) -> Color:
	var idx := NoteMapping.chromatic_index_for(note_key)
	if idx < 0:
		return NoteMapping.default_color_for(note_key)
	if scheme_id == CUSTOM_ID and _custom.size() == 12:
		return _custom[idx]
	var cores := ColorSchemes.colors_for(scheme_id)
	if cores.size() != 12:
		return NoteMapping.default_color_for(note_key)
	return cores[idx]

func set_custom_color(chromatic_index: int, color: Color) -> void:
	if _custom.size() != 12:
		_custom = ColorSchemes.colors_for(scheme_id).duplicate()
	if chromatic_index < 0 or chromatic_index >= 12:
		return
	_custom[chromatic_index] = color
	if scheme_id == CUSTOM_ID:
		scheme_changed.emit(scheme_id)

func custom_colors() -> Array[Color]:
	if _custom.size() != 12:
		_custom = ColorSchemes.colors_for(scheme_id).duplicate()
	return _custom

## Um único reset, sem reset por item (12 botões espalhados seriam pior para o
## público-alvo). Também é o que os testes chamam para não vazar estado global.
func reset_to_defaults() -> void:
	scheme_id = DEFAULT_SCHEME
	_custom.clear()
	scheme_changed.emit(scheme_id)

func save_to_disk() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("cor", "scheme_id", scheme_id)
	cfg.set_value("cor", "custom", custom_colors())
	cfg.save(CONFIG_PATH)

## Retorna false (sem push_error) se o arquivo não existir ou estiver inválido;
## nesses casos o estado padrão é mantido intacto -- nunca aplica meia paleta.
## push_error poluiria a suíte, e aplicar parcialmente daria uma paleta híbrida
## que o jogador nunca escolheu.
func load_from_disk() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return false
	var id: String = cfg.get_value("cor", "scheme_id", "")
	var custom: Array = cfg.get_value("cor", "custom", [])
	var id_ok := id == CUSTOM_ID or ColorSchemes.SCHEME_IDS.has(id)
	if not id_ok:
		return false
	if id == CUSTOM_ID and not ColorSchemes.is_valid_palette(custom):
		return false
	if id == CUSTOM_ID:
		_custom.assign(custom)
	scheme_id = id
	scheme_changed.emit(scheme_id)
	return true
