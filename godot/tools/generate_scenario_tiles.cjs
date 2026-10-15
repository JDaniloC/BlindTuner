const fs = require('fs');
const path = require('path');
const sharp = require('../../../casarei.online/node_modules/sharp');

const TILEMAP_DIR = path.resolve('godot/assets/sprites/tilemap');
if (!fs.existsSync(TILEMAP_DIR)) {
  fs.mkdirSync(TILEMAP_DIR, { recursive: true });
}

// 64x32 Floor Tile: Diamond (0,16), (32,0), (64,16), (32,32)
// Isometric 2:1 slope (+0.5 and -0.5)

function generateWoodFloorA() {
  // Cozy oak wood planks along South-East axis
  return `
<svg width="64" height="32" viewBox="0 0 64 32" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">
  <!-- Base diamond -->
  <polygon points="32,0 64,16 32,32 0,16" fill="#8B5A2B"/>

  <!-- Plank 1 (Top-Left) -->
  <polygon points="32,0 42,5 10,21 0,16" fill="#9B6835"/>
  <line x1="42" y1="5" x2="10" y2="21" stroke="#6F421D" stroke-width="1"/>

  <!-- Plank 2 (Center) -->
  <polygon points="42,5 53,10.5 21,26.5 10,21" fill="#8B5A2B"/>
  <line x1="53" y1="10.5" x2="21" y2="26.5" stroke="#6F421D" stroke-width="1"/>

  <!-- Plank 3 (Bottom-Right) -->
  <polygon points="53,10.5 64,16 32,32 21,26.5" fill="#93602F"/>

  <!-- Subtle grain lines -->
  <line x1="16" y1="8" x2="26" y2="13" stroke="#7A4B22" stroke-width="0.7" stroke-dasharray="4 2 5 2"/>
  <line x1="26" y1="13" x2="37" y2="18.5" stroke="#7A4B22" stroke-width="0.7" stroke-dasharray="6 3 4 2"/>
  <line x1="37" y1="18.5" x2="48" y2="24" stroke="#7A4B22" stroke-width="0.7" stroke-dasharray="3 2 7 2"/>

  <!-- Staggered joints -->
  <line x1="21" y1="10.5" x2="26" y2="8" stroke="#5F3818" stroke-width="1"/>
  <line x1="37" y1="18.5" x2="42" y2="16" stroke="#5F3818" stroke-width="1"/>

  <!-- Subtle warm highlight sheen -->
  <polygon points="32,0 50,9 35,16 17,7" fill="#FFFFFF" opacity="0.08"/>
</svg>
`;
}

function generateWoodFloorB() {
  // Cozy oak wood planks variation with knot and alternate tones
  return `
<svg width="64" height="32" viewBox="0 0 64 32" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">
  <!-- Base diamond -->
  <polygon points="32,0 64,16 32,32 0,16" fill="#825225"/>

  <!-- Plank 1 (Top-Left) -->
  <polygon points="32,0 42,5 10,21 0,16" fill="#91602F"/>
  <line x1="42" y1="5" x2="10" y2="21" stroke="#673C19" stroke-width="1"/>

  <!-- Plank 2 (Center) -->
  <polygon points="42,5 53,10.5 21,26.5 10,21" fill="#845427"/>
  <line x1="53" y1="10.5" x2="21" y2="26.5" stroke="#673C19" stroke-width="1"/>

  <!-- Plank 3 (Bottom-Right) -->
  <polygon points="53,10.5 64,16 32,32 21,26.5" fill="#8D5C2C"/>

  <!-- Wood knot on center plank -->
  <circle cx="36" cy="14" r="1.5" fill="#5F3717"/>
  <circle cx="36" cy="14" r="2.8" fill="none" stroke="#72451F" stroke-width="0.6"/>

  <!-- Subtle grain lines -->
  <line x1="14" y1="7" x2="24" y2="12" stroke="#72451F" stroke-width="0.7" stroke-dasharray="5 3 6 2"/>
  <line x1="40" y1="20" x2="50" y2="25" stroke="#72451F" stroke-width="0.7" stroke-dasharray="4 2 8 2"/>

  <!-- Staggered joints -->
  <line x1="16" y1="13" x2="21" y2="10.5" stroke="#5F3818" stroke-width="1"/>
  <line x1="47" y1="13.5" x2="53" y2="10.5" stroke="#5F3818" stroke-width="1"/>

  <!-- Warm sheen -->
  <polygon points="32,0 48,8 32,16 16,8" fill="#FFFFFF" opacity="0.06"/>
</svg>
`;
}

