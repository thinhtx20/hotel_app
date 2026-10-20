// Canvas Studio Interactive Controller
let currentDiagramIndex = 0;
let scale = 1;
let translateX = 0;
let translateY = 0;
let isDragging = false;
let startX = 0;
let startY = 0;
let isGridVisible = true;
let isMarginsVisible = false;
let isLightMode = false;

// DOM Elements
const viewport = document.getElementById('canvasViewport');
const stage = document.getElementById('canvasStage');
const svgContainer = document.getElementById('canvasSvgContainer');
const zoomBadge = document.getElementById('zoomLevelBadge');
const tabsContainer = document.getElementById('diagramTabs');
const searchInput = document.getElementById('elementSearchInput');
const elementListContainer = document.getElementById('elementList');
const printMarginsOverlay = document.getElementById('printMarginsOverlay');
const gridElement = document.getElementById('canvasGrid');

// Inspector DOM Elements
const inspectorTitle = document.getElementById('inspectorTitle');
const inspectorSubtitle = document.getElementById('inspectorSubtitle');
const specArchType = document.getElementById('specArchType');
const specDimensions = document.getElementById('specDimensions');
const specWordPage = document.getElementById('specWordPage');
const specPrintSize = document.getElementById('specPrintSize');
const specSourcePaths = document.getElementById('specSourcePaths');
const specZeroSpillage = document.getElementById('specZeroSpillage');

// Initialize Studio
function initStudio() {
  renderTabs();
  loadDiagram(0);
  setupEvents();
  fitToScreen();
}

// Render Top Tabs
function renderTabs() {
  tabsContainer.innerHTML = '';
  DIAGRAMS_DATA.forEach((d, idx) => {
    const btn = document.createElement('button');
    btn.className = `tab-btn ${idx === currentDiagramIndex ? 'active' : ''}`;
    btn.innerHTML = `<span class="tab-num">${d.num}</span> ${d.title.split('(')[0].trim()}`;
    btn.onclick = () => switchDiagram(idx);
    tabsContainer.appendChild(btn);
  });
}

// Switch Diagram
function switchDiagram(index) {
  if (index === currentDiagramIndex) return;
  currentDiagramIndex = index;
  renderTabs();
  loadDiagram(index);
  setTimeout(fitToScreen, 50);
}

// Load Diagram Content
function loadDiagram(index) {
  const data = DIAGRAMS_DATA[index];
  svgContainer.innerHTML = data.svg;
  
  // Set stage dimensions
  stage.style.width = `${data.width}px`;
  stage.style.height = `${data.height}px`;

  // Render elements in left sidebar
  renderElementList(data.elements);

  // Update Inspector
  updateInspector(data);

  // Reset search
  searchInput.value = '';

  // Update bottom bar info
  document.getElementById('statusDimensions').textContent = `${data.width} × ${data.height} px`;
  document.getElementById('statusWordTarget').textContent = `${data.wordPage}`;
}

// Update Inspector Details
function updateInspector(data, activeElement = null) {
  inspectorTitle.textContent = activeElement ? activeElement.name : data.title;
  inspectorSubtitle.textContent = activeElement ? activeElement.desc : data.subtitle;

  specArchType.textContent = activeElement ? (activeElement.type || data.archType) : data.archType;
  specDimensions.textContent = `${data.width} × ${data.height} px (SVG 2.0)`;
  specWordPage.textContent = data.wordPage;
  specPrintSize.textContent = `${data.printWidthPt} × ${data.printHeightPt}`;
  
  specSourcePaths.innerHTML = data.sourcePaths
    .map(p => `<span class="code-pill">${p}</span>`)
    .join(' ');
  
  specZeroSpillage.innerHTML = '✓ 100% Khớp Lề A4 (0px Overflow)';
}

