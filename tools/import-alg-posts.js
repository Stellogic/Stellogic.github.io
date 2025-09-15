/*
  将 “基本算法md文件” 子模块中的 Markdown 和相关图片拷贝到 Hexo 的 source/_posts/算法笔记 下。
  - 仅拷贝 .md 与常见图片格式（.png/.jpg/.jpeg/.gif/.svg/.webp）
  - 排除 .java 文件及子模块根 README.md
  - 若缺失 Front-matter（或缺 title/date/categories/tags），则补齐：
      title: 文件名（去扩展名）
      date: 源文件 mtime（本地时区 YYYY-MM-DD HH:mm:ss）
      categories: [<顶级目录名>]
      tags: 若缺失则使用 [<顶级目录名>, 学习笔记]
  - 保持原相对引用图片可用：将图片复制到与文章所在的同级目录中
*/
const fs = require('fs');
const path = require('path');

const WORKSPACE_ROOT = path.resolve(__dirname, '..');
const SRC_BASE = path.resolve(WORKSPACE_ROOT, '基本算法md文件');
// 按需导入：排除 leetcode 刷题笔记
const SRC_SUBDIRS = ['基本算法', '数据结构'];
const DEST_BASE = path.resolve(WORKSPACE_ROOT, 'source', '_posts', '算法笔记');

const IMG_EXTS = new Set(['.png', '.jpg', '.jpeg', '.gif', '.svg', '.webp']);

function formatDateLocal(dt) {
  // 输出 YYYY-MM-DD HH:mm:ss（本地时区）
  const pad = (n) => (n < 10 ? '0' + n : '' + n);
  const y = dt.getFullYear();
  const m = pad(dt.getMonth() + 1);
  const d = pad(dt.getDate());
  const hh = pad(dt.getHours());
  const mm = pad(dt.getMinutes());
  const ss = pad(dt.getSeconds());
  return `${y}-${m}-${d} ${hh}:${mm}:${ss}`;
}

function ensureDirSync(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function readText(file) {
  return fs.readFileSync(file, 'utf8');
}

function writeText(file, content) {
  ensureDirSync(path.dirname(file));
  fs.writeFileSync(file, content, 'utf8');
}

function copyBinary(src, dest) {
  ensureDirSync(path.dirname(dest));
  fs.copyFileSync(src, dest);
}

function hasKeyInYaml(yamlBlock, key) {
  const re = new RegExp(`^${key}\s*:`, 'm');
  return re.test(yamlBlock);
}

function buildYamlLines(meta) {
  const lines = [];
  lines.push('---');
  lines.push(`title: ${meta.title}`);
  lines.push(`date: ${meta.date}`);
  lines.push('categories:');
  lines.push(`  - ${meta.category}`);
  if (meta.tags && meta.tags.length) {
    lines.push('tags:');
    meta.tags.forEach((t) => lines.push(`  - ${t}`));
  }
  lines.push('---');
  return lines.join('\n');
}

function ensureFrontMatter(content, meta) {
  // 返回补齐后的文本
  if (content.startsWith('---')) {
    const endIdx = content.indexOf('\n---', 3);
    if (endIdx !== -1) {
      const headEnd = endIdx + '\n---'.length; // 指向第二个 --- 的末尾
      const header = content.slice(0, headEnd);
      const body = content.slice(headEnd);

      let updatedHeader = header;
      const toAdd = [];
      if (!hasKeyInYaml(header, 'title')) toAdd.push(`title: ${meta.title}`);
      if (!hasKeyInYaml(header, 'date')) toAdd.push(`date: ${meta.date}`);
      if (!hasKeyInYaml(header, 'categories')) {
        toAdd.push('categories:');
        toAdd.push(`  - ${meta.category}`);
      }
      if (!hasKeyInYaml(header, 'tags')) {
        toAdd.push('tags:');
        (meta.tags || []).forEach((t) => toAdd.push(`  - ${t}`));
      }
      if (toAdd.length > 0) {
        // 在结束 --- 之前插入
        const insertPos = header.lastIndexOf('\n---');
        updatedHeader = header.slice(0, insertPos) + '\n' + toAdd.join('\n') + header.slice(insertPos);
      }
      return updatedHeader + body;
    }
  }
  // 无 Front-matter，则新增
  const yaml = buildYamlLines(meta);
  return yaml + '\n\n' + content;
}

function walkDirRecursive(dir, visitor) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const ent of entries) {
    const full = path.join(dir, ent.name);
    if (ent.isDirectory()) {
      walkDirRecursive(full, visitor);
    } else {
      visitor(full);
    }
  }
}

function importOneFolder(srcSubdirName) {
  const srcDir = path.join(SRC_BASE, srcSubdirName);
  const destDir = path.join(DEST_BASE, srcSubdirName);
  if (!fs.existsSync(srcDir)) {
    console.warn(`[跳过] 源目录不存在: ${srcDir}`);
    return { md: 0, assets: 0 };
  }
  let mdCount = 0;
  let assetCount = 0;
  walkDirRecursive(srcDir, (file) => {
    const rel = path.relative(srcDir, file);
    // 跳过隐藏文件夹内的内容
    if (rel.startsWith('.git')) return;

    const ext = path.extname(file).toLowerCase();
    const base = path.basename(file);

    // 排除根 README.md（仅限于子模块的根，不是每个子目录）
    const isRootReadme = file === path.join(SRC_BASE, 'README.md');
    if (isRootReadme) return;

    // 排除 .java
    if (ext === '.java') return;

    // 目标路径：保持在对应子目录下，确保图片与 md 相对路径不变
    const target = path.join(destDir, rel);

    if (ext === '.md') {
      try {
        const stat = fs.statSync(file);
        const mtime = stat.mtime; // 本地时间
        const content = readText(file);
        const title = path.basename(file, '.md');
        const meta = {
          title,
          date: formatDateLocal(mtime),
          category: srcSubdirName,
          tags: [srcSubdirName, '学习笔记'],
        };
        const newContent = ensureFrontMatter(content, meta);
        writeText(target, newContent);
        mdCount++;
      } catch (e) {
        console.error(`[失败] 处理 Markdown: ${file}`, e);
      }
    } else if (IMG_EXTS.has(ext)) {
      try {
        copyBinary(file, target);
        assetCount++;
      } catch (e) {
        console.error(`[失败] 复制图片: ${file}`, e);
      }
    } else {
      // 其他文件全部忽略（例如 .DS_Store、代码文件等）
    }
  });
  return { md: mdCount, assets: assetCount };
}

function main() {
  console.log('开始导入基本算法相关 Markdown ...');
  ensureDirSync(DEST_BASE);
  let totalMd = 0;
  let totalAssets = 0;
  for (const sub of SRC_SUBDIRS) {
    const { md, assets } = importOneFolder(sub);
    totalMd += md;
    totalAssets += assets;
    console.log(`  [${sub}] -> 文章 ${md} 篇，图片 ${assets} 个`);
  }
  console.log(`完成导入，共 ${totalMd} 篇文章，${totalAssets} 个图片资源。`);
  console.log(`目标目录：${DEST_BASE}`);
}

main();