function generateWallNW() {
  // North-West wall: slopes down-left from right to left
  // Top: (0, 16) -> (64, -16) or relative to 64x64 canvas:
  // In 64x64 canvas, wall height = 32px
  // Base line: from (0, 48) to (64, 16) [slope -0.5]
  // Top line: from (0, 16) to (64, -16) -> let's place base at (0, 48) to (64, 16)?
  // Standard 2:1 isometric wall:
  // Left edge X=0: Y from 16 to 48 (height 32)
  // Right edge X=64: Y from 0 to 32 (height 32, or 48 for taller wall)
  // Let's create standard 64x64 wall segment for North-West (face points South-East):
  return `
<svg width="64" height="64" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">
  <!-- Main Wall Surface (warm cream plaster with gentle cel-shading) -->
  <polygon points="0,16 64,0 64,48 0,64" fill="#EAE4D6"/>
  <polygon points="0,16 64,0 64,24 0,40" fill="#F4EFE5" opacity="0.4"/>

  <!-- Plaster texture lines -->
  <line x1="0" y1="28" x2="64" y2="12" stroke="#DFD7C5" stroke-width="1" stroke-dasharray="12 8 20 6"/>
  <line x1="0" y1="44" x2="64" y2="28" stroke="#DFD7C5" stroke-width="1" stroke-dasharray="16 10 14 8"/>

  <!-- Top Crown Molding -->
  <polygon points="0,16 64,0 64,3 0,19" fill="#FFFDF8"/>
  <line x1="0" y1="19" x2="64" y2="3" stroke="#D0C8B6" stroke-width="1"/>

  <!-- Wooden Baseboard (Rodapé de carvalho no pé da parede) -->
  <polygon points="0,58 64,42 64,48 0,64" fill="#6B411D"/>
  <polygon points="0,56 64,40 64,58 0,58" fill="#805126"/>
  <line x1="0" y1="56" x2="64" y2="40" stroke="#553213" stroke-width="1"/>
  <line x1="0" y1="64" x2="64" y2="48" stroke="#3F2309" stroke-width="1"/>

  <!-- Vertical 1px dark contour on left boundary -->
  <line x1="0" y1="16" x2="0" y2="64" stroke="#2B201A" stroke-width="1"/>
</svg>
`;
}

function generateWallNE() {
  // North-East wall: slopes down-right from left to right
  // Base line: from (0, 16) to (64, 48) [slope +0.5]
  // Face points South-West
  return `
<svg width="64" height="64" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">
  <!-- Main Wall Surface (warm cream plaster, slightly darker for depth) -->
  <polygon points="0,0 64,16 64,64 0,48" fill="#DFD7C5"/>
  <polygon points="0,0 64,16 64,24 0,8" fill="#EAE4D6" opacity="0.4"/>

  <!-- Plaster texture lines -->
  <line x1="0" y1="12" x2="64" y2="28" stroke="#D2C8B4" stroke-width="1" stroke-dasharray="14 6 18 8"/>
  <line x1="0" y1="28" x2="64" y2="44" stroke="#D2C8B4" stroke-width="1" stroke-dasharray="10 12 16 6"/>

  <!-- Top Crown Molding -->
  <polygon points="0,0 64,16 64,19 0,3" fill="#F4EFE5"/>
  <line x1="0" y1="3" x2="64" y2="19" stroke="#C5BBA7" stroke-width="1"/>

  <!-- Wooden Baseboard (Rodapé de carvalho no pé da parede) -->
  <polygon points="0,42 64,58 64,64 0,48" fill="#5F3818"/>
  <polygon points="0,40 64,56 64,58 0,42" fill="#75471F"/>
  <line x1="0" y1="40" x2="64" y2="56" stroke="#4C2B0E" stroke-width="1"/>
  <line x1="0" y1="48" x2="64" y2="64" stroke="#351B06" stroke-width="1"/>

  <!-- Vertical 1px dark contour on right boundary -->
  <line x1="63" y1="16" x2="63" y2="64" stroke="#2B201A" stroke-width="1"/>
</svg>
`;
}

async function run() {
  console.log('--- Generating Pixel-Perfect Scenario Tiles for BlindTuner ---');

  // 1. Wood Floor A (64x32)
  const floorABuf = Buffer.from(generateWoodFloorA());
  await sharp(floorABuf).png().toFile(path.join(TILEMAP_DIR, 'floor_wood_oak_a.png'));
  console.log('✅ Generated: floor_wood_oak_a.png (64x32)');

  // 2. Wood Floor B (64x32)
  const floorBBuf = Buffer.from(generateWoodFloorB());
  await sharp(floorBBuf).png().toFile(path.join(TILEMAP_DIR, 'floor_wood_oak_b.png'));
  console.log('✅ Generated: floor_wood_oak_b.png (64x32)');

  // 3. Wall North-West (64x64)
  const wallNWBuf = Buffer.from(generateWallNW());
  await sharp(wallNWBuf).png().toFile(path.join(TILEMAP_DIR, 'wall_nw.png'));
  console.log('✅ Generated: wall_nw.png (64x64)');

  // 4. Wall North-East (64x64)
  const wallNEBuf = Buffer.from(generateWallNE());
  await sharp(wallNEBuf).png().toFile(path.join(TILEMAP_DIR, 'wall_ne.png'));
  console.log('✅ Generated: wall_ne.png (64x64)');

  console.log('--- Scenario Base Tiles Completed Successfully! ---');
}

run().catch(err => {
  console.error('Error generating tiles:', err);
  process.exit(1);
});
