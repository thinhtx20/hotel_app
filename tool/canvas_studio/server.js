const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 3456;
const studioDir = path.resolve(__dirname);
const rootDir = path.resolve(__dirname, '../../');

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml; charset=utf-8',
  '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
};

const server = http.createServer((req, res) => {
  let reqPath = decodeURI(req.url.split('?')[0]);
  if (reqPath === '/') reqPath = '/index.html';

  // Check if file is in studio directory first
  let filePath = path.join(studioDir, reqPath);
  if (!fs.existsSync(filePath)) {
    // Check root directory
    filePath = path.join(rootDir, reqPath);
  }

  if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';
    res.writeHead(200, { 'Content-Type': contentType });
    fs.createReadStream(filePath).pipe(res);
  } else {
    res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('404 Not Found: ' + reqPath);
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Luxe Grand Hotel Canvas Studio is running:`);
  console.log(`- Local:   http://localhost:${PORT}`);
  console.log(`- Network: http://172.16.1.47:${PORT}`);
});
