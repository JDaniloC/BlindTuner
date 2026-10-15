const sharp = require('../../../casarei.online/node_modules/sharp');
const path = require('path');

async function inspectOriginal() {
  const { data, info } = await sharp('godot/assets/sprites/character_backup_original/16x32/16x32 Idle-Sheet.png')
    .raw().toBuffer({ resolveWithObject: true });

  for (let r = 0; r < 5; r++) {
    console.log(`=== ROW ${r} (c=0) ===`);
    for (let fy = 13; fy <= 20; fy++) {
      let line = `fy=${fy}: `;
      for (let fx = 10; fx <= 22; fx++) {
        const idx = ((r * 32 + fy) * info.width + fx) * 4;
        const hex = ((data[idx] << 16) | (data[idx+1] << 8) | data[idx+2]).toString(16).padStart(6, '0');
        line += `${hex} `;
      }
      console.log(line);
    }
  }
}

inspectOriginal();
