import { NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';

export interface FlutterFileInfo {
  path: string;
  relativePath: string;
  name: string;
  category: 'models' | 'enums' | 'widgets' | 'screens' | 'services' | 'core' | 'other';
  lines: number;
  sizeBytes: number;
  targetPath: string;
}

export async function GET() {
  try {
    // Path to aqarelmasryeen/lib
    const workspaceRoot = path.resolve(process.cwd(), '..');
    const flutterLibDir = path.join(workspaceRoot, 'aqarelmasryeen', 'lib');

    if (!fs.existsSync(flutterLibDir)) {
      return NextResponse.json(
        { error: 'Flutter lib directory not found', searchedPath: flutterLibDir },
        { status: 404 }
      );
    }

    const files: FlutterFileInfo[] = [];

    function scanDir(dir: string) {
      const entries = fs.readdirSync(dir, { withFileTypes: true });

      for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);

        if (entry.isDirectory()) {
          scanDir(fullPath);
        } else if (entry.isFile() && entry.name.endsWith('.dart')) {
          const relativePath = path.relative(flutterLibDir, fullPath);
          const stat = fs.statSync(fullPath);
          const content = fs.readFileSync(fullPath, 'utf-8');
          const lines = content.split('\n').length;

          // Categorize
          let category: FlutterFileInfo['category'] = 'other';
          if (relativePath.includes('enums')) category = 'enums';
          else if (relativePath.includes('models')) category = 'models';
          else if (relativePath.includes('screen')) category = 'screens';
          else if (relativePath.includes('widgets')) category = 'widgets';
          else if (relativePath.includes('data') || relativePath.includes('domain') || relativePath.includes('services')) category = 'services';
          else if (relativePath.includes('core')) category = 'core';

          // Suggest Target Path
          const baseName = entry.name.replace('.dart', '');
          let targetPath = `src/converted/${baseName}.tsx`;
          if (category === 'enums') targetPath = `src/types/${baseName}.ts`;
          else if (category === 'models') targetPath = `src/types/${baseName}.ts`;
          else if (category === 'widgets') targetPath = `src/components/${baseName}.tsx`;
          else if (category === 'screens') targetPath = `src/app/${baseName.replace('_screen', '')}/page.tsx`;
          else if (category === 'services') targetPath = `src/services/${baseName}.ts`;

          files.push({
            path: fullPath,
            relativePath,
            name: entry.name,
            category,
            lines,
            sizeBytes: stat.size,
            targetPath,
          });
        }
      }
    }

    scanDir(flutterLibDir);

    const stats = {
      totalFiles: files.length,
      totalLines: files.reduce((acc, f) => acc + f.lines, 0),
      byCategory: files.reduce((acc, f) => {
        acc[f.category] = (acc[f.category] || 0) + 1;
        return acc;
      }, {} as Record<string, number>),
    };

    return NextResponse.json({ files, stats, flutterLibDir });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
