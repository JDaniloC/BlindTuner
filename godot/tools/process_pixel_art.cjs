const fs = require('fs');
const path = require('path');
const sharp = require('../../../casarei.online/node_modules/sharp');

// 1px contour outline applicator
function applyOutline(data, width, height, outlineColor = [30, 35, 42]) {
  const result = Buffer.from(data);
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const idx = (y * width + x) * 4;
      if (data[idx + 3] === 0) {
        let hasOpaqueNeighbor = false;
        if (x > 0 && data[idx - 4 + 3] > 180) hasOpaqueNeighbor = true;
        else if (x < width - 1 && data[idx + 4 + 3] > 180) hasOpaqueNeighbor = true;
        else if (y > 0 && data[((y - 1) * width + x) * 4 + 3] > 180) hasOpaqueNeighbor = true;
        else if (y < height - 1 && data[((y + 1) * width + x) * 4 + 3] > 180) hasOpaqueNeighbor = true;

        if (hasOpaqueNeighbor) {
          result[idx] = outlineColor[0];
          result[idx + 1] = outlineColor[1];
          result[idx + 2] = outlineColor[2];
          result[idx + 3] = 255;
        }
      }
    }
  }
  return result;
}

async function processPixelAsset(inputPath, outputPath, targetW, targetH, options = {}) {
  if (!fs.existsSync(inputPath)) {
    throw new Error(`File not found: ${inputPath}`);
  }

  const inputBuf = fs.readFileSync(inputPath);
  const { data, info } = await sharp(inputBuf).raw().toBuffer({ resolveWithObject: true });
  const w = info.width;
  const h = info.height;
  const channels = info.channels;

  const marginTrim = options.marginTrim || 20;
  // Clear outer margins to 255 to eliminate any compression/boundary artifacts
  if (marginTrim > 0) {
    for (let y = 0; y < h; y++) {
      for (let x = 0; x < w; x++) {
        if (x < marginTrim || x >= w - marginTrim || y < marginTrim || y >= h - marginTrim) {
          const idx = (y * w + x) * channels;
          data[idx] = 255;
          data[idx + 1] = 255;
          data[idx + 2] = 255;
        }
      }
    }
  }

  const bgThreshold = options.bgThreshold || 235;
  const visited = new Uint8Array(w * h);
  const queue = [];

  // Seed flood-fill strictly from perimeter borders
  for (let x = 0; x < w; x++) {
    queue.push(x, 0); visited[x] = 1;
    queue.push(x, h - 1); visited[(h - 1) * w + x] = 1;
  }
  for (let y = 0; y < h; y++) {
    queue.push(0, y); visited[y * w] = 1;
    queue.push(w - 1, y); visited[y * w + (w - 1)] = 1;
  }

  let head = 0;
  while (head < queue.length) {
    const cx = queue[head++];
    const cy = queue[head++];
    const idx = (cy * w + cx) * channels;
    const r = data[idx];
    const g = data[idx + 1];
    const b = data[idx + 2];

    if (r >= bgThreshold && g >= bgThreshold && b >= bgThreshold) {
      const neighbors = [
        [cx + 1, cy],
        [cx - 1, cy],
        [cx, cy + 1],
        [cx, cy - 1]
      ];
      for (const [nx, ny] of neighbors) {
        if (nx >= 0 && nx < w && ny >= 0 && ny < h) {
          const nPos = ny * w + nx;
          if (!visited[nPos]) {
            visited[nPos] = 1;
            const nIdx = nPos * channels;
            if (data[nIdx] >= bgThreshold && data[nIdx + 1] >= bgThreshold && data[nIdx + 2] >= bgThreshold) {
              queue.push(nx, ny);
            }
          }
        }
      }
    }
  }

  // Create RGBA buffer with bounding box tracking
  const rgba = Buffer.alloc(w * h * 4);
  let minX = w, maxX = 0, minY = h, maxY = 0;

  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const pos = y * w + x;
      const srcIdx = pos * channels;
      const dstIdx = pos * 4;

      if (visited[pos] && data[srcIdx] >= bgThreshold && data[srcIdx + 1] >= bgThreshold && data[srcIdx + 2] >= bgThreshold) {
        rgba[dstIdx + 3] = 0;
      } else {
        rgba[dstIdx] = data[srcIdx];
        rgba[dstIdx + 1] = data[srcIdx + 1];
        rgba[dstIdx + 2] = data[srcIdx + 2];
        rgba[dstIdx + 3] = 255;

        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  // Defringe 1px outer white halo
  for (let y = minY; y <= maxY; y++) {
    for (let x = minX; x <= maxX; x++) {
      const idx = (y * w + x) * 4;
      if (rgba[idx + 3] > 0) {
        const hasTransNeighbor =
          (x > 0 && rgba[idx - 4 + 3] === 0) ||
          (x < w - 1 && rgba[idx + 4 + 3] === 0) ||
          (y > 0 && rgba[((y - 1) * w + x) * 4 + 3] === 0) ||
          (y < h - 1 && rgba[((y + 1) * w + x) * 4 + 3] === 0);

        if (hasTransNeighbor && rgba[idx] > 220 && rgba[idx + 1] > 220 && rgba[idx + 2] > 220) {
          rgba[idx + 3] = 0; // Eliminate edge bleed
        }
      }
    }
  }

  // Color decontamination on semi-opaque fringe
  for (let y = minY; y <= maxY; y++) {
    for (let x = minX; x <= maxX; x++) {
      const idx = (y * w + x) * 4;
      if (rgba[idx + 3] > 0 && rgba[idx + 3] < 255) {
        rgba[idx + 3] = 255;
      }
    }
  }

  const cropW = maxX - minX + 1;
  const cropH = maxY - minY + 1;

  const croppedPng = await sharp(rgba, { raw: { width: w, height: h, channels: 4 } })
    .extract({ left: minX, top: minY, width: cropW, height: cropH })
    .png()
    .toBuffer();

  // Aspect-preserving scaling via Nearest-Neighbor
  const scale = Math.min(targetW / cropW, targetH / cropH);
  const scaledW = Math.max(1, Math.round(cropW * scale));
  const scaledH = Math.max(1, Math.round(cropH * scale));

  const scaledPng = await sharp(croppedPng)
    .resize(scaledW, scaledH, { kernel: sharp.kernel.nearest })
    .png()
    .toBuffer();

  const leftPad = Math.max(0, Math.floor((targetW - scaledW) / 2));
  const topPad = Math.max(0, targetH - scaledH - (options.bottomInset || 0));

  // Canvas composite
  const canvas = await sharp({
    create: {
      width: targetW,
      height: targetH,
      channels: 4,
      background: { r: 0, g: 0, b: 0, alpha: 0 }
    }
  }).composite([
    { input: scaledPng, left: leftPad, top: topPad }
  ]).png().toBuffer();

  // Apply crisp 1px outline
  const { data: cData, info: cInfo } = await sharp(canvas).raw().toBuffer({ resolveWithObject: true });
  const outlined = applyOutline(cData, cInfo.width, cInfo.height, options.outlineColor || [30, 35, 42]);
  const finalPng = await sharp(outlined, { raw: cInfo }).png().toBuffer();

  const outDir = path.dirname(outputPath);
  if (!fs.existsSync(outDir)) {
    fs.mkdirSync(outDir, { recursive: true });
  }

  fs.writeFileSync(outputPath, finalPng);
  console.log(`✅ Asset salvo: ${outputPath} (${targetW}x${targetH}) [scaled from ${cropW}x${cropH} -> ${scaledW}x${scaledH}]`);
  return outputPath;
}

module.exports = { processPixelAsset, applyOutline };

// CLI Execution if run directly
if (require.main === module) {
  const args = process.argv.slice(2);
  if (args.length < 4) {
    console.log('Uso: node process_pixel_art.cjs <inputFile> <outputFile> <targetW> <targetH>');
    process.exit(1);
  }
  const [inputFile, outputFile, targetW, targetH] = args;
  processPixelAsset(inputFile, outputFile, parseInt(targetW, 10), parseInt(targetH, 10))
    .then(() => console.log('Sucesso!'))
    .catch(err => {
      console.error('Erro ao processar:', err);
      process.exit(1);
    });
}
