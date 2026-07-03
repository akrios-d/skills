#!/usr/bin/env node
/**
 * generate_triage_docx.js
 * Usage: node generate_triage_docx.js <data.json> <output.docx>
 *
 * data.json schema:
 * {
 *   "title": "Source Triage — Topic",
 *   "subtitle": "Case 1  ·  Case 2",
 *   "base_documents": ["Doc 1 (already owned)", "Doc 2 (already owned)"],
 *   "date": "April 2026",
 *   "sources": [
 *     {
 *       "number": 1,
 *       "title": "Full Title (Year)\n(Publisher)",
 *       "url_label": "domain.com › path-slug",
 *       "url": "https://full-url.com/path",
 *       "classification": "ESSENTIAL",   // ESSENTIAL | COMPLEMENTARY | SECONDARY
 *       "note": "Triage note explaining the gap filled."
 *     }
 *   ],
 *   "reading_order": [
 *     { "number": 1, "description": "Source title — reason" }
 *   ]
 * }
 */

const [,, dataPath, outputPath] = process.argv;
if (!dataPath || !outputPath) {
  console.error('Usage: node generate_triage_docx.js <data.json> <output.docx>');
  process.exit(1);
}

// Try to find docx module in common locations
let docxModule;
const searchPaths = [
  '/tmp/triage-build/node_modules/docx',
  '/tmp/docxbuild/node_modules/docx',
  `${__dirname}/../node_modules/docx`,
  'docx',
];
for (const p of searchPaths) {
  try { docxModule = require(p); break; } catch {}
}
if (!docxModule) {
  console.error('docx module not found. Run: mkdir -p /tmp/triage-build && cd /tmp/triage-build && npm init -y && npm install docx');
  process.exit(1);
}

const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  ExternalHyperlink, HeadingLevel, AlignmentType, BorderStyle, WidthType,
  ShadingType, LevelFormat
} = docxModule;
const fs = require('fs');

const data = JSON.parse(fs.readFileSync(dataPath, 'utf8'));

// ── Colours ──────────────────────────────────────────────────────────────────
const CLS_FILL = { ESSENTIAL: 'C6EFCE', COMPLEMENTARY: 'FFEB9C', SECONDARY: 'DDEEFF' };
const HEADER_FILL = '2E5090';
const border = { style: BorderStyle.SINGLE, size: 1, color: 'CCCCCC' };
const borders = { top: border, bottom: border, left: border, right: border };
const pad = { top: 80, bottom: 80, left: 120, right: 120 };

// ── Helpers ───────────────────────────────────────────────────────────────────
function txt(text, opts = {}) {
  return new TextRun({ text: String(text), font: 'Arial', size: opts.size || 18, ...opts });
}
function para(children, opts = {}) {
  return new Paragraph({ children: Array.isArray(children) ? children : [children], ...opts });
}
function cell(children, width, opts = {}) {
  return new TableCell({
    borders,
    width: { size: width, type: WidthType.DXA },
    margins: pad,
    ...(opts.shading ? { shading: { fill: opts.shading, type: ShadingType.CLEAR } } : {}),
    children: Array.isArray(children) ? children : [para(children)],
  });
}
function hdrCell(text, width) {
  return new TableCell({
    borders,
    shading: { fill: HEADER_FILL, type: ShadingType.CLEAR },
    width: { size: width, type: WidthType.DXA },
    margins: pad,
    children: [para(txt(text, { bold: true, color: 'FFFFFF' }))],
  });
}
function clsCell(label, width) {
  const fill = CLS_FILL[label] || 'FFFFFF';
  return new TableCell({
    borders,
    shading: { fill, type: ShadingType.CLEAR },
    width: { size: width, type: WidthType.DXA },
    margins: pad,
    children: [new Paragraph({
      alignment: AlignmentType.CENTER,
      children: [txt(label, { bold: true, size: 16 })],
    })],
  });
}
function urlCell(label, url, width) {
  return new TableCell({
    borders,
    width: { size: width, type: WidthType.DXA },
    margins: pad,
    children: [para(new ExternalHyperlink({
      link: url,
      children: [txt(label, { size: 16, color: '1155CC', underline: {} })],
    }))],
  });
}

// ── Landscape Letter: content = 15840 - 2*1080 = 13680 DXA ──────────────────
// Columns: # | Source | Link | Classification | Note
const COL = [360, 2700, 3100, 1400, 6120];
const TOTAL = COL.reduce((a, b) => a + b, 0); // 13680