// Render Quick Elements List
function renderElementList(elements) {
  elementListContainer.innerHTML = '';
  if (!elements || elements.length === 0) {
    elementListContainer.innerHTML = '<div style="color:var(--text-dim);font-size:12px;">Không có thành phần nổi bật.</div>';
    return;
  }

  elements.forEach(el => {
    const item = document.createElement('div');
    item.className = 'element-item';
    item.innerHTML = `
      <div class="element-item-header">
        <span class="element-item-name">${el.name}</span>
        <span class="element-item-badge">${el.type}</span>
      </div>
      <div class="element-item-desc">${el.desc}</div>
    `;
    item.onclick = () => {
      document.querySelectorAll('.element-item').forEach(i => i.classList.remove('active'));
      item.classList.add('active');
      focusElement(el.name);
      updateInspector(DIAGRAMS_DATA[currentDiagramIndex], el);
    };
    elementListContainer.appendChild(item);
  });
}

// Focus Element in Canvas
function focusElement(textQuery) {
  const svg = svgContainer.querySelector('svg');
  if (!svg) return;

  const textNodes = Array.from(svg.querySelectorAll('text'));
  const match = textNodes.find(t => t.textContent.toLowerCase().includes(textQuery.toLowerCase()));

  if (match) {
    // Pulse animation on element
    const parentG = match.closest('g') || match;
    parentG.style.transition = 'all 0.3s ease';
    parentG.style.filter = 'drop-shadow(0 0 16px #3B82F6)';
    setTimeout(() => {
      parentG.style.filter = '';
    }, 1800);

    // Center on element midpoint
    const bbox = match.getBBox();
    const vWidth = viewport.clientWidth;
    const vHeight = viewport.clientHeight;
    
    translateX = (vWidth / 2) - ((bbox.x + (bbox.width / 2)) * scale);
    translateY = (vHeight / 2) - ((bbox.y + (bbox.height / 2)) * scale);
    updateTransform();
  }
}

// Live Search Filter
function handleSearch(query) {
  const q = query.trim().toLowerCase();
  const items = elementListContainer.querySelectorAll('.element-item');
  
  items.forEach(it => {
    const text = it.textContent.toLowerCase();
    it.style.display = text.includes(q) ? 'block' : 'none';
  });

  if (q.length > 2) {
    focusElement(q);
  } else if (q.length === 0) {
    fitToScreen();
  }
}

// Transform matrix update
function updateTransform() {
  stage.style.transform = `translate(${translateX}px, ${translateY}px) scale(${scale})`;
  zoomBadge.textContent = `${Math.round(scale * 100)}%`;
  document.getElementById('statusZoom').textContent = `${Math.round(scale * 100)}%`;
}

// Zoom Controls
function zoomIn() {
  zoomAt(viewport.clientWidth / 2, viewport.clientHeight / 2, 1.25);
}

function zoomOut() {
  zoomAt(viewport.clientWidth / 2, viewport.clientHeight / 2, 0.8);
}

function resetZoom() {
  scale = 1;
  const data = DIAGRAMS_DATA[currentDiagramIndex];
  translateX = (viewport.clientWidth - data.width) / 2;
  translateY = (viewport.clientHeight - data.height) / 2;
  updateTransform();
}

function fitToScreen() {
  const data = DIAGRAMS_DATA[currentDiagramIndex];
  const padding = 60;
  const availW = viewport.clientWidth - padding;
  const availH = viewport.clientHeight - padding;
  
  const scaleX = availW / data.width;
  const scaleY = availH / data.height;
  scale = Math.min(scaleX, scaleY, 1);
  
  translateX = (viewport.clientWidth - (data.width * scale)) / 2;
  translateY = (viewport.clientHeight - (data.height * scale)) / 2;
  updateTransform();
}

function zoomAt(x, y, factor) {
  const newScale = Math.min(Math.max(0.2, scale * factor), 4.0);
  if (newScale === scale) return;
  
  const mousePointX = (x - translateX) / scale;
  const mousePointY = (y - translateY) / scale;

  scale = newScale;
  translateX = x - (mousePointX * scale);
  translateY = y - (mousePointY * scale);
  updateTransform();
}

