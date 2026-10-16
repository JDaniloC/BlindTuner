extends Node
## Autoload — layouts dos 3 cômodos do MVP. Paredes listadas aqui são SÓ as internas;
## Playground._build_room adiciona a borda automaticamente via _border_walls.

const MapPresetRes := preload("res://scripts/MapPreset.gd")

var ALL: Array = []

func _ready() -> void:
    if ALL.is_empty():
        ALL = _build_all()

func _build_all() -> Array:
    return [
        _make("quarto", "Quarto", Vector2i(8, 8),
            _quarto_walls(), Vector2i(1, 6), Vector2i(6, 1), "quarto"),
        _make("banheiro", "Banheiro", Vector2i(10, 10),
            _banheiro_walls(), Vector2i(8, 8), Vector2i(3, 1), "banheiro"),
        _make("sala", "Sala", Vector2i(12, 12),
            _sala_walls(), Vector2i(10, 10), Vector2i(1, 1), "sala"),
        _make("quarto_lullaby", "Quarto (Noite)", Vector2i(10, 10),
            _quarto_lullaby_walls(), Vector2i(2, 2), Vector2i(3, 6), "quarto"),
        _make("jardim_portao", "Jardim do Portão", Vector2i(10, 10),
            _jardim_portao_walls(), Vector2i(1, 8), Vector2i(8, 2), "quarto"),
        _make("padaria_calcada", "Calçada da Padaria", Vector2i(10, 10),
            _padaria_calcada_walls(), Vector2i(2, 8), Vector2i(7, 2), "sala"),
        _make("praca_chafariz", "Praça do Chafariz", Vector2i(12, 12),
            _praca_chafariz_walls(), Vector2i(2, 9), Vector2i(9, 3), "banheiro"),
        _make("largo_matriz", "Largo da Matriz", Vector2i(12, 12),
            _largo_matriz_walls(), Vector2i(10, 10), Vector2i(2, 2), "sala"),
        # Modo Arcade: Caderno Suzuki Volume 1
        _make("arcade_s1_vento", "Sala da Veneziana", Vector2i(10, 10),
            _arcade_s1_vento_walls(), Vector2i(1, 7), Vector2i(8, 2), "sala"),
        _make("arcade_s1_oculos", "Escrivaninha de Leitura", Vector2i(10, 10),
            _arcade_s1_oculos_walls(), Vector2i(2, 8), Vector2i(7, 3), "sala"),
        _make("arcade_s1_planta", "Canto da Samambaia", Vector2i(10, 10),
            _arcade_s1_planta_walls(), Vector2i(1, 8), Vector2i(6, 2), "sala"),
        _make("arcade_s1_louca", "Bancada de Porcelana", Vector2i(10, 10),
            _arcade_s1_louca_walls(), Vector2i(2, 7), Vector2i(7, 2), "sala"),
        # Modo Arcade: Caderno Suzuki Volume 2
        _make("arcade_s2_gato", "Sala de Estar do Mimi", Vector2i(10, 10),
            _arcade_s2_gato_walls(), Vector2i(2, 8), Vector2i(7, 3), "sala"),
        _make("arcade_s2_valsa", "Corredor Ensolarado", Vector2i(10, 10),
            _arcade_s2_valsa_walls(), Vector2i(1, 8), Vector2i(8, 3), "quarto"),
        _make("arcade_s2_chaves", "Aparador da Entrada", Vector2i(10, 10),
            _arcade_s2_chaves_walls(), Vector2i(2, 8), Vector2i(7, 2), "sala"),
        # Modo Arcade: Caderno Suzuki Volume 3
        _make("arcade_s3_carteiro", "Calçada da Caixa de Correio", Vector2i(10, 10),
            _arcade_s3_carteiro_walls(), Vector2i(2, 8), Vector2i(7, 2), "sala"),
        _make("arcade_s3_cha", "Cozinha da Caneca Noturna", Vector2i(10, 10),
            _arcade_s3_cha_walls(), Vector2i(2, 8), Vector2i(7, 3), "sala"),
        # Modo Arcade: Caderno Suzuki Volume 4
        _make("arcade_s4_vento", "Varanda das Partituras", Vector2i(10, 10),
            _arcade_s4_vento_walls(), Vector2i(2, 8), Vector2i(7, 2), "sala"),
        _make("arcade_s4_duo", "Salão dos Dois Violinos", Vector2i(10, 10),
            _arcade_s4_duo_walls(), Vector2i(1, 8), Vector2i(8, 3), "sala"),
        # Modo Arcade: Caderno Suzuki Volume 5
        _make("arcade_s5_flores", "Praça da Barraca de Flores", Vector2i(10, 10),
            _arcade_s5_flores_walls(), Vector2i(2, 8), Vector2i(7, 2), "sala"),
        # Modo Arcade: Caderno Suzuki Volume 6
        _make("arcade_s6_igreja", "Nave da Antiga Sé", Vector2i(10, 10),
            _arcade_s6_igreja_walls(), Vector2i(2, 8), Vector2i(7, 3), "quarto"),
        # Modo História: Capítulo 3 — As Últimas Paisagens
        _make("praia_mirante", "Praia do Mirante", Vector2i(12, 12),
            _praia_mirante_walls(), Vector2i(2, 9), Vector2i(9, 3), "quarto"),
        _make("estacao_plataforma", "Plataforma da Estação", Vector2i(12, 12),
            _estacao_plataforma_walls(), Vector2i(10, 10), Vector2i(3, 3), "sala"),
        _make("estudio_conservatorio", "Estúdio do Conservatório", Vector2i(12, 12),
            _estudio_conservatorio_walls(), Vector2i(2, 10), Vector2i(9, 2), "sala"),
        _make("teatro_palco", "Palco do Grande Teatro", Vector2i(12, 12),
            _teatro_palco_walls(), Vector2i(10, 2), Vector2i(2, 9), "sala"),
    ]

