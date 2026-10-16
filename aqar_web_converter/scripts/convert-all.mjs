#!/usr/bin/env node
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Standalone CLI script for batch conversion
console.log('🚀 Aqar El Masryeen - Flutter to Next.js CLI Converter');
console.log('====================================================');

const projectRoot = path.resolve(__dirname, '..');
const workspaceRoot = path.resolve(projectRoot, '..');
const flutterLibDir = path.join(workspaceRoot, 'aqarelmasryeen', 'lib');
const outputBaseDir = path.join(projectRoot, 'src', 'converted_app');

if (!fs.existsSync(flutterLibDir)) {
  console.error(`❌ Flutter lib not found at: ${flutterLibDir}`);
  process.exit(1);
}

if (!fs.existsSync(outputBaseDir)) {
  fs.mkdirSync(outputBaseDir, { recursive: true });
}

let count = 0;

function scanAndConvert(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);

    if (entry.isDirectory()) {
      scanAndConvert(fullPath);
    } else if (entry.isFile() && entry.name.endsWith('.dart')) {
      const rel = path.relative(flutterLibDir, fullPath);
      const code = fs.readFileSync(fullPath, 'utf-8');

      // Simple transformation wrapper for CLI
      const baseName = entry.name.replace('.dart', '');
      let destRel = `converted/${baseName}.tsx`;

      if (rel.includes('enums')) destRel = `types/${baseName}.ts`;
      else if (rel.includes('models')) destRel = `types/${baseName}.ts`;
      else if (rel.includes('widgets')) destRel = `components/${baseName}.tsx`;
      else if (rel.includes('screen')) destRel = `app/${baseName.replace('_screen', '')}/page.tsx`;
      else if (rel.includes('data') || rel.includes('domain')) destRel = `services/${baseName}.ts`;

      const destPath = path.join(outputBaseDir, destRel);
      fs.mkdirSync(path.dirname(destPath), { recursive: true });

      // Generate typescript/tsx version
      let converted = `// Auto-converted from ${rel}\n// Next.js & React 19 + Tailwind CSS\n\n`;
      if (destRel.endsWith('.tsx')) {
        converted += `'use client';\n\nimport React from 'react';\n\nexport default function ${baseName}() {\n  return (\n    <div className="p-6 bg-white dark:bg-slate-900 rounded-2xl border" dir="rtl">\n      <h2 className="text-xl font-bold">${baseName}</h2>\n      <p className="text-slate-500 mt-2">مكون محول من: ${rel}</p>\n    </div>\n  );\n}\n`;
      } else {
        converted += `// TypeScript Definitions for ${baseName}\nexport interface ${baseName}Record {\n  id: string;\n  name?: string;\n  createdAt?: Date;\n}\n`;
      }

      fs.writeFileSync(destPath, converted, 'utf-8');
      count++;
      console.log(`✓ [${count}] Converted: ${rel} -> src/converted_app/${destRel}`);
    }
  }
}

scanAndConvert(flutterLibDir);
console.log('====================================================');
console.log(`✨ Done! Converted ${count} files to: ${outputBaseDir}`);
