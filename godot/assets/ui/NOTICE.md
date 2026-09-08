# Atribuição de assets de UI

Os sprites em `flat/` vêm do **Complete UI Essential Pack** de
**Crusenho Agus Hennihuno**.

- Licença: Creative Commons Attribution 4.0 International (CC BY 4.0)
- Texto da licença: https://creativecommons.org/licenses/by/4.0/
- Autor / store: https://crusenho.itch.io

Alterações feitas: os arquivos PNG foram copiados sem modificação de pixel.
A configuração como `StyleBoxTexture` nine-patch é feita nos metadados do
Godot (`blindtuner_theme.tres`), não nos arquivos de imagem.

## Ícones em `icons/`

Os 12 SVGs em `icons/` (`back_hand`, `directions_run`,
`keyboard_double_arrow_up`, `priority_high`, `north`, `north_east`, `east`,
`south_east`, `south`, `south_west`, `west`, `north_west`) vêm do
**Material Symbols**, do **Google**.

- Licença: Apache License 2.0
- Texto da licença: https://www.apache.org/licenses/LICENSE-2.0
- Origem: https://fonts.google.com/icons

Alterações feitas (a Apache-2.0 exige sinalizar modificações):

1. O atributo `fill="#ffffff"` foi injetado no `<path>` de cada arquivo, para
   que o glifo seja branco e possa ser tingido em runtime pelo 4º argumento de
   `draw_texture_rect` (ver `scripts/ActionIcon.gd`).
2. Os atributos `width` e `height` foram trocados de `24` para `96`, para o
   importador de SVG do Godot rasterizar em resolução suficiente para as
   teclas grandes do modo Piano. O `viewBox` não foi alterado.