# Quarto de dormir no escuro (Lullaby): obstáculos em volta do caminho seguro.
func _quarto_lullaby_walls() -> Array[Vector2i]:
    return [
        Vector2i(1, 2), Vector2i(1, 3), Vector2i(1, 4),
        Vector2i(2, 3), Vector2i(2, 4),
        Vector2i(5, 4), Vector2i(5, 5),
        Vector2i(2, 5), Vector2i(2, 6),
        Vector2i(3, 5),
        Vector2i(4, 3),
        Vector2i(2, 7), Vector2i(3, 7),
        Vector2i(6, 6), Vector2i(6, 7),
        Vector2i(5, 8),
        Vector2i(3, 8),
    ]

# Cama 2×3 no canto NW + criado-mudo.
func _quarto_walls() -> Array[Vector2i]:
    return [
        Vector2i(1,1), Vector2i(2,1),
        Vector2i(1,2), Vector2i(2,2),
        Vector2i(1,3), Vector2i(2,3),
        Vector2i(3,1), Vector2i(3,2),
    ]

# Pia L (3) + vaso (2) + lixeira (1). Total 6 tiles.
func _banheiro_walls() -> Array[Vector2i]:
    return [
        Vector2i(1,1), Vector2i(2,1), Vector2i(1,2),
        Vector2i(7,1), Vector2i(7,2),
        Vector2i(8,1),
    ]

# Sofá 3 + mesinha 1 + estante 4 + TV 1. Total 9 tiles.
func _sala_walls() -> Array[Vector2i]:
    return [
        Vector2i(3,8), Vector2i(4,8), Vector2i(5,8),
        Vector2i(4,6),
        Vector2i(10,2), Vector2i(10,3), Vector2i(10,4), Vector2i(10,5),
        Vector2i(1,4),
    ]

# Jardim do Portão: canteiros de flores e arbustos nas laterais
func _jardim_portao_walls() -> Array[Vector2i]:
    return [
        Vector2i(1, 6), Vector2i(2, 6),
        Vector2i(4, 7),
        Vector2i(5, 3), Vector2i(6, 3),
        Vector2i(7, 5),
        Vector2i(8, 4), Vector2i(8, 5),
    ]

# Calçada da Padaria: meio-fio, poste e mesinhas externas
func _padaria_calcada_walls() -> Array[Vector2i]:
    return [
        Vector2i(1, 5), Vector2i(1, 6),
        Vector2i(2, 5),
        Vector2i(4, 7),
        Vector2i(5, 6),
        Vector2i(6, 4),
        Vector2i(7, 4),
        Vector2i(8, 3),
    ]