// ── Main triage table ─────────────────────────────────────────────────────────
const tableRows = [
  new TableRow({
    tableHeader: true,
    children: [
      hdrCell('#', COL[0]),
      hdrCell('Source', COL[1]),
      hdrCell('Link', COL[2]),
      hdrCell('Classification', COL[3]),
      hdrCell('Triage Note', COL[4]),
    ],
  }),
  ...data.sources.map(s => new TableRow({
    children: [
      cell(para(txt(String(s.number), { bold: true })), COL[0]),
      cell(para(txt(s.title)), COL[1]),
      urlCell(s.url_label, s.url, COL[2]),
      clsCell(s.classification, COL[3]),
      cell(para(txt(s.note)), COL[4]),
    ],
  })),
];

// ── Legend table ──────────────────────────────────────────────────────────────
const legendData = [
  ['ESSENTIAL',     'Fills a critical gap not covered by any base document. Must read.',                   'C6EFCE'],
  ['COMPLEMENTARY', 'Adds depth or extends coverage beyond the base documents. Read after ESSENTIALs.',  'FFEB9C'],
  ['SECONDARY',     'Comparative or tangential context. Only if broadening the dissertation scope.',       'DDEEFF'],
];
const legendRows = legendData.map(([label, desc, fill]) => new TableRow({
  children: [
    new TableCell({
      borders, shading: { fill, type: ShadingType.CLEAR },
      width: { size: 1700, type: WidthType.DXA }, margins: { top: 60, bottom: 60, left: 120, right: 120 },
      children: [para(txt(label, { bold: true }))],
    }),
    new TableCell({
      borders,
      width: { size: 8000, type: WidthType.DXA }, margins: { top: 60, bottom: 60, left: 120, right: 120 },
      children: [para(txt(desc))],
    }),
  ],
}));

// ── Document ──────────────────────────────────────────────────────────────────
const doc = new Document({
  styles: {
    default: { document: { run: { font: 'Arial', size: 22 } } },
    paragraphStyles: [
      { id: 'Heading1', name: 'Heading 1', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 40, bold: true, font: 'Arial', color: HEADER_FILL },
        paragraph: { spacing: { before: 280, after: 160 }, outlineLevel: 0 } },
      { id: 'Heading2', name: 'Heading 2', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 26, bold: true, font: 'Arial', color: HEADER_FILL },
        paragraph: { spacing: { before: 200, after: 120 }, outlineLevel: 1 } },
    ],
  },
  numbering: {
    config: [{
      reference: 'numbers',
      levels: [{ level: 0, format: LevelFormat.DECIMAL, text: '%1.', alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } } }],
    }],
  },
  sections: [{
    properties: {
      page: { size: { width: 15840, height: 12240 }, margin: { top: 1080, right: 1080, bottom: 1080, left: 1080 } },
    },
    children: [
      // ── Title block
      new Paragraph({ heading: HeadingLevel.HEADING_1, children: [txt(data.title, { size: 40, bold: true, color: HEADER_FILL })] }),
      para(txt(data.subtitle, { size: 24, italics: true, color: '555555' })),
      para(txt(
        `Prepared: ${data.date}   |   Base documents already in hand: ${data.base_documents.join('   |   ')}`,
        { size: 18, color: '777777' }
      ), { spacing: { after: 160 } }),

      // ── Key
      new Paragraph({ heading: HeadingLevel.HEADING_2, children: [txt('Key', { size: 26, bold: true, color: HEADER_FILL })] }),
      new Table({ width: { size: 9700, type: WidthType.DXA }, columnWidths: [1700, 8000], rows: legendRows }),

      para(txt(''), { spacing: { before: 240, after: 80 } }),

      // ── Triage table
      new Paragraph({ heading: HeadingLevel.HEADING_2, children: [txt('Source Triage', { size: 26, bold: true, color: HEADER_FILL })] }),
      new Table({ width: { size: TOTAL, type: WidthType.DXA }, columnWidths: COL, rows: tableRows }),

      para(txt(''), { spacing: { before: 320, after: 80 } }),

      // ── Reading order
      new Paragraph({ heading: HeadingLevel.HEADING_2, children: [txt('Suggested Reading Order (ESSENTIAL sources only)', { size: 26, bold: true, color: HEADER_FILL })] }),
      para(txt('Read in this sequence — theory first, then evidence:', { size: 20, italics: true, color: '444444' }), { spacing: { after: 100 } }),
      ...data.reading_order.map(item => new Paragraph({
        numbering: { reference: 'numbers', level: 0 },
        children: [txt(`[${item.number}]  ${item.description}`, { size: 20 })],
      })),

      // ── Footer note
      para(txt(
        `After the essential sources, add COMPLEMENTARY sources as supporting evidence. SECONDARY sources are optional.`,
        { size: 18, italics: true, color: '666666' }
      ), { spacing: { before: 200, after: 80 } }),
    ],
  }],
});

Packer.toBuffer(doc).then(buf => {
  fs.writeFileSync(outputPath, buf);
  console.log(`✓ Written ${buf.length} bytes → ${outputPath}`);
});
