// Chuyển báo cáo Markdown sang Word (.docx) theo định dạng khóa luận: A4, Times New Roman 13,
// trang bìa có khung, mục lục tự động, danh mục hình/bảng sinh từ chú thích.
//
// node tool/docx/md_to_docx.js [input.md] [output.docx]
// Hỗ trợ: #..#### tiêu đề, đoạn văn (**đậm**, *nghiêng*, `mã`), danh sách -, +, 1., bảng |, khối ```,
// trích dẫn >, ảnh ![](đường dẫn), \newpage, chú thích *Hình x.y: …* / *Bảng x.y: …*,
// và các dấu <!-- MUC_LUC -->, <!-- DANH_MUC_HINH -->, <!-- DANH_MUC_BANG -->.
const fs = require('fs');
const path = require('path');
const {
  Document,
  Packer,
  Paragraph,
  TextRun,
  HeadingLevel,
  Table,
  TableRow,
  TableCell,
  WidthType,
  AlignmentType,
  BorderStyle,
  ShadingType,
  ImageRun,
  Header,
  Footer,
  PageNumber,
  PageBreak,
  LevelFormat,
  TableOfContents,
  VerticalAlign,
  TableLayoutType,
} = require('docx');

const ROOT_DIR = path.resolve(__dirname, '../../');
const INPUT = path.resolve(process.argv[2] || path.join(ROOT_DIR, 'BAO_CAO_TOT_NGHIEP_HE_THONG_QUAN_LY_KHACH_SAN.md'));
const OUTPUT = path.resolve(process.argv[3] || INPUT.replace(/\.md$/i, '.docx'));
const BASE_DIR = path.dirname(INPUT);

const FONT = 'Times New Roman';
const MONO = 'Consolas';
const NAVY = '1B365D';
const GOLD = 'B8860B';
const BODY = 26; // 13pt
const PAGE = { width: 11906, height: 16838 };
const MARGIN = { top: 1134, bottom: 1134, left: 1701, right: 1134 };
const CONTENT_WIDTH = PAGE.width - MARGIN.left - MARGIN.right;
const CONTENT_PX = 600;
const HEADER_TEXT = 'Khóa luận tốt nghiệp – Hệ thống quản lý khách sạn Luxe Grand Hotel';

const CAPTION_RE = /^\*((?:Hình|Bảng) [\dA-Z]+(?:\.\d+)*[a-z]?:.*)\*$/;

// ---------------------------------------------------------------------------
// Định dạng trong dòng
// ---------------------------------------------------------------------------
function inline(text, base = {}) {
  const out = [];
  const re = /(\*\*[^*]+\*\*|`[^`]+`|\*[^*\s][^*]*\*)/g;
  let last = 0;
  let m;
  const push = (t, extra = {}) => t && out.push(new TextRun({ text: t, font: FONT, size: BODY, ...base, ...extra }));
  while ((m = re.exec(text))) {
    push(text.slice(last, m.index));
    const tok = m[0];
    if (tok.startsWith('**')) push(tok.slice(2, -2), { bold: true });
    else if (tok.startsWith('`')) push(tok.slice(1, -1), { font: MONO, size: (base.size || BODY) - 4, color: '8B1A1A' });
    else push(tok.slice(1, -1), { italics: true });
    last = m.index + tok.length;
  }
  push(text.slice(last));
  return out;
}

// Một đoạn có thể gồm nhiều dòng; dòng kết thúc bằng 2 dấu cách là ngắt dòng cứng
function inlineLines(lines, base) {
  const runs = [];
  lines.forEach((line, i) => {
    const hard = /\s{2,}$/.test(line);
    runs.push(...inline(line.trim(), base));
    if (i < lines.length - 1) runs.push(hard ? new TextRun({ break: 1 }) : new TextRun({ text: ' ', font: FONT, size: BODY }));
  });
  return runs;
}

// ---------------------------------------------------------------------------
// Khối
// ---------------------------------------------------------------------------
let pendingPageBreak = false;
function takeBreak() {
  const b = pendingPageBreak;
  pendingPageBreak = false;
  return b;
}