# Praça do Chafariz: canteiros de flores e bancos ao redor
func _praca_chafariz_walls() -> Array[Vector2i]:
    return [
        Vector2i(2, 7),
        Vector2i(3, 6),
        Vector2i(4, 5),
        Vector2i(5, 8), Vector2i(6, 8),
        Vector2i(8, 6),
        Vector2i(9, 5),
        Vector2i(10, 4),
    ]

# Largo da Matriz: pilastras e balustradas da escadaria
func _largo_matriz_walls() -> Array[Vector2i]:
    return [
        Vector2i(10, 8),
        Vector2i(9, 7),
        Vector2i(7, 9),
        Vector2i(6, 8),
        Vector2i(4, 6),
        Vector2i(3, 5),
        Vector2i(2, 4),
        Vector2i(1, 3),
    ]

# S1.1 Sala da Veneziana: sofás e estante contornando a travessia
func _arcade_s1_vento_walls() -> Array[Vector2i]:
    return [
        Vector2i(2, 4), Vector2i(2, 5), Vector2i(3, 4),
        Vector2i(5, 6), Vector2i(6, 6),
        Vector2i(4, 3), Vector2i(5, 3),
        Vector2i(7, 5), Vector2i(8, 4),
    ]

# S1.2 Escrivaninha de Leitura: estante alta, poltrona e cesto
func _arcade_s1_oculos_walls() -> Array[Vector2i]:
    return [
        Vector2i(5, 6), Vector2i(6, 6), Vector2i(7, 5),
        Vector2i(2, 6), Vector2i(2, 7),
        Vector2i(4, 4), Vector2i(5, 3),
        Vector2i(4, 7),
    ]

# S1.3 Canto da Samambaia: jardineiras, pedestais e pufe central
func _arcade_s1_planta_walls() -> Array[Vector2i]:
    return [
        Vector2i(3, 5), Vector2i(4, 5),
        Vector2i(2, 6), Vector2i(2, 5),
        Vector2i(6, 4), Vector2i(7, 4),
        Vector2i(4, 7), Vector2i(5, 7),
    ]

# S1.4 Bancada de Porcelana: cristaleira e balcão de louça
func _arcade_s1_louca_walls() -> Array[Vector2i]:
    return [
        Vector2i(2, 5), Vector2i(2, 6),
        Vector2i(3, 4),
        Vector2i(4, 3), Vector2i(4, 4),
        Vector2i(6, 4), Vector2i(6, 5),
        Vector2i(7, 4),
    ]

# S2.1 Sala de Estar do Mimi: sofá e mesas onde o gato se esconde
func _arcade_s2_gato_walls() -> Array[Vector2i]:
    return [
        Vector2i(2, 6), Vector2i(2, 7),
        Vector2i(4, 7), Vector2i(4, 4),
        Vector2i(5, 3), Vector2i(5, 5),
        Vector2i(7, 4), Vector2i(7, 5),
    ]

# S2.2 Corredor Ensolarado: móveis laterais contornados pelo trajeto de varredura
func _arcade_s2_valsa_walls() -> Array[Vector2i]:
    return [
        Vector2i(2, 5),
        Vector2i(3, 4), Vector2i(3, 5),
        Vector2i(4, 7),
        Vector2i(5, 6),
        Vector2i(6, 3),
        Vector2i(7, 2), Vector2i(7, 5),
    ]

# S2.3 Aparador da Entrada: aparador, cabideiro e sapateira
func _arcade_s2_chaves_walls() -> Array[Vector2i]:
    return [
        Vector2i(2, 6),
        Vector2i(3, 5), Vector2i(3, 6),
        Vector2i(5, 5), Vector2i(5, 6),
        Vector2i(6, 4), Vector2i(6, 2),
        Vector2i(7, 4),
    ]

# S3.1 Calçada da Caixa de Correio: cerca viva e pedras
func _arcade_s3_carteiro_walls() -> Array[Vector2i]:
    return [
        Vector2i(2, 6), Vector2i(3, 5),
        Vector2i(4, 7), Vector2i(5, 4),
        Vector2i(6, 6), Vector2i(7, 5),
    ]

