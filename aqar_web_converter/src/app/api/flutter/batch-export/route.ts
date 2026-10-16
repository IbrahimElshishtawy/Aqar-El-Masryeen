import { NextRequest, NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';
import { transpileDartToNextJs } from '@/lib/transpiler';

export async function POST(req: NextRequest) {
  try {
    const workspaceRoot = path.resolve(process.cwd(), '..');
    const flutterLibDir = path.join(workspaceRoot, 'aqarelmasryeen', 'lib');
    const outputBaseDir = path.join(process.cwd(), 'src', 'converted_app');

    if (!fs.existsSync(flutterLibDir)) {
      return NextResponse.json({ error: 'Flutter lib directory not found' }, { status: 404 });
    }

    if (!fs.existsSync(outputBaseDir)) {
      fs.mkdirSync(outputBaseDir, { recursive: true });
    }

    const convertedSummary: { source: string; target: string; status: string }[] = [];

    function processDir(dir: string) {
      const entries = fs.readdirSync(dir, { withFileTypes: true });

      for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);

        if (entry.isDirectory()) {
          processDir(fullPath);
        } else if (entry.isFile() && entry.name.endsWith('.dart')) {
          const relativePath = path.relative(flutterLibDir, fullPath);
          const dartCode = fs.readFileSync(fullPath, 'utf-8');

          const result = transpileDartToNextJs(dartCode, fullPath);

          // Write to converted_app
          const cleanTargetPath = result.targetPath.replace(/^src\//, '');
          const destPath = path.join(outputBaseDir, cleanTargetPath);
          const destDir = path.dirname(destPath);

          if (!fs.existsSync(destDir)) {
            fs.mkdirSync(destDir, { recursive: true });
          }

          fs.writeFileSync(destPath, result.convertedCode, 'utf-8');

          convertedSummary.push({
            source: relativePath,
            target: path.join('src/converted_app', cleanTargetPath),
            status: 'success',
          });
        }
      }
    }

    processDir(flutterLibDir);

    return NextResponse.json({
      success: true,
      message: `تم تحويل ${convertedSummary.length} ملف بنجاح وحفظها في مجلد src/converted_app`,
      totalConverted: convertedSummary.length,
      outputDirectory: outputBaseDir,
      files: convertedSummary,
    });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
