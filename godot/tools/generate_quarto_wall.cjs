const fs = require('fs');
const path = require('path');
let sharp;
try {
  sharp = require('../../../casarei.online/node_modules/sharp');
} catch (e) {
  try {
    sharp = require('../casarei.online/node_modules/sharp');
  } catch (e2) {
    sharp = require('c:/Users/danil/Documents/code/casarei.online/node_modules/sharp');
  }
}

// 64x72 Isometric Wall Tile with Rich Oak Wainscoting & Warm Vintage Wallpaper
const svg = `
<svg width="64" height="72" viewBox="0 0 64 72" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">
  <!-- TOP CAP (Warm dark walnut wood trim - frames the room cleanly) -->
  <polygon points="32,0 64,16 32,32 0,16" fill="#4A3222"/>
  <polygon points="32,2 61,16 32,30 3,16" fill="#5C3E2A"/>
  <polygon points="32,4 57,16 32,28 7,16" fill="#6E4A33"/>
  <polygon points="32,6 52,16 32,26 12,16" fill="#583A27"/>

  <!-- LEFT FACE (facing South-West - warm ambient light) -->
  <!-- Upper Half: Vintage Warm Sage/Olive Patterned Wallpaper -->
  <polygon points="0,16 32,32 32,50 0,34" fill="#889A82"/>
  <!-- Wallpaper vertical pinstripes & damask rhythm -->
  <polygon points="6,19 10,21 10,39 6,37" fill="#98AA92"/>
  <polygon points="14,23 18,25 18,43 14,41" fill="#98AA92"/>
  <polygon points="22,27 26,29 26,47 22,45" fill="#98AA92"/>
  <line x1="8" y1="20" x2="8" y2="38" stroke="#778972" stroke-width="1"/>
  <line x1="16" y1="24" x2="16" y2="42" stroke="#778972" stroke-width="1"/>
  <line x1="24" y1="28" x2="24" y2="46" stroke="#778972" stroke-width="1"/>
  
  <!-- Chair Rail / Molding Divider -->
  <polygon points="0,34 32,50 32,53 0,37" fill="#8D5B2F"/>
  <polygon points="0,35 32,51 32,52 0,36" fill="#B07540"/>

  <!-- Lower Half: Rich Oak Wainscoting / Wood Paneling -->
  <polygon points="0,37 32,53 32,72 0,56" fill="#6A401D"/>
  <!-- Wainscot vertical panels & bevels -->
  <polygon points="3,40 12,44 12,59 3,55" fill="#7C4C24"/>
  <polygon points="14,45 23,49 23,64 14,60" fill="#7C4C24"/>
  <polygon points="25,50 31,53 31,68 25,65" fill="#7C4C24"/>
  <!-- Baseboard trim at floor -->
  <polygon points="0,52 32,68 32,72 0,56" fill="#4E2D12"/>
  <line x1="0" y1="52" x2="32" y2="68" stroke="#8D5B2F" stroke-width="1"/>

  <!-- RIGHT FACE (facing South-East - soft shadow) -->
  <!-- Upper Half: Vintage Sage Wallpaper in Shadow -->
  <polygon points="32,32 64,16 64,34 32,50" fill="#6D7F67"/>
  <!-- Wallpaper vertical stripes right -->
  <polygon points="38,47 42,45 42,27 38,29" fill="#7B8D75"/>
  <polygon points="46,43 50,41 50,23 46,25" fill="#7B8D75"/>
  <polygon points="54,39 58,37 58,19 54,21" fill="#7B8D75"/>
  <line x1="40" y1="46" x2="40" y2="28" stroke="#5E6F58" stroke-width="1"/>
  <line x1="48" y1="42" x2="48" y2="24" stroke="#5E6F58" stroke-width="1"/>
  <line x1="56" y1="38" x2="56" y2="20" stroke="#5E6F58" stroke-width="1"/>

  <!-- Chair Rail / Molding Divider right -->
  <polygon points="32,50 64,34 64,37 32,53" fill="#6E4420"/>
  <polygon points="32,51 64,35 64,36 32,52" fill="#8D5B2F"/>

  <!-- Lower Half: Shaded Oak Wainscoting -->
  <polygon points="32,53 64,37 64,56 32,72" fill="#523013"/>
  <!-- Shaded panels -->
  <polygon points="33,53 41,49 41,65 33,68" fill="#5D3818"/>
  <polygon points="43,48 52,44 52,60 43,64" fill="#5D3818"/>
  <polygon points="54,43 62,39 62,55 54,59" fill="#5D3818"/>
  <!-- Baseboard trim right -->
  <polygon points="32,68 64,52 64,56 32,72" fill="#3B200A"/>
  <line x1="32,68" x2="64,52" stroke="#6E4420" stroke-width="1"/>

  <!-- Isometric Outlines (Dark Walnut Pixel Art Contours) -->
  <polyline points="32,0 64,16 32,32 0,16 32,0" fill="none" stroke="#2B1A10" stroke-width="1"/>
  <line x1="0" y1="16" x2="0" y2="56" stroke="#2B1A10" stroke-width="1"/>
  <line x1="63" y1="16" x2="63" y2="56" stroke="#2B1A10" stroke-width="1"/>
  <line x1="32" y1="32" x2="32" y2="72" stroke="#2B1A10" stroke-width="1"/>
  <polyline points="0,56 32,72 63,56" fill="none" stroke="#1D1109" stroke-width="1"/>
</svg>
`;

async function generateWall() {
  const outPath = path.resolve('godot/assets/sprites/tilemap/wall_wood_quarto.png');
  await sharp(Buffer.from(svg))
    .png()
    .toFile(outPath);
  console.log('Saved', outPath);
}

generateWall();
