const http = require("http");
const fs = require("fs");
const path = require("path");
const { chromium } = require("playwright");

// Servidor estático ultra-simples para servir o dist
const distDir = path.join(__dirname, "dist");
const mimeTypes = {
  ".html": "text/html",
  ".js": "application/javascript",
  ".css": "text/css",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".json": "application/json",
};

const server = http.createServer((req, res) => {
  let reqPath = req.url.split("?")[0];
  if (reqPath === "/") reqPath = "/index.html";
  const filePath = path.join(distDir, reqPath);

  if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
    const ext = path.extname(filePath);
    res.writeHead(200, {
      "Content-Type": mimeTypes[ext] || "application/octet-stream",
      "Cross-Origin-Opener-Policy": "same-origin",
      "Cross-Origin-Embedder-Policy": "require-corp",
    });
    fs.createReadStream(filePath).pipe(res);
  } else {
    res.writeHead(404);
    res.end("Not Found");
  }
});

async function run() {
  server.listen(4173, async () => {
    console.log("Servidor local iniciado na porta 4173.");

    const browser = await chromium.launch({
      headless: true,
      args: [
        "--use-gl=angle",
        "--use-angle=swiftshader",
        "--enable-webgl",
        "--enable-unsafe-webgpu",
        "--no-sandbox",
      ],
    });

    const page = await browser.newPage({
      viewport: { width: 540, height: 960 },
      deviceScaleFactor: 2,
    });

    await page.goto("http://localhost:4173", { waitUntil: "networkidle" });
    console.log("Página carregada com sucesso.");

    // Clica no botão de iniciar para desbloquear o áudio e loop
    await page.click("#btn-start");
    console.log("Botão iniciar clicado.");

    // Espera 1.2 segundos para a cena renderizar e a prévia da primeira nota tocar
    await page.waitForTimeout(1200);

    const artifactDir = "C:\\Users\\danil\\.gemini\\antigravity\\brain\\3cdf66e1-7446-4272-b1f4-e65d042e310d";
    const outLocal = path.join(__dirname, "poc_web_showcase.png");
    const outArtifact = path.join(artifactDir, "poc_web_showcase.png");

    await page.screenshot({ path: outLocal });
    if (fs.existsSync(artifactDir)) {
      fs.copyFileSync(outLocal, outArtifact);
    }
    console.log("Screenshot 1 salvo:", outLocal);

    // Agora simula o arrasto no Scroll de Afinação para capturar o Sr. Arthur em modo de afinador
    const scrollBox = await page.locator("canvas").boundingBox();
    if (scrollBox) {
      // O scroll está à direita: x = width - 40, y varia de 350 a 480
      const startX = scrollBox.x + scrollBox.width - 38;
      const startY = scrollBox.y + scrollBox.height * 0.5;

      await page.mouse.move(startX, startY);
      await page.mouse.down();
      // Move para cima para afinar uma nota e girar o Sr. Arthur e o Violoncelo
      await page.mouse.move(startX, startY - 120, { steps: 8 });
      await page.waitForTimeout(500);

      const outTuningLocal = path.join(__dirname, "poc_web_tuning_showcase.png");
      const outTuningArtifact = path.join(artifactDir, "poc_web_tuning_showcase.png");

      await page.screenshot({ path: outTuningLocal });
      if (fs.existsSync(artifactDir)) {
        fs.copyFileSync(outTuningLocal, outTuningArtifact);
      }
      console.log("Screenshot 2 (Tuning Pixel Art) salvo:", outTuningLocal);

      // Alterna o estilo para demonstrar a alternância em tempo real entre Pixel Art e Vetorial HD
      await page.click("#btn-style-toggle");
      await page.waitForTimeout(400);

      const outHdLocal = path.join(__dirname, "poc_web_hd_showcase.png");
      const outHdArtifact = path.join(artifactDir, "poc_web_hd_showcase.png");

      await page.screenshot({ path: outHdLocal });
      if (fs.existsSync(artifactDir)) {
        fs.copyFileSync(outHdLocal, outHdArtifact);
      }
      console.log("Screenshot 3 (Vetorial HD) salvo:", outHdLocal);

      await page.mouse.up();
    }

    await browser.close();
    server.close();
    console.log("Captura concluída com sucesso!");
    process.exit(0);
  });
}

run().catch((err) => {
  console.error("Erro na captura:", err);
  server.close();
  process.exit(1);
});
