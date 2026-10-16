import { NextRequest, NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';
import { transpileDartToNextJs } from '@/lib/transpiler';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { filePath, code } = body;

    let dartCode = code;
    let actualPath = filePath || 'custom_snippet.dart';

    if (!dartCode && filePath) {
      // Read from disk
      let targetFile = filePath;
      if (!path.isAbsolute(targetFile)) {
        const workspaceRoot = path.resolve(process.cwd(), '..');
        targetFile = path.join(workspaceRoot, 'aqarelmasryeen', 'lib', filePath);
      }

      if (!fs.existsSync(targetFile)) {
        return NextResponse.json({ error: `File not found: ${targetFile}` }, { status: 404 });
      }

      dartCode = fs.readFileSync(targetFile, 'utf-8');
      actualPath = targetFile;
    }

    if (!dartCode) {
      return NextResponse.json({ error: 'No code or filePath provided' }, { status: 400 });
    }

    const result = transpileDartToNextJs(dartCode, actualPath);

    return NextResponse.json(result);
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
