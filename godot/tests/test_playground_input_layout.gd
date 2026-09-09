extends GutTest
## Rede de segurança de layout dos controles de input NA CENA DE JOGO.
##
## Por que este arquivo existe: as tasks do Plano A cresceram o teclado do Piano
## (tecla branca de 160 pra 280px) e o braço do Scroll (BOARD_SIZE pra 110x400)
## sem que nenhuma delas listasse Playground.tscn entre seus arquivos. As caixas
## que hospedam esses controles na cena continuaram com o tamanho antigo e, como
## nenhum teste instanciava a cena de jogo, 7 dos 12 ícones de tecla e as duas
## cravelhas da direita passaram a ser desenhados fora da tela em silêncio.
##
## O truque: instanciar dentro de um SubViewport do tamanho de projeto
## (720x1280). A janela raiz em headless NÃO tem esse tamanho -- ela vem 1280x1280
## --, então medir contra o viewport do runner daria folga horizontal demais e
## deixaria passar exatamente o transbordo do braço do Scroll, que era 30px.

const PlaygroundScene := preload("res://scenes/Playground.tscn")

var _screen: SubViewport

func _design_size() -> Vector2i:
	# Tipagem explícita: get_setting devolve Variant e ":=" não infere daí.
	var w: int = ProjectSettings.get_setting("display/window/size/viewport_width")
	var h: int = ProjectSettings.get_setting("display/window/size/viewport_height")
	return Vector2i(w, h)

func _playground_at_design_size() -> Node:
	_screen = SubViewport.new()
	_screen.size = _design_size()
	add_child_autofree(_screen)
	var p = PlaygroundScene.instantiate()
	_screen.add_child(p)
	return p

func _assert_on_screen(rect: Rect2, what: String) -> void:
	var screen := _screen.get_visible_rect()
	assert_true(screen.encloses(rect),
		"%s está fora da tela: %s não cabe em %s" % [what, rect, screen])

func test_piano_key_icons_are_fully_on_screen():
	var p = _playground_at_design_size()
	await wait_frames(2)
	var piano: Control = p.get_node("UI/PianoInput")
	for i in range(piano._key_icons.size()):
		var icon: Control = piano._key_icons[i]
		_assert_on_screen(icon.get_global_rect(), "ícone da tecla %s" % piano._button_notes[i])

func test_piano_keys_are_fully_on_screen():
	var p = _playground_at_design_size()
	await wait_frames(2)
	var piano: Control = p.get_node("UI/PianoInput")
	for i in range(piano._buttons.size()):
		_assert_on_screen(piano._buttons[i].get_global_rect(), "tecla %s" % piano._button_notes[i])

func test_pitch_scroll_board_is_fully_on_screen():
	var p = _playground_at_design_size()
	await wait_frames(2)
	var scroll: Control = p.get_node("UI/PitchScrollInput")
	# O braço é desenhado em coordenadas locais de 0 até BOARD_SIZE, sem clip --
	# medir a caixa do nó não bastaria se ela fosse menor que o desenho.
	var board := Rect2(scroll.global_position, scroll.BOARD_SIZE)
	_assert_on_screen(board, "braço do PitchScrollInput")
	_assert_on_screen(scroll.get_global_rect(), "caixa do PitchScrollInput")

func test_joystick_and_special_actions_are_fully_on_screen():
	var p = _playground_at_design_size()
	await wait_frames(2)
	_assert_on_screen((p.get_node("UI/DirectionJoystick") as Control).get_global_rect(), "DirectionJoystick")
	_assert_on_screen((p.get_node("UI/SpecialActionPanel") as Control).get_global_rect(), "SpecialActionPanel")

func test_joystick_drawn_reach_is_fully_on_screen():
	# A caixa do nó não é o desenho: as fatias saem do centro e o thumb chega a
	# RADIUS+THUMB_RADIUS dele. Medir só get_global_rect() deixaria passar um
	# transbordo do desenho, que é como o joystick já vivia (108px de alcance
	# dentro de uma meia-caixa de 100px).
	var p = _playground_at_design_size()
	await wait_frames(2)
	var j: Control = p.get_node("UI/DirectionJoystick")
	var alcance: float = j.RADIUS + j.THUMB_RADIUS
	var centro := j.get_global_rect().get_center()
	_assert_on_screen(Rect2(centro - Vector2.ONE * alcance, Vector2.ONE * alcance * 2.0),
		"alcance desenhado do joystick")
	assert_true(j.get_global_rect().encloses(Rect2(centro - Vector2.ONE * alcance, Vector2.ONE * alcance * 2.0)),
		"a área de toque do joystick precisa cobrir o desenho inteiro")

func test_joystick_does_not_overlap_the_note_panel_or_the_actions():
	# O joystick cresceu na direção do painel de ações (mesma faixa de baixo) e
	# para cima, na direção do NotePanel.
	var p = _playground_at_design_size()
	await wait_frames(2)
	var j := (p.get_node("UI/DirectionJoystick") as Control).get_global_rect()
	assert_false(j.intersects((p.get_node("UI/NotePanel") as Control).get_global_rect()),
		"o joystick cobre o NotePanel")
	assert_false(j.intersects((p.get_node("UI/SpecialActionPanel") as Control).get_global_rect()),
		"o joystick cobre os botões de ação")
