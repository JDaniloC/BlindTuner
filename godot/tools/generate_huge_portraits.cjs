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
const fs = require('fs');
const path = require('path');

const DIR = 'C:/Users/danil/.gemini/antigravity/brain/eb13c739-4486-43dc-a07d-133d19d8e4d6';
const OUT = path.resolve('godot/assets/sprites/ui/portrait');

const files = [
  ['clean_raw_idle.png', 'portrait_idle.png'],
  ['clean_raw_listening.png', 'portrait_listening.png'],
  ['clean_raw_bump.png', 'portrait_bump.png'],
  ['clean_raw_confused.png', 'portrait_confused.png'],
  ['clean_raw_happy.png', 'portrait_happy.png']
];

async function generateHugePortraits() {
  const bufs = [];
  for (const [src, dst] of files) {
    const srcPath = path.join(DIR, src);
    const dstPath = path.join(OUT, dst);
    // Crop perfectly centered 940x940 from top=25, left=64 to keep full head, hair, chin, collar and shoulders
    const buf = await sharp(srcPath)
      .extract({ left: 64, top: 25, width: 940, height: 940 })
      .resize(128, 128, { kernel: 'lanczos3' })
      .png()
      .toBuffer();

    fs.writeFileSync(dstPath, buf);
    bufs.push(buf);
    console.log(`Generated ${dst}`);
  }

  // Composite 640x128 sheet
  const compositeList = bufs.map((buf, i) => ({
    input: buf,
    left: i * 128,
    top: 0
  }));

  const sheet = await sharp({
    create: {
      width: 640,
      height: 128,
      channels: 4,
      background: { r: 0, g: 0, b: 0, alpha: 0 }
    }
  })
  .composite(compositeList)
  .png()
  .toBuffer();

  fs.writeFileSync(path.join(OUT, 'portrait_elderly_sheet.png'), sheet);
  console.log('Generated portrait_elderly_sheet.png');
}

generateHugePortraits();
