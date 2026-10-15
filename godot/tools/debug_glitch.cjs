const sharp = require('../../../casarei.online/node_modules/sharp');
const path = require('path');
const fs = require('fs');

async function debugGlitch() {
  const { data, info } = await sharp('C:/Users/danil/.gemini/antigravity/brain/eb13c739-4486-43dc-a07d-133d19d8e4d6/glitch_character_zoom.png')
    .raw().toBuffer({ resolveWithObject: true });

  for (let y = 80; y < 150; y += 10) {
    let line = 'y=' + y + ': ';
    for (let x = 40; x < 180; x += 10) {
      const idx = (y * info.width + x) * 4;
      line += '[' + data[idx] + ',' + data[idx+1] + ',' + data[idx+2] + '] ';
    }
    console.log(line);
  }
}

debugGlitch();
