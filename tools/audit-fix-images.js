/*
  扫描算法笔记文章中的图片引用，检查目标文件是否存在；
  若不存在，尝试在同级目录或兄弟目录中查找同名文件并重写为相对路径；
  打印无法修复的清单，便于人工处理。
*/
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const BASE = path.resolve(ROOT, 'source', '_posts', '算法笔记');
const SUBS = ['基本算法', '数据结构'];

function read(p) { return fs.readFileSync(p, 'utf8'); }
function write(p, s) { fs.writeFileSync(p, s, 'utf8'); }

function walk(dir, cb) {
  const ents = fs.readdirSync(dir, { withFileTypes: true });
  for (const e of ents) {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) walk(full, cb);
    else if (/\.md$/i.test(e.name)) cb(full);
  }
}

function findSiblingByName(baseDir, name) {
  const dirs = fs.readdirSync(baseDir, { withFileTypes: true });
  for (const d of dirs) {
    if (!d.isDirectory()) continue;
    const maybe = path.join(baseDir, d.name, name);
    if (fs.existsSync(maybe)) return maybe;
  }
  return '';
}

function process(file) {
  let content = read(file);
  const dir = path.dirname(file);
  let changed = false;
  const missing = [];
  content = content.replace(/!\[[^\]]*\]\(([^\)\s]+)(?:\s+"[^"]*")?\)/g, (m, url) => {
    if (/^https?:\/\//i.test(url) || url.startsWith('/')) return m;
    const abs = path.resolve(dir, url);
    if (fs.existsSync(abs)) return m;
    const name = path.basename(url);
    // 在当前文章的上一级目录内尝试寻找兄弟目录同名
    const maybe = findSiblingByName(path.dirname(dir), name);
    if (maybe) {
      const rel = path.relative(dir, maybe).replace(/\\/g, '/');
      changed = true;
      return m.replace(url, rel);
    }
    missing.push(url);
    return m;
  });
  if (changed) write(file, content);
  if (missing.length) {
    console.warn(`[缺失图片] ${file}`);
    missing.forEach(u => console.warn(`  - ${u}`));
  }
}

function main() {
  for (const s of SUBS) {
    const dir = path.join(BASE, s);
    if (!fs.existsSync(dir)) continue;
    walk(dir, process);
  }
  console.log('Audit images done. 请查看上方 [缺失图片] 日志条目。');
}

main();
