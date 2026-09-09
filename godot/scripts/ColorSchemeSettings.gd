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

## Marca "campo ausente no arquivo" na leitura de custom_editada. Ver load_from_disk().
const SEM_FLAG := "ausente"

## Caminho do arquivo de configuração. É variável, não constante, porque os
## testes precisam apontar para um arquivo próprio: a suíte gravava e apagava o
## user://color_scheme.cfg REAL, destruindo a paleta de quem joga na mesma
## máquina toda vez que alguém rodava os testes.
var config_path: String = CONFIG_PATH

var scheme_id: String = DEFAULT_SCHEME
var _custom: Array[Color] = []

## O jogador REALMENTE editou alguma das 12 cores, ou elas só foram semeadas?
## Sem essa distinção, apenas SELECIONAR "Personalizado" no dropdown já gravava
## 12 cores em disco (a tela salva a cada troca de esquema) e a paleta congelava
## para sempre: a semente via size() == 12 e nunca mais re-semeava, então não
## havia como começar uma paleta personalizada a partir de outro esquema sem
## passar por "Restaurar tudo ao padrão".
var _custom_edited: bool = false

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
	if id == CUSTOM_ID:
		# Entrar no editor parte do esquema que estava ativo, não do zero -- mas
		# só re-semeia enquanto o jogador não tiver editado cor nenhuma, senão
		# sobrescreveria o trabalho dele.
		_seed_custom_from_active()
	scheme_id = id
	scheme_changed.emit(scheme_id)

## Copia as 12 cores do esquema ATIVO para _custom, a menos que o jogador já
## tenha editado alguma -- aí a paleta é trabalho dele e não pode ser trocada.
##
## Separado de custom_colors() de propósito: aquele é um getter puro. Enquanto
## os dois estavam no mesmo lugar, save_to_disk() -- que só queria LER --
## semeava a paleta como efeito colateral, e como a tela salva a cada troca de
## esquema, a semente do "Personalizado" congelava no primeiro esquema salvo.
func _seed_custom_from_active() -> void:
	if _custom_edited and _custom.size() == 12:
		return
	var base := ColorSchemes.colors_for(scheme_id)
	if base.size() != 12:
		# Não há esquema fixo de onde copiar (já estamos no personalizado, ou o
		# id é inválido): mantém o que houver em vez de zerar.
		return
	_custom = base.duplicate()

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
	if chromatic_index < 0 or chromatic_index >= 12:
		return
	if _custom.size() != 12:
		# Editar direto, sem passar pelo dropdown: parte do que o jogador está
		# vendo agora. Nunca re-semeia quando já há 12 cores -- as outras 11
		# podem ser trabalho dele.
		_custom = active_palette()
	_custom[chromatic_index] = color
	_custom_edited = true
	if scheme_id == CUSTOM_ID:
		scheme_changed.emit(scheme_id)

## Getter PURO -- não semeia, não muta, devolve cópia. Vazio significa "o
## jogador nunca personalizou nada".
func custom_colors() -> Array[Color]:
	return _custom.duplicate()

## As 12 cores em vigor agora, seja qual for o esquema. É o que a UI deve
## comparar contra (o jogador enxerga estas), sem forçar a criação de uma
## paleta personalizada só por estar olhando.
func active_palette() -> Array[Color]:
	if scheme_id == CUSTOM_ID and _custom.size() == 12:
		return _custom.duplicate()
	var cores := ColorSchemes.colors_for(scheme_id)
	if cores.size() == 12:
		return cores
	return ColorSchemes.colors_for(DEFAULT_SCHEME)

## Um único reset, sem reset por item (12 botões espalhados seriam pior para o
## público-alvo). Também é o que os testes chamam para não vazar estado global.
func reset_to_defaults() -> void:
	scheme_id = DEFAULT_SCHEME
	_custom.clear()
	_custom_edited = false
	scheme_changed.emit(scheme_id)