# S3.2 Cozinha da Caneca Noturna: mesa de jantar e cadeiras
func _arcade_s3_cha_walls() -> Array[Vector2i]:
    return [
        Vector2i(2, 7), Vector2i(3, 8),
        Vector2i(4, 6), Vector2i(5, 3),
        Vector2i(6, 5),
    ]

# S4.1 Varanda das Partituras: jardineiras e porta da varanda
func _arcade_s4_vento_walls() -> Array[Vector2i]:
    return [
        Vector2i(2, 6), Vector2i(3, 5),
        Vector2i(4, 5), Vector2i(5, 7),
        Vector2i(6, 6), Vector2i(6, 3), Vector2i(7, 4),
    ]

# S4.2 Salão dos Dois Violinos: estantes de partituras e poltronas
func _arcade_s4_duo_walls() -> Array[Vector2i]:
    return [
        Vector2i(2, 5), Vector2i(3, 4),
        Vector2i(4, 7), Vector2i(5, 3),
        Vector2i(6, 6), Vector2i(7, 5),
    ]

# S5.1 Praça da Barraca de Flores: caixotes e barracas de madeira
func _arcade_s5_flores_walls() -> Array[Vector2i]:
    return [
        Vector2i(2, 6), Vector2i(4, 7),
        Vector2i(4, 3), Vector2i(5, 6),
        Vector2i(6, 2), Vector2i(7, 4),
    ]

# S6.1 Nave da Antiga Sé: colunas de pedra e pia batismal
func _arcade_s6_igreja_walls() -> Array[Vector2i]:
    return [
        Vector2i(2, 6), Vector2i(3, 5),
        Vector2i(5, 6), Vector2i(6, 2),
        Vector2i(7, 5),
    ]

# 3.1 Praia do Mirante: rochedos do quebra-mar e cercado
func _praia_mirante_walls() -> Array[Vector2i]:
    return [
        Vector2i(2, 7), Vector2i(3, 7), Vector2i(4, 8),
        Vector2i(5, 6), Vector2i(6, 7), Vector2i(7, 6),
        Vector2i(8, 5), Vector2i(9, 4), Vector2i(9, 5),
    ]

# 3.2 Plataforma da Estação: pilares de ferro fundido e bancos da plataforma
func _estacao_plataforma_walls() -> Array[Vector2i]:
    return [
        Vector2i(10, 8), Vector2i(8, 10),
        Vector2i(8, 7), Vector2i(7, 8),
        Vector2i(6, 5), Vector2i(5, 6),
        Vector2i(4, 3), Vector2i(3, 4),
    ]

# 3.3 Estúdio do Conservatório: piano de cauda, estantes e armários
func _estudio_conservatorio_walls() -> Array[Vector2i]:
    return [
        Vector2i(2, 8), Vector2i(3, 8), Vector2i(3, 10),
        Vector2i(5, 7), Vector2i(5, 8),
        Vector2i(6, 4), Vector2i(7, 5),
        Vector2i(8, 2), Vector2i(9, 3),
    ]

# 3.4 Palco do Grande Teatro: ribalta do proscênio e pedestais dos sinos
func _teatro_palco_walls() -> Array[Vector2i]:
    return [
        Vector2i(9, 2), Vector2i(8, 3), Vector2i(8, 5),
        Vector2i(7, 3), Vector2i(6, 6), Vector2i(5, 5),
        Vector2i(4, 6), Vector2i(3, 7), Vector2i(2, 8),
    ]

func _make(p_id: String, p_label: String, p_size: Vector2i,
        p_walls: Array[Vector2i], p_start: Vector2i, p_goal: Vector2i,
        p_theme_id: String) -> Resource:
    var m := MapPresetRes.new()
    m.id = p_id
    m.label = p_label
    m.size = p_size
    m.walls = p_walls
    m.start_grid = p_start
    m.goal_grid = p_goal
    m.theme_id = p_theme_id
    return m

func by_id(p_id: String) -> Resource:
    for m in ALL:
        if m.id == p_id:
            return m
    return null