function paragraph(lines, opts = {}) {
  // Đoạn có ngắt dòng cứng (khối ký tên, thông tin) căn trái để không bị dãn chữ
  const hardBreaks = lines.length > 1 && lines.some((l) => /\s{2,}$/.test(l));
  return new Paragraph({
    alignment: opts.align || (hardBreaks ? AlignmentType.LEFT : AlignmentType.JUSTIFIED),
    pageBreakBefore: takeBreak(),
    spacing: { after: 100, line: 312 },
    indent: opts.noIndent ? undefined : { firstLine: 567 },
    children: inlineLines(lines, opts.run),
  });
}

function heading(level, text) {
  const map = { 1: HeadingLevel.HEADING_1, 2: HeadingLevel.HEADING_2, 3: HeadingLevel.HEADING_3, 4: HeadingLevel.HEADING_4 };
  return new Paragraph({ heading: map[level], pageBreakBefore: takeBreak(), children: inline(text, { size: undefined, font: undefined }) });
}

function frontTitle(text) {
  return new Paragraph({
    alignment: AlignmentType.CENTER,
    pageBreakBefore: takeBreak(),
    spacing: { after: 240 },
    children: [new TextRun({ text, bold: true, font: FONT, size: 30, color: NAVY })],
  });
}

const figureList = [];
const tableList = [];
function caption(text) {
  const isTable = text.startsWith('Bảng');
  return new Paragraph({
    alignment: AlignmentType.CENTER,
    keepNext: isTable,
    spacing: { before: isTable ? 160 : 40, after: isTable ? 80 : 200 },
    children: [new TextRun({ text: text.replace(/`/g, ''), italics: true, bold: true, font: FONT, size: 22, color: '333333' })],
  });
}

function imageSize(file) {
  const buf = fs.readFileSync(file);
  if (buf[0] === 0x89 && buf[1] === 0x50) return { type: 'png', buf, width: buf.readUInt32BE(16), height: buf.readUInt32BE(20) };
  // JPEG: tìm marker SOF
  let i = 2;
  while (i < buf.length) {
    if (buf[i] !== 0xff) break;
    const marker = buf[i + 1];
    const len = buf.readUInt16BE(i + 2);
    if (marker >= 0xc0 && marker <= 0xc3) return { type: 'jpg', buf, height: buf.readUInt16BE(i + 5), width: buf.readUInt16BE(i + 7) };
    i += 2 + len;
  }
  throw new Error(`Không đọc được kích thước ảnh ${file}`);
}

function image(src) {
  const file = path.resolve(BASE_DIR, src);
  const { type, buf, width, height } = imageSize(file);
  let w = CONTENT_PX;
  let h = Math.round((height / width) * w);
  const maxH = 820;
  if (h > maxH) {
    h = maxH;
    w = Math.round((width / height) * h);
  }
  return new Paragraph({
    alignment: AlignmentType.CENTER,
    keepNext: true,
    pageBreakBefore: takeBreak(),
    spacing: { before: 120, after: 40 },
    children: [new ImageRun({ type, data: buf, transformation: { width: w, height: h } })],
  });
}

function codeBlock(lines) {
  const out = lines.map(
    (line, i) =>
      new Paragraph({
        keepNext: i < lines.length - 1 && lines.length < 30,
        shading: { type: ShadingType.CLEAR, color: 'auto', fill: 'F4F6F8' },
        border: { left: { style: BorderStyle.SINGLE, size: 18, color: GOLD, space: 8 } },
        spacing: { after: 0, line: 240 },
        indent: { left: 170 },
        children: [new TextRun({ text: line.length ? line : ' ', font: MONO, size: 17, color: '1F2937' })],
      }),
  );
  out.push(new Paragraph({ spacing: { after: 100 }, children: [] }));
  return out;
}

function quote(lines) {
  const text = lines.map((l) => l.replace(/^>\s?/, '')).filter((l) => !/^[-=]{6,}$/.test(l.trim()));
  const isPlaceholder = text.some((l) => l.includes('📸'));
  const dashed = { style: BorderStyle.DASHED, size: 8, color: '9AA5B1', space: 6 };
  return new Paragraph({
    alignment: isPlaceholder ? AlignmentType.CENTER : AlignmentType.LEFT,
    spacing: { before: 100, after: 100, line: 300 },
    indent: isPlaceholder ? undefined : { left: 567 },
    shading: isPlaceholder ? undefined : { type: ShadingType.CLEAR, color: 'auto', fill: 'F4F6F8' },
    border: isPlaceholder
      ? { top: dashed, bottom: dashed, left: dashed, right: dashed }
      : { left: { style: BorderStyle.SINGLE, size: 18, color: NAVY, space: 8 } },
    children: inlineLines(text.map((l) => l.replace('📸 ', '')), isPlaceholder ? { italics: true, color: '6B7280', size: 22 } : {}),
  });
}

const cellBorders = {
  top: { style: BorderStyle.SINGLE, size: 4, color: '9AA5B1' },
  bottom: { style: BorderStyle.SINGLE, size: 4, color: '9AA5B1' },
  left: { style: BorderStyle.SINGLE, size: 4, color: '9AA5B1' },
  right: { style: BorderStyle.SINGLE, size: 4, color: '9AA5B1' },
};

function splitRow(line) {
  const cells = [];
  let cur = '';
  const s = line.trim().replace(/^\|/, '').replace(/\|$/, '');
  for (let i = 0; i < s.length; i++) {
    if (s[i] === '\\' && s[i + 1] === '|') {
      cur += '|';
      i++;
    } else if (s[i] === '|') {
      cells.push(cur.trim());
      cur = '';
    } else cur += s[i];
  }
  cells.push(cur.trim());
  return cells;
}

function table(lines) {
  const header = splitRow(lines[0]);
  const aligns = splitRow(lines[1]).map((a) => (a.startsWith(':') && a.endsWith(':') ? 'center' : 'left'));
  const rows = lines.slice(2).map(splitRow);
  const n = header.length;
  const size = n >= 6 ? 18 : n >= 5 ? 19 : 21;
  const plain = (t) => t.replace(/[*`]/g, '');
  const colTexts = (i) => [header[i], ...rows.map((r) => r[i] || '')].map(plain);
  // Độ rộng tối thiểu (DXA) đủ chứa từ dài nhất của cột, để 'TC01', 'POST', 'Xác suất' không bị bẻ chữ.
  // Một ký tự cỡ `size` nửa-điểm rộng khoảng size * 5.5 DXA; cộng lề ô hai bên.
  const charW = size * 5.5;
  const minW = Array.from({ length: n }, (_, i) => {
    const longest = Math.max(...colTexts(i).flatMap((t) => t.split(/[\s,/]+/)).map((w) => w.length));
    return Math.min(2600, Math.round(Math.min(longest, 24) * charW + 260));
  });
  // Phần còn lại chia theo độ dài nội dung trung bình của cột
  const weight = Array.from({ length: n }, (_, i) => {
    const lens = colTexts(i).map((t) => t.length);
    return Math.max(1, lens.reduce((a, b) => a + b, 0) / lens.length);
  });
  const minSum = minW.reduce((a, b) => a + b, 0);
  let cols;
  if (minSum >= CONTENT_WIDTH) {
    cols = minW.map((w) => Math.floor((w / minSum) * CONTENT_WIDTH));
  } else {
    const spare = CONTENT_WIDTH - minSum;
    const wSum = weight.reduce((a, b) => a + b, 0);
    cols = minW.map((w, i) => w + Math.floor((weight[i] / wSum) * spare));
  }
  cols[n - 1] += CONTENT_WIDTH - cols.reduce((a, b) => a + b, 0);

  const cell = (text, i, isHeader, fill) =>
    new TableCell({
      width: { size: cols[i], type: WidthType.DXA },
      borders: cellBorders,
      verticalAlign: VerticalAlign.CENTER,
      shading: fill ? { type: ShadingType.CLEAR, color: 'auto', fill } : undefined,
      margins: { top: 50, bottom: 50, left: 90, right: 90 },
      children: [
        new Paragraph({
          alignment: isHeader || aligns[i] === 'center' ? AlignmentType.CENTER : AlignmentType.LEFT,
          spacing: { after: 0, line: 264 },
          children: isHeader
            ? [new TextRun({ text: text.replace(/[*`]/g, ''), bold: true, color: 'FFFFFF', font: FONT, size })]
            : inline(text, { size }),
        }),
      ],
    });

  return [
    new Table({
      width: { size: CONTENT_WIDTH, type: WidthType.DXA },
      columnWidths: cols,
      layout: TableLayoutType.FIXED,
      rows: [
        new TableRow({ tableHeader: true, children: header.map((h, i) => cell(h, i, true, NAVY)) }),
        ...rows.map((r, ri) => new TableRow({ cantSplit: true, children: header.map((_, i) => cell(r[i] || '', i, false, ri % 2 ? 'F7F9FB' : undefined)) })),
      ],
    }),
    new Paragraph({ spacing: { after: 120 }, children: [] }),
  ];
}

// ---------------------------------------------------------------------------
// Trang bìa: phần trước \newpage đầu tiên
// ---------------------------------------------------------------------------
function coverPage(lines) {
  const out = [];
  const line = (text, size, opts = {}) =>
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: opts.before || 0, after: opts.after ?? 100 },
      children: inline(text, { size, bold: opts.bold, color: opts.color }),
    });
  out.push(line('[TÊN TRƯỜNG ĐẠI HỌC]', 28, { bold: true }));
  out.push(line('KHOA CÔNG NGHỆ THÔNG TIN', 28, { bold: true }));
  out.push(line('──────── ✦ ────────', 24, { color: GOLD, after: 500 }));
  let first = true;
  for (const raw of lines) {
    const l = raw.trim();
    if (!l || l === '---') continue;
    if (l.startsWith('# ')) {
      const t = l.slice(2);
      if (t.startsWith('BÁO CÁO')) out.push(line(t, 36, { bold: true, color: NAVY, before: 300 }));
      else if (t === 'ĐỀ TÀI:') out.push(line('Đề tài:', 28, { before: 400 }));
      else out.push(line(t, 30, { bold: true, color: NAVY, after: 500 }));
    } else if (l.startsWith('## ')) {
      out.push(line(l.slice(3), 26, { bold: true }));
    } else {
      out.push(
        new Paragraph({
          indent: { left: 1700 },
          spacing: { before: first ? 400 : 0, after: 80 },
          children: inline(l.replace(/\s+$/, ''), { size: 26 }),
        }),
      );
      first = false;
    }
  }
  out.push(line('Hà Nội, 2026', 26, { bold: true, before: 1200 }));
  return out;
}

// ---------------------------------------------------------------------------
// Phân tích Markdown
// ---------------------------------------------------------------------------
function parse(md) {
  const lines = md.replace(/\r/g, '').split('\n');
  const firstBreak = lines.findIndex((l) => l.trim() === '\\newpage');
  const cover = coverPage(lines.slice(0, firstBreak));
  const body = [];
  let inFront = true; // trước CHƯƠNG 1: tiêu đề cấp 2 là tiêu đề trang không đánh số
  let stepInstance = 0;

  // Danh mục hình/bảng thu thập trước để in ở phần đầu
  for (const l of lines) {
    const m = l.trim().match(CAPTION_RE);
    if (m) (m[1].startsWith('Hình') ? figureList : tableList).push(m[1].replace(/`/g, ''));
  }

  let i = firstBreak;
  while (i < lines.length) {
    const raw = lines[i];
    const l = raw.trim();

    if (l === '\\newpage') {
      pendingPageBreak = true;
      i++;
      continue;
    }
    if (!l || l === '---') {
      i++;
      continue;
    }
    if (l === '<!-- MUC_LUC -->') {
      body.push(new TableOfContents('Mục lục', { hyperlink: true, headingStyleRange: '1-3' }));
      i++;
      continue;
    }
    if (l === '<!-- DANH_MUC_HINH -->' || l === '<!-- DANH_MUC_BANG -->') {
      const list = l.includes('HINH') ? figureList : tableList;
      list.forEach((t) => body.push(paragraph([t], { noIndent: true })));
      i++;
      continue;
    }
    if (l.startsWith('<!--')) {
      i++;
      continue;
    }

    const h = l.match(/^(#{1,4})\s+(.*)$/);
    if (h) {
      const level = h[1].length;
      if (level === 1 && /^CHƯƠNG|^TÀI LIỆU/.test(h[2])) inFront = false;
      if (inFront && level === 2) body.push(frontTitle(h[2]));
      else if (inFront && level === 3) body.push(paragraph([`**${h[2]}**`], { noIndent: true }));
      else body.push(heading(level, h[2]));
      i++;
      continue;
    }

    const cap = l.match(CAPTION_RE);
    if (cap) {
      body.push(caption(cap[1]));
      i++;
      continue;
    }

    const img = l.match(/^!\[[^\]]*\]\(([^)]+)\)$/);
    if (img) {
      body.push(image(img[1]));
      i++;
      continue;
    }

    if (l.startsWith('```')) {
      const block = [];
      i++;
      while (i < lines.length && !lines[i].trim().startsWith('```')) block.push(lines[i++].replace(/\t/g, '  '));
      i++;
      // Khối mã nằm trong danh sách được thụt lề sẵn: bỏ phần thụt chung
      const pad = Math.min(...block.filter((b) => b.trim()).map((b) => b.match(/^ */)[0].length));
      body.push(...codeBlock(block.map((b) => b.slice(Number.isFinite(pad) ? pad : 0))));
      continue;
    }

    if (l.startsWith('|')) {
      const block = [];
      while (i < lines.length && lines[i].trim().startsWith('|')) block.push(lines[i++]);
      body.push(...table(block));
      continue;
    }

    if (l.startsWith('>')) {
      const block = [];
      while (i < lines.length && lines[i].trim().startsWith('>')) block.push(lines[i++].trim());
      body.push(quote(block));
      continue;
    }

    if (/^([-+*]|\d+\.)\s/.test(l)) {
      stepInstance++;
      while (i < lines.length && /^\s*([-+*]|\d+\.)\s/.test(lines[i])) {
        const item = lines[i];
        const indent = item.match(/^ */)[0].length;
        const level = Math.min(2, Math.floor(indent / 2));
        const ordered = /^\s*\d+\.\s/.test(item);
        const text = [item.replace(/^\s*([-+*]|\d+\.)\s+/, '')];
        i++;
        // Dòng tiếp nối của cùng mục (thụt lề, không phải mục mới, không phải khối mã)
        while (i < lines.length && /^\s{2,}\S/.test(lines[i]) && !/^\s*([-+*]|\d+\.)\s/.test(lines[i]) && !lines[i].trim().startsWith('```')) {
          text.push(lines[i++].trim());
        }
        body.push(
          new Paragraph({
            numbering: ordered ? { reference: 'steps', level, instance: stepInstance } : { reference: 'bullets', level },
            alignment: AlignmentType.JUSTIFIED,
            pageBreakBefore: takeBreak(),
            spacing: { after: 60, line: 300 },
            children: inlineLines(text),
          }),
        );
        // Khối mã nằm trong mục danh sách
        if (i < lines.length && lines[i].trim().startsWith('```')) break;
      }
      continue;
    }

    // Đoạn văn: gom các dòng liên tiếp
    const para = [];
    while (i < lines.length) {
      const t = lines[i];
      const tt = t.trim();
      if (!tt || tt === '\\newpage' || /^(#{1,4}\s|\||>|```|!\[|<!--|---$)/.test(tt) || /^([-+*]|\d+\.)\s/.test(tt) || CAPTION_RE.test(tt)) break;
      para.push(t);
      i++;
    }
    body.push(paragraph(para));
  }
  return { cover, body };
}

// ---------------------------------------------------------------------------
async function main() {
  const { cover, body } = parse(fs.readFileSync(INPUT, 'utf8'));
  const headingRun = (size, color, extra = {}) => ({ font: FONT, size, bold: true, color, ...extra });
  const levels = (ref, fmt, texts) => ({
    reference: ref,
    levels: texts.map((text, level) => ({
      level,
      format: fmt,
      text,
      alignment: AlignmentType.LEFT,
      style: { paragraph: { indent: { left: 720 + level * 360, hanging: 360 } } },
    })),
  });

  const doc = new Document({
    creator: 'Luxe Grand Hotel',
    title: 'Khóa luận tốt nghiệp – Hệ thống quản lý khách sạn Luxe Grand Hotel',
    features: { updateFields: true },
    styles: {
      default: { document: { run: { font: FONT, size: BODY } } },
      paragraphStyles: [
        { id: 'Heading1', name: 'Heading 1', basedOn: 'Normal', next: 'Normal', quickFormat: true, run: headingRun(30, NAVY), paragraph: { alignment: AlignmentType.CENTER, spacing: { before: 0, after: 300 }, outlineLevel: 0 } },
        { id: 'Heading2', name: 'Heading 2', basedOn: 'Normal', next: 'Normal', quickFormat: true, run: headingRun(28, NAVY), paragraph: { spacing: { before: 280, after: 120 }, keepNext: true, outlineLevel: 1 } },
        { id: 'Heading3', name: 'Heading 3', basedOn: 'Normal', next: 'Normal', quickFormat: true, run: headingRun(26, '1F2937', { italics: true }), paragraph: { spacing: { before: 200, after: 80 }, keepNext: true, outlineLevel: 2 } },
        { id: 'Heading4', name: 'Heading 4', basedOn: 'Normal', next: 'Normal', quickFormat: true, run: headingRun(26, '374151'), paragraph: { spacing: { before: 160, after: 60 }, keepNext: true, outlineLevel: 3 } },
      ],
    },
    numbering: {
      config: [levels('bullets', LevelFormat.BULLET, ['•', '–', '◦']), levels('steps', LevelFormat.DECIMAL, ['%1.', '%2.', '%3.'])],
    },
    sections: [
      {
        properties: {
          page: {
            size: PAGE,
            margin: MARGIN,
            borders: {
              pageBorderTop: { style: BorderStyle.DOUBLE, size: 6, color: NAVY, space: 24 },
              pageBorderBottom: { style: BorderStyle.DOUBLE, size: 6, color: NAVY, space: 24 },
              pageBorderLeft: { style: BorderStyle.DOUBLE, size: 6, color: NAVY, space: 24 },
              pageBorderRight: { style: BorderStyle.DOUBLE, size: 6, color: NAVY, space: 24 },
            },
          },
        },
        children: cover,
      },
      {
        properties: { page: { size: PAGE, margin: MARGIN, pageNumbers: { start: 1 } } },
        headers: {
          default: new Header({
            children: [
              new Paragraph({
                alignment: AlignmentType.RIGHT,
                border: { bottom: { style: BorderStyle.SINGLE, size: 4, color: 'C0C7D0', space: 4 } },
                children: [new TextRun({ text: HEADER_TEXT, italics: true, size: 18, font: FONT, color: '6B7280' })],
              }),
            ],
          }),
        },
        footers: {
          default: new Footer({
            children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ children: [PageNumber.CURRENT], size: 22, font: FONT })] })],
          }),
        },
        children: body,
      },
    ],
  });

  fs.writeFileSync(OUTPUT, await Packer.toBuffer(doc));
  console.log(`Đã ghi ${OUTPUT} – ${figureList.length} hình, ${tableList.length} bảng`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