## Retorna false se a escrita falhar. Sem o retorno checado, um disco cheio ou
## sem permissão perdia a configuração do jogador em silêncio absoluto.
func save_to_disk() -> bool:
	var cfg := ConfigFile.new()
	cfg.set_value("cor", "scheme_id", scheme_id)
	# Grava _custom direto: custom_colors() é puro agora, e mesmo assim não
	# queremos semear aqui -- salvar não é motivo pra inventar paleta.
	cfg.set_value("cor", "custom", _custom)
	# Sem este campo não dá para distinguir "o jogador pintou as 12 cores" de "a
	# tela semeou as 12 cores porque ele espiou o item Personalizado".
	cfg.set_value("cor", "custom_editada", _custom_edited)
	var err := cfg.save(config_path)
	if err != OK:
		push_warning("ColorSchemeSettings: falha ao salvar em %s (erro %d)" % [config_path, err])
		return false
	return true

## Retorna false (sem push_error) se o arquivo não existir ou estiver inválido;
## nesses casos o estado padrão é mantido intacto -- nunca aplica meia paleta.
## push_error poluiria a suíte, e aplicar parcialmente daria uma paleta híbrida
## que o jogador nunca escolheu.
func load_from_disk() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(config_path) != OK:
		return false
	# Lê sem tipar na declaração: um arquivo corrompido mas parseável (um número
	# onde deveria haver texto) derrubava o boot com erro de atribuição de tipo
	# em vez de simplesmente devolver false.
	var id_raw = cfg.get_value("cor", "scheme_id", "")
	var custom_raw = cfg.get_value("cor", "custom", [])
	# Sentinela em vez de null: get_value(..., null) faz o ConfigFile entender que
	# default NENHUM foi dado e chamar push_error, então todo boot de quem atualiza
	# de uma versão anterior ao campo saía com "Couldn't find the given section" no
	# log -- por um caso normal, e contra a decisão de não poluir o log registrada
	# logo acima. Qualquer valor não-booleano serve: o typeof() abaixo trata
	# sentinela e lixo pelo mesmo caminho, o da migração.
	var editada_raw = cfg.get_value("cor", "custom_editada", SEM_FLAG)
	if typeof(id_raw) != TYPE_STRING:
		return false
	var id: String = id_raw
	if id != CUSTOM_ID and not ColorSchemes.SCHEME_IDS.has(id):
		return false
	var custom: Array = custom_raw if typeof(custom_raw) == TYPE_ARRAY else []

	# A paleta personalizada é restaurada sempre que for válida, INDEPENDENTE do
	# esquema ativo no arquivo. Antes ela só voltava quando o jogo tinha sido
	# fechado dentro do "Personalizado": quem editasse as 12 cores e depois desse
	# uma espiada em outro esquema antes de sair perdia tudo no próximo boot,
	# mesmo com as cores gravadas no disco.
	var custom_ok := ColorSchemes.is_valid_palette(custom)
	if custom_ok:
		_custom.assign(custom)
		if typeof(editada_raw) == TYPE_BOOL:
			_custom_edited = editada_raw
		else:
			# Arquivo gravado antes de o campo existir: uma paleta idêntica a um
			# esquema de fábrica não carrega trabalho nenhum do jogador (foi
			# semeada), qualquer outra carrega. Na dúvida, preserva o trabalho.
			_custom_edited = not _matches_stock_scheme(custom)
	elif id == CUSTOM_ID:
		# Esquema personalizado sem paleta válida é estado incoerente.
		return false

	scheme_id = id
	scheme_changed.emit(scheme_id)
	return true

func _matches_stock_scheme(cores: Array) -> bool:
	for id in ColorSchemes.SCHEME_IDS:
		var fixo := ColorSchemes.colors_for(id)
		if fixo.size() != cores.size():
			continue
		var igual := true
		for i in range(fixo.size()):
			if fixo[i] != cores[i]:
				igual = false
				break
		if igual:
			return true
	return false
