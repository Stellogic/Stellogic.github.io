/*
  目标：
  1) 在 Hexo Keep 主题下，摘要默认取正文前一部分。为保证摘要清晰，我们在每篇文章首段后插入 <!-- more --> （若不存在）。
  2) 对导入文章里的图片引用进行兜底修复：
     - 若引用的相对图片在同目录存在：保持不变。
     - 若不存在但在 source/_posts/算法笔记/<子类>/ 下能找到同名图片：补齐相对路径。
     - 可选将图片统一搬运到 source/img/<slug>/ 下并重写引用（当前仅兜底不搬家，避免大规模路径变更）。
*/
const fs = require('fs');
const path = require('path');

const WORKSPACE_ROOT = path.resolve(__dirname, '..');
const POSTS_BASE = path.resolve(WORKSPACE_ROOT, 'source', '_posts', '算法笔记');

const MD_GLOB_DIRS = ['基本算法', '数据结构'];

function read(file) { return fs.readFileSync(file, 'utf8'); }
function write(file, content) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, content, 'utf8');
}

function stripMdInline(s) {
  return s
    .replace(/`[^`]*`/g, '')
    .replace(/\*\*([^*]+)\*\*/g, '$1')
    .replace(/\*([^*]+)\*/g, '$1')
    .replace(/\[(.*?)\]\([^)]*\)/g, '$1')
    .replace(/<br\s*\/>/gi, ' ')
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ') // collapse
    .trim();
}

function insertExcerptMarker(md) {
  // 如果已有 more 就不处理
  if (/<!--\s*more\s*-->/.test(md)) return md;
  const lines = md.split(/\r?\n/);
  // 跳过 front-matter
  let i = 0;
  if (lines[0] === '---') {
    i = 1;
    while (i < lines.length && lines[i] !== '---') i++;
    if (i < lines.length) i += 1; // 跳过结束 --- 行
  }
  // 收集首段候选（跳过标题、空行、代码围栏）
  let inFence = false;
  while (i < lines.length) {
    const L = lines[i];
    if (/^\s*```/.test(L)) { inFence = !inFence; i++; continue; }
    if (inFence) { i++; continue; }
    if (/^\s*$/.test(L) || /^\s*#/.test(L)) { i++; continue; }
    break;
  }
  // 找到第一段（直到空行/标题/代码围栏）
  let j = i;
  inFence = false;
  while (j < lines.length) {
    const L = lines[j];
    if (/^\s*```/.test(L)) { break; }
    if (/^\s*$/.test(L) || /^\s*#/.test(L)) break;
    j++;
  }
  const firstPara = lines.slice(i, j).join(' ');
  const summary = stripMdInline(firstPara).slice(0, 180);
  const intro = summary ? `简介：${summary}` : '';
  const header = lines.slice(0, i).join('\n');
  const bodyRest = lines.slice(i).join('\n');
  if (intro) {
    return `${header}\n${intro}\n\n<!-- more -->\n\n${bodyRest}`;
  }
  // fallback：原位插入 more
  const before = lines.slice(0, j).join('\n');
  const after = lines.slice(j).join('\n');
  return `${before}\n\n<!-- more -->\n\n${after}`;
}

function fixImageRefs(mdPath, md) {
  const dir = path.dirname(mdPath);
  // 匹配 Markdown 图片：! [alt](url "title")
  return md.replace(/!\[[^\]]*\]\(([^\)\s]+)(?:\s+"[^"]*")?\)/g, (m, url) => {
    // 绝对或 http 链接不处理
    if (/^https?:\/\//i.test(url) || url.startsWith('/')) return m;
    const candidate = path.resolve(dir, url);
    if (fs.existsSync(candidate)) return m; // 已存在

    // 尝试在同类目录下寻找同名文件
    const baseDir = path.dirname(dir); // e.g., .../_posts/算法笔记/基本算法
    const name = path.basename(url);
    let found = '';
    const entries = fs.readdirSync(baseDir, { withFileTypes: true });
    for (const ent of entries) {
      if (ent.isFile() && ent.name === name) {
        found = path.join(baseDir, ent.name);
        break;
      }
    }
    if (found && fs.existsSync(found)) {
      const rel = path.relative(dir, found).replace(/\\/g, '/');
      return m.replace(url, rel);
    }
    return m;
  });
}

function processOne(file) {
  let md = read(file);
  const orig = md;
  md = insertExcerptMarker(md);
  md = fixImageRefs(file, md);
  if (md !== orig) write(file, md);
}

function walk(dir, cb) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const ent of entries) {
    const full = path.join(dir, ent.name);
    if (ent.isDirectory()) walk(full, cb);
    else if (/\.md$/i.test(ent.name)) cb(full);
  }
}

function main() {
  for (const sub of MD_GLOB_DIRS) {
    const dir = path.join(POSTS_BASE, sub);
    if (!fs.existsSync(dir)) continue;
    walk(dir, processOne);
  }
  console.log('Polish done: inserted <!-- more --> where missing, attempted to fix image references.');
}

main();