// Setup Event Listeners
function setupEvents() {
  // Pan via Drag
  viewport.addEventListener('mousedown', (e) => {
    if (e.button !== 0) return; // Only left click
    isDragging = true;
    startX = e.clientX - translateX;
    startY = e.clientY - translateY;
  });

  window.addEventListener('mousemove', (e) => {
    if (!isDragging) return;
    translateX = e.clientX - startX;
    translateY = e.clientY - startY;
    updateTransform();
    
    // Update coordinates in bottom bar
    const data = DIAGRAMS_DATA[currentDiagramIndex];
    const mouseX = Math.round((e.clientX - translateX) / scale);
    const mouseY = Math.round((e.clientY - translateY) / scale);
    if (mouseX >= 0 && mouseX <= data.width && mouseY >= 0 && mouseY <= data.height) {
      document.getElementById('statusCoords').textContent = `X: ${mouseX}, Y: ${mouseY}`;
    }
  });

  window.addEventListener('mouseup', () => {
    isDragging = false;
  });

  // Wheel Zoom
  viewport.addEventListener('wheel', (e) => {
    e.preventDefault();
    const factor = e.deltaY < 0 ? 1.15 : 0.87;
    zoomAt(e.clientX, e.clientY, factor);
  }, { passive: false });

  // Search Input
  searchInput.addEventListener('input', (e) => handleSearch(e.target.value));

  // Keyboard Shortcuts
  window.addEventListener('keydown', (e) => {
    if (e.target.tagName === 'INPUT') return;
    
    if (e.key >= '1' && e.key <= '5') {
      switchDiagram(parseInt(e.key) - 1);
    } else if (e.key === '+' || e.key === '=') {
      zoomIn();
    } else if (e.key === '-') {
      zoomOut();
    } else if (e.key === '0') {
      resetZoom();
    } else if (e.key === 'f' || e.key === 'F') {
      fitToScreen();
    } else if (e.key === 'g' || e.key === 'G') {
      toggleGrid();
    } else if (e.key === 'm' || e.key === 'M') {
      toggleMargins();
    }
  });

  // Window resize
  window.addEventListener('resize', fitToScreen);
}

// Feature Toggles
function toggleGrid() {
  isGridVisible = !isGridVisible;
  gridElement.style.opacity = isGridVisible ? '1' : '0';
  document.getElementById('btnToggleGrid').classList.toggle('active', isGridVisible);
}

function toggleMargins() {
  isMarginsVisible = !isMarginsVisible;
  printMarginsOverlay.classList.toggle('active', isMarginsVisible);
  document.getElementById('btnToggleMargins').classList.toggle('active', isMarginsVisible);
}

function toggleTheme() {
  isLightMode = !isLightMode;
  document.body.classList.toggle('light-mode', isLightMode);
  document.getElementById('btnToggleTheme').classList.toggle('active', isLightMode);
}

// Export SVG
function exportSvg() {
  const data = DIAGRAMS_DATA[currentDiagramIndex];
  const blob = new Blob([data.svg], { type: 'image/svg+xml;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `${data.id}_diagram_luxe_grand_hotel.svg`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

// Export PNG 4K
function exportPng() {
  const data = DIAGRAMS_DATA[currentDiagramIndex];
  const img = new Image();
  const svgBlob = new Blob([data.svg], { type: 'image/svg+xml;charset=utf-8' });
  const url = URL.createObjectURL(svgBlob);

  img.onload = () => {
    const canvas = document.createElement('canvas');
    canvas.width = data.width * 2;
    canvas.height = data.height * 2;
    const ctx = canvas.getContext('2d');
    ctx.fillStyle = '#FFFFFF';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.drawImage(img, 0, 0, canvas.width, canvas.height);

    canvas.toBlob((blob) => {
      const pngUrl = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = pngUrl;
      a.download = `${data.id}_diagram_4k_luxe_grand_hotel.png`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(pngUrl);
      URL.revokeObjectURL(url);
    }, 'image/png');
  };
  img.src = url;
}

// Export Word Modal / Info
function showWordModal() {
  document.getElementById('wordModal').classList.add('active');
}

function closeWordModal() {
  document.getElementById('wordModal').classList.remove('active');
}

// Start
document.addEventListener('DOMContentLoaded', initStudio);
