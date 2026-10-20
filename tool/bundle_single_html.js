const fs = require('fs');
const path = require('path');

console.log('--- Bundling Luxe Grand Hotel Architecture into a Single Standalone HTML File ---');

const studioDir = path.resolve(__dirname, 'canvas_studio');
const htmlTemplate = fs.readFileSync(path.join(studioDir, 'index.html'), 'utf8');
const cssContent = fs.readFileSync(path.join(studioDir, 'style.css'), 'utf8');
const dataJs = fs.readFileSync(path.join(studioDir, 'diagrams_data.js'), 'utf8');
const appJs = fs.readFileSync(path.join(studioDir, 'app.js'), 'utf8');

const docxPath = path.resolve(__dirname, '../So_Do_Kien_Truc_Luxe_Grand_Hotel.docx');
let docxBase64 = '';
if (fs.existsSync(docxPath)) {
  docxBase64 = fs.readFileSync(docxPath).toString('base64');
  console.log('Embedded docx base64 length:', docxBase64.length);
}

// Enhanced offline Word download script
const enhancedAppJs = `
${appJs}

// Enhanced Offline Word Download Function
const EMBEDDED_DOCX_BASE64 = ${JSON.stringify(docxBase64)};

function downloadOfflineDocx() {
  if (!EMBEDDED_DOCX_BASE64) {
    alert("Tập tin Word không khả dụng trong bản dựng này.");
    return;
  }
  const byteCharacters = atob(EMBEDDED_DOCX_BASE64);
  const byteNumbers = new Array(byteCharacters.length);
  for (let i = 0; i < byteCharacters.length; i++) {
    byteNumbers[i] = byteCharacters.charCodeAt(i);
  }
  const byteArray = new Uint8Array(byteNumbers);
  const blob = new Blob([byteArray], { type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = "So_Do_Kien_Truc_Luxe_Grand_Hotel.docx";
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}
`;

// Replace CSS link with inline style
let bundledHtml = htmlTemplate.replace(
  '<link rel="stylesheet" href="style.css">',
  `<style>\n${cssContent}\n</style>`
);

// Replace download link with onclick handler
bundledHtml = bundledHtml.replace(
  /<a href="\/So_Do_Kien_Truc_Luxe_Grand_Hotel\.docx"[\s\S]*?<\/a>/,
  '<button onclick="downloadOfflineDocx()" class="btn-primary" style="display:inline-flex; align-items:center; gap:6px;">⬇️ Tải File Word Về Máy</button>'
);

// Replace script tags with inline scripts
bundledHtml = bundledHtml.replace(
  /<script src="diagrams_data\.js"><\/script>\s*<script src="app\.js"><\/script>/,
  `<script>\n${dataJs}\n</script>\n<script>\n${enhancedAppJs}\n</script>`
);

const outPath = path.resolve(__dirname, '../So_Do_Kien_Truc_Luxe_Grand_Hotel.html');
fs.writeFileSync(outPath, bundledHtml, 'utf8');

console.log('✓ Successfully created single standalone HTML file:', outPath);
console.log('File size:', fs.statSync(outPath).size, 'bytes');
