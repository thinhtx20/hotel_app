// Bộ dựng file .drawio (mxGraph XML) cho các sơ đồ UML.
// Mọi hình đều dùng ký hiệu UML 2.5 chuẩn: nét đen, nền trắng, từ khóa «...».

const FONT = 'fontFamily=Helvetica;fontColor=#000000;';
const STROKE = 'strokeColor=#000000;';

function esc(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

class Diagram {
  constructor(name) {
    this.name = name;
    this.cells = [];
    this.next = 2;
    this.bounds = { x1: Infinity, y1: Infinity, x2: -Infinity, y2: -Infinity };
    this.geo = {};
  }

  newId() {
    return `${this.name}-${this.next++}`;
  }

  track(x, y, w = 0, h = 0) {
    const b = this.bounds;
    b.x1 = Math.min(b.x1, x);
    b.y1 = Math.min(b.y1, y);
    b.x2 = Math.max(b.x2, x + w);
    b.y2 = Math.max(b.y2, y + h);
  }

  // Tọa độ (x, y) luôn là tuyệt đối; nếu có parent thì tự quy đổi sang tương đối.
  vertex(value, style, x, y, w, h, parent) {
    const id = this.newId();
    const p = parent ? this.geo[parent] : null;
    const rx = p ? x - p.x : x;
    const ry = p ? y - p.y : y;
    this.geo[id] = { x, y, w, h };
    this.track(x, y, w, h);
    this.cells.push(
      `<mxCell id="${id}" value="${esc(value)}" style="${FONT}${style}" vertex="1" parent="${parent || '1'}">` +
        `<mxGeometry x="${rx}" y="${ry}" width="${w}" height="${h}" as="geometry"/></mxCell>`,
    );
    return id;
  }

  // opts: source/target (id ô) hoặc sp/tp (điểm tuyệt đối [x,y]), points: [[x,y],...]
  edge(value, style, opts = {}) {
    const id = this.newId();
    const attrs = [];
    if (opts.source) attrs.push(`source="${opts.source}"`);
    if (opts.target) attrs.push(`target="${opts.target}"`);
    let geo = '<mxGeometry relative="1" as="geometry">';
    if (opts.sp) {
      geo += `<mxPoint x="${opts.sp[0]}" y="${opts.sp[1]}" as="sourcePoint"/>`;
      this.track(opts.sp[0], opts.sp[1]);
    }
    if (opts.tp) {
      geo += `<mxPoint x="${opts.tp[0]}" y="${opts.tp[1]}" as="targetPoint"/>`;
      this.track(opts.tp[0], opts.tp[1]);
    }
    if (opts.points && opts.points.length) {
      geo += '<Array as="points">';
      for (const [x, y] of opts.points) {
        geo += `<mxPoint x="${x}" y="${y}"/>`;
        this.track(x, y);
      }
      geo += '</Array>';
    }
    geo += '</mxGeometry>';
    const lbl = opts.labelBg === false ? 'labelBackgroundColor=none;' : 'labelBackgroundColor=#FFFFFF;';
    this.cells.push(
      `<mxCell id="${id}" value="${esc(value)}" style="${FONT}${STROKE}${lbl}html=1;rounded=0;fontSize=11;${style}" edge="1" parent="1" ${attrs.join(' ')}>` +
        `${geo}</mxCell>`,
    );
    return id;
  }

  // Nhãn gắn vào đầu mút cạnh: pos = -1 (đầu nguồn), 1 (đầu đích), 0 (giữa).
  edgeLabel(edgeId, value, pos, dx, dy, align = 'left', valign = 'middle') {
    const id = this.newId();
    this.cells.push(
      `<mxCell id="${id}" value="${esc(value)}" style="${FONT}edgeLabel;resizable=0;html=1;fontSize=11;align=${align};verticalAlign=${valign};labelBackgroundColor=none;" vertex="1" connectable="0" parent="${edgeId}">` +
        `<mxGeometry x="${pos}" relative="1" as="geometry"><mxPoint x="${dx}" y="${dy}" as="offset"/></mxGeometry></mxCell>`,
    );
    return id;
  }

  xml() {
    return (
      `<mxfile host="drawio" type="device"><diagram name="${esc(this.name)}" id="${this.name}">` +
      `<mxGraphModel grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="0" pageScale="1" math="0" shadow="0" background="#FFFFFF">` +
      `<root><mxCell id="0"/><mxCell id="1" parent="0"/>${this.cells.join('')}</root></mxGraphModel></diagram></mxfile>`
    );
  }
}

// ---------- Kiểu nét UML ----------
const S = {
  text: 'text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=top;whiteSpace=nowrap;',
  note: `shape=note;size=14;whiteSpace=wrap;html=1;align=left;verticalAlign=top;spacingLeft=8;spacingTop=4;fillColor=#FFFFFF;${STROKE}fontSize=11;`,
  noteLink: 'endArrow=none;dashed=1;dashPattern=4 4;',
  association: 'endArrow=none;edgeStyle=orthogonalEdgeStyle;jumpStyle=arc;jumpSize=10;',
  navigable: 'endArrow=open;endFill=0;endSize=10;edgeStyle=orthogonalEdgeStyle;jumpStyle=arc;jumpSize=10;',
  composition: 'startArrow=diamondThin;startFill=1;startSize=16;endArrow=none;edgeStyle=orthogonalEdgeStyle;',
  aggregation: 'startArrow=diamondThin;startFill=0;startSize=16;endArrow=none;edgeStyle=orthogonalEdgeStyle;',
  dependency: 'endArrow=open;endFill=0;endSize=10;dashed=1;dashPattern=6 4;',
  generalization: 'endArrow=block;endFill=0;endSize=14;edgeStyle=orthogonalEdgeStyle;',
  realization: 'endArrow=block;endFill=0;endSize=14;dashed=1;dashPattern=6 4;',
  line: 'endArrow=none;',
};

const LINE_H = 15.4;

// Lớp UML 3 ngăn: tên | thuộc tính | thao tác.
function classBox(d, { x, y, w, name, stereotype, italic, attrs = [], ops = [], showOps = true }) {
  const head = stereotype ? 42 : 28;
  const attrH = Math.round(Math.max(attrs.length, 1) * LINE_H + 12);
  const opsH = showOps ? Math.round(ops.length * LINE_H + (ops.length ? 10 : 12)) : 0;
  const h = head + attrH + opsH;
  const title = stereotype
    ? `<span style="font-weight:normal">«${stereotype}»</span><br><b>${italic ? `<i>${name}</i>` : name}</b>`
    : `<b>${italic ? `<i>${name}</i>` : name}</b>`;
  const id = d.vertex(
    title,
    `swimlane;html=1;fontStyle=0;align=center;verticalAlign=top;startSize=${head};horizontal=1;collapsible=0;fillColor=#FFFFFF;swimlaneFillColor=#FFFFFF;${STROKE}fontSize=12;spacingTop=2;`,
    x, y, w, h,
  );
  d.vertex(attrs.join('<br>'), `${S.text}spacingLeft=6;spacingTop=3;fontSize=12;`, x, y + head, w, attrH, id);
  if (showOps) {
    d.vertex('', `line;strokeWidth=1;fillColor=none;${STROKE}`, x, y + head + attrH - 4, w, 8, id);
    d.vertex(ops.join('<br>'), `${S.text}spacingLeft=6;spacingTop=3;fontSize=12;`, x, y + head + attrH, w, opsH, id);
  }
  return { id, x, y, w, h };
}

// Đổi điểm tuyệt đối thành tỉ lệ trên biên ô (dùng cho exitX/entryX).
function rel(box, ax, ay) {
  return [+((ax - box.x) / box.w).toFixed(4), +((ay - box.y) / box.h).toFixed(4)];
}

function anchor(prefix, box, ax, ay) {
  const [rx, ry] = rel(box, ax, ay);
  return `${prefix}X=${rx};${prefix}Y=${ry};${prefix}Dx=0;${prefix}Dy=0;`;
}

function sideOf(box, ax, ay) {
  if (Math.abs(ay - box.y) < 1) return 'top';
  if (Math.abs(ay - (box.y + box.h)) < 1) return 'bottom';
  if (Math.abs(ax - box.x) < 1) return 'left';
  return 'right';
}

// Bội số đặt một bên đường nối, tên vai trò đặt bên còn lại.
function endLabels(d, edgeId, pos, side, mult, role) {
  const L = {
    bottom: [[7, 6, 'left', 'top'], [-7, 6, 'right', 'top']],
    top: [[7, -6, 'left', 'bottom'], [-7, -6, 'right', 'bottom']],
    right: [[8, -5, 'left', 'bottom'], [8, 5, 'left', 'top']],
    left: [[-8, -5, 'right', 'bottom'], [-8, 5, 'right', 'top']],
  }[side];
  if (mult) d.edgeLabel(edgeId, mult, pos, ...L[0]);
  if (role) d.edgeLabel(edgeId, role, pos, ...L[1]);
}

// Đường nối giữa hai hộp, neo tại điểm tuyệt đối `from` (trên biên a) và `to` (trên biên b).
function link(d, a, b, { from, to, style, name = '', aMult, aRole, bMult, bRole, points }) {
  const e = d.edge(name, style + anchor('exit', a, ...from) + anchor('entry', b, ...to), {
    source: a.id,
    target: b.id,
    points,
  });
  endLabels(d, e, -1, sideOf(a, ...from), aMult, aRole);
  endLabels(d, e, 1, sideOf(b, ...to), bMult, bRole);
  return e;
}

module.exports = { Diagram, S, classBox, rel, anchor, link, esc, STROKE, FONT, LINE_H };
