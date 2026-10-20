// Sinh các sơ đồ UML dạng .drawio (mở/chỉnh sửa bằng draw.io / diagrams.net)
// và xuất ảnh PNG bằng Chrome headless + draw.io viewer.
//
//   node tool/uml/build.js            -> sinh tất cả
//   node tool/uml/build.js class      -> chỉ sinh sơ đồ có tên chứa "class"
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const outDir = path.resolve(__dirname, '../../docs/uml_diagrams');
const tmpDir = path.join(require('os').tmpdir(), 'uml_render');
const chrome = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const BORDER = 30;

const builders = {
  class_diagram: require('./class_diagram'),
};
for (const name of ['sequence_diagram', 'component_diagram', 'deployment_diagram', 'package_diagram', 'layers_diagram', 'message_bus_diagram', 'usecase_diagram', 'bloc_diagram']) {
  const file = path.join(__dirname, `${name}.js`);
  if (fs.existsSync(file)) builders[name] = require(file);
}

fs.mkdirSync(tmpDir, { recursive: true });
const filter = process.argv[2];

for (const [name, build] of Object.entries(builders)) {
  if (filter && !name.includes(filter)) continue;
  const d = build();
  const xml = d.xml();
  fs.writeFileSync(path.join(outDir, `${name}.drawio`), xml, 'utf8');

  const b = d.bounds;
  const width = Math.ceil(b.x2 - b.x1 + BORDER * 2);
  const height = Math.ceil(b.y2 - b.y1 + BORDER * 2);
  const config = {
    highlight: 'none', nav: false, resize: false, toolbar: null, edit: null,
    lightbox: false, border: BORDER, zoom: 1, xml,
  };
  const attr = JSON.stringify(config).replace(/&/g, '&amp;').replace(/'/g, '&#39;').replace(/</g, '&lt;');
  const html = `<!DOCTYPE html><html><head><meta charset="utf-8">
<style>html,body{margin:0;padding:0;background:#fff;overflow:hidden}</style></head><body>
<div class="mxgraph" data-mxgraph='${attr}'></div>
<script src="https://viewer.diagrams.net/js/viewer-static.min.js"></script></body></html>`;
  const htmlPath = path.join(tmpDir, `${name}.html`);
  fs.writeFileSync(htmlPath, html, 'utf8');

  const pngPath = path.join(outDir, `${name}.png`);
  execFileSync(chrome, [
    '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=2',
    '--virtual-time-budget=20000', `--window-size=${width},${height}`,
    `--screenshot=${pngPath}`, `file:///${htmlPath.replace(/\\/g, '/')}`,
  ], { stdio: 'ignore' });
  console.log(`✔ ${name}: ${width}x${height} -> ${path.relative(process.cwd(), pngPath)}`);
}
