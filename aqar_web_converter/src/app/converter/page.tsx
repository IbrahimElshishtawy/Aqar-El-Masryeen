'use client';

import React, { useState, useEffect } from 'react';
import {
  FolderCode,
  FileCode,
  Play,
  Copy,
  Check,
  Download,
  Layers,
  Sparkles,
  ArrowRightLeft,
  Search,
  Eye,
  RefreshCw,
  Code2,
  CheckCircle2,
  FileCheck2,
  ExternalLink,
  Flame,
  LayoutDashboard,
  Building2,
  DollarSign,
  TrendingUp,
  Receipt,
  Users,
  Calendar,
  AlertCircle
} from 'lucide-react';

interface FileInfo {
  path: string;
  relativePath: string;
  name: string;
  category: 'models' | 'enums' | 'widgets' | 'screens' | 'services' | 'core' | 'other';
  lines: number;
  sizeBytes: number;
  targetPath: string;
}

interface FileStats {
  totalFiles: number;
  totalLines: number;
  byCategory: Record<string, number>;
}

interface TranspileResponse {
  originalCode: string;
  convertedCode: string;
  targetPath: string;
  fileType: string;
  stats: {
    originalLines: number;
    convertedLines: number;
    componentsFound: string[];
    modelsFound: string[];
    enumsFound: string[];
  };
}

export default function ConverterStudioPage() {
  const [files, setFiles] = useState<FileInfo[]>([]);
  const [stats, setStats] = useState<FileStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [activeFile, setActiveFile] = useState<FileInfo | null>(null);

  // Conversion State
  const [converting, setConverting] = useState(false);
  const [transpileResult, setTranspileResult] = useState<TranspileResponse | null>(null);
  const [activeTab, setActiveTab] = useState<'editor' | 'preview' | 'playground' | 'export'>('editor');

  // Playground snippet
  const [customDartCode, setCustomDartCode] = useState(`class CustomMetricCard extends StatelessWidget {
  const CustomMetricCard({
    super.key,
    required this.title,
    required this.amount,
  });

  final String title;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('\${amount} ج.م', style: const TextStyle(fontSize: 22, color: Colors.blue)),
        ],
      ),
    );
  }
}`);
  const [playgroundResult, setPlaygroundResult] = useState<string>('');
  const [copiedDart, setCopiedDart] = useState(false);
  const [copiedNext, setCopiedNext] = useState(false);
  const [batchProgress, setBatchProgress] = useState<{ running: boolean; message: string; count: number } | null>(null);

  // Fetch file list on mount
  useEffect(() => {
    fetchFiles();
  }, []);

  async function fetchFiles() {
    setLoading(true);
    try {
      const res = await fetch('/api/flutter/files');
      const data = await res.json();
      if (data.files) {
        setFiles(data.files);
        setStats(data.stats);
        if (data.files.length > 0) {
          // Select metric_card or first widget/screen by default
          const defaultFile = data.files.find((f: FileInfo) => f.name.includes('metric_card')) || data.files[0];
          loadFileConversion(defaultFile);
        }
      }
    } catch (err) {
      console.error('Error fetching files:', err);
    } finally {
      setLoading(false);
    }
  }

  async function loadFileConversion(file: FileInfo) {
    setActiveFile(file);
    setConverting(true);
    try {
      const res = await fetch('/api/flutter/convert', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ filePath: file.path }),
      });
      const data = await res.json();
      setTranspileResult(data);
    } catch (err) {
      console.error('Error transpiling file:', err);
    } finally {
      setConverting(false);
    }
  }

  async function handlePlaygroundConvert() {
    setConverting(true);
    try {
      const res = await fetch('/api/flutter/convert', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ code: customDartCode, filePath: 'PlaygroundWidget.dart' }),
      });
      const data = await res.json();
      setPlaygroundResult(data.convertedCode);
    } catch (err) {
      console.error('Error in playground conversion:', err);
    } finally {
      setConverting(false);
    }
  }

  async function handleBatchExport() {
    setBatchProgress({ running: true, message: 'جاري تحويل جميع ملفات lib وتصديرها...', count: 0 });
    try {
      const res = await fetch('/api/flutter/batch-export', { method: 'POST' });
      const data = await res.json();
      if (data.success) {
        setBatchProgress({ running: false, message: data.message, count: data.totalConverted });
      } else {
        setBatchProgress({ running: false, message: 'حدث خطأ أثناء التصدير', count: 0 });
      }
    } catch (err) {
      setBatchProgress({ running: false, message: 'فشل الاتصال بالخادم', count: 0 });
    }
  }

  const filteredFiles = files.filter(f => {
    const matchesSearch = f.relativePath.toLowerCase().includes(searchQuery.toLowerCase()) ||
                          f.name.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCategory = selectedCategory === 'all' || f.category === selectedCategory;
    return matchesSearch && matchesCategory;
  });

  const copyToClipboard = (text: string, isDart: boolean) => {
    navigator.clipboard.writeText(text);
    if (isDart) {
      setCopiedDart(true);
      setTimeout(() => setCopiedDart(false), 2000);
    } else {
      setCopiedNext(true);
      setTimeout(() => setCopiedNext(false), 2000);
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col font-sans" dir="rtl">
      {/* Top Navbar */}
      <header className="h-18 border-b border-slate-800 bg-slate-900/90 backdrop-blur-md px-6 flex items-center justify-between sticky top-0 z-50">
        <div className="flex items-center gap-3">
          <div className="w-11 h-11 rounded-2xl bg-gradient-to-tr from-blue-600 via-indigo-600 to-sky-400 flex items-center justify-center text-white shadow-lg shadow-blue-500/20">
            <ArrowRightLeft className="w-6 h-6" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-lg md:text-xl font-black tracking-tight text-white">
                عقار المصريين <span className="text-blue-400 font-medium text-sm">| استوديو تحويل Flutter إلى Next.js</span>
              </h1>
              <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                جاهز للعمل
              </span>
            </div>
            <p className="text-xs text-slate-400">
              قراءة أكواد Dart من <code className="bg-slate-800 px-1 py-0.5 rounded text-blue-300">aqarelmasryeen/lib</code> وتحويلها آلياً إلى TypeScript + Next.js App Router
            </p>
          </div>
        </div>

        {/* Global Action Buttons */}
        <div className="flex items-center gap-3">
          <button
            onClick={fetchFiles}
            className="p-2.5 rounded-xl border border-slate-800 hover:bg-slate-800/80 text-slate-300 transition text-xs flex items-center gap-1.5"
            title="تحديث فحص الملفات"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
            <span className="hidden sm:inline">تحديث</span>
          </button>

          <button
            onClick={handleBatchExport}
            className="px-4 py-2.5 rounded-xl bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 text-white font-bold text-xs flex items-center gap-2 shadow-lg shadow-blue-600/25 transition active:scale-95"
          >
            <Sparkles className="w-4 h-4" />
            <span>تحويل وتصدير كل الملفات</span>
          </button>
        </div>
      </header>

      {/* Stats Bar */}
      {stats && (
        <div className="bg-slate-900/60 border-b border-slate-800/80 px-6 py-2.5 flex items-center justify-between text-xs overflow-x-auto gap-6 scrollbar-none">
          <div className="flex items-center gap-6">
            <span className="flex items-center gap-1.5 text-slate-400">
              <FolderCode className="w-3.5 h-3.5 text-blue-400" />
              إجمالي الملفات: <strong className="text-slate-100 font-bold">{stats.totalFiles} ملف</strong>
            </span>
            <span className="flex items-center gap-1.5 text-slate-400">
              <Code2 className="w-3.5 h-3.5 text-emerald-400" />
              إجمالي الأسطر: <strong className="text-slate-100 font-bold">{stats.totalLines.toLocaleString()} سطر Dart</strong>
            </span>
            <span className="flex items-center gap-1.5 text-slate-400">
              <LayoutDashboard className="w-3.5 h-3.5 text-amber-400" />
              الشاشات: <strong className="text-slate-100">{stats.byCategory.screens || 0}</strong>
            </span>
            <span className="flex items-center gap-1.5 text-slate-400">
              <Layers className="w-3.5 h-3.5 text-purple-400" />
              المكونات: <strong className="text-slate-100">{stats.byCategory.widgets || 0}</strong>
            </span>
            <span className="flex items-center gap-1.5 text-slate-400">
              <FileCheck2 className="w-3.5 h-3.5 text-pink-400" />
              النماذج (Models): <strong className="text-slate-100">{stats.byCategory.models || 0}</strong>
            </span>
          </div>

          <div className="text-slate-400 flex items-center gap-2">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
            <span>المسار المتصل: <span className="font-mono text-slate-300">../aqarelmasryeen/lib</span></span>
          </div>
        </div>
      )}

      {/* Main Container */}
      <div className="flex-1 flex overflow-hidden">
        {/* Left Sidebar: File Explorer */}
        <aside className="w-80 border-l border-slate-800 bg-slate-900/40 flex flex-col shrink-0">
          {/* Search & Filter Header */}
          <div className="p-4 border-b border-slate-800 space-y-3">
            <div className="relative">
              <Search className="w-4 h-4 text-slate-500 absolute right-3 top-3" />
              <input
                type="text"
                placeholder="بحث في ملفات lib..."
                value={searchQuery}
                onChange={e => setSearchQuery(e.target.value)}
                className="w-full pl-3 pr-9 py-2 bg-slate-800/80 border border-slate-700/80 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-blue-500 transition"
              />
            </div>

            {/* Category Filter Pills */}
            <div className="flex items-center gap-1 overflow-x-auto pb-1 scrollbar-none text-[11px]">
              {[
                { id: 'all', label: 'الكل' },
                { id: 'widgets', label: 'مكونات' },
                { id: 'screens', label: 'شاشات' },
                { id: 'models', label: 'نماذج' },
                { id: 'enums', label: 'Enums' },
                { id: 'services', label: 'خدمات' },
              ].map(cat => (
                <button
                  key={cat.id}
                  onClick={() => setSelectedCategory(cat.id)}
                  className={`px-2.5 py-1 rounded-lg shrink-0 transition font-medium ${
                    selectedCategory === cat.id
                      ? 'bg-blue-600 text-white font-bold'
                      : 'bg-slate-800 text-slate-400 hover:text-slate-200'
                  }`}
                >
                  {cat.label}
                </button>
              ))}
            </div>
          </div>

          {/* Files List */}
          <div className="flex-1 overflow-y-auto divide-y divide-slate-800/40 p-2 space-y-1">
            {loading ? (
              <div className="p-8 text-center text-slate-500 text-xs">
                <RefreshCw className="w-5 h-5 mx-auto mb-2 animate-spin text-blue-500" />
                جاري فحص مجلد lib...
              </div>
            ) : filteredFiles.length === 0 ? (
              <div className="p-8 text-center text-slate-500 text-xs">
                لا توجد ملفات تطابق البحث
              </div>
            ) : (
              filteredFiles.map(file => {
                const isSelected = activeFile?.path === file.path;
                return (
                  <button
                    key={file.path}
                    onClick={() => loadFileConversion(file)}
                    className={`w-full text-right p-3 rounded-xl transition flex flex-col gap-1 ${
                      isSelected
                        ? 'bg-blue-600/15 border border-blue-500/40 text-blue-400 shadow-sm'
                        : 'hover:bg-slate-800/60 text-slate-300 border border-transparent'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2 truncate">
                        <FileCode className={`w-4 h-4 shrink-0 ${isSelected ? 'text-blue-400' : 'text-slate-500'}`} />
                        <span className="font-mono text-xs font-semibold truncate">{file.name}</span>
                      </div>
                      <span className="text-[10px] px-1.5 py-0.5 rounded bg-slate-800 text-slate-400">
                        {file.lines} سطر
                      </span>
                    </div>
                    <div className="text-[11px] text-slate-500 truncate font-mono mr-6">
                      {file.relativePath}
                    </div>
                  </button>
                );
              })
            )}
          </div>
        </aside>

        {/* Right Section: Workspace / Tabs */}
        <div className="flex-1 flex flex-col bg-slate-950 overflow-hidden">
          {/* Mode Switcher Tabs */}
          <div className="h-13 border-b border-slate-800 px-6 flex items-center justify-between bg-slate-900/30">
            <div className="flex items-center gap-2">
              <button
                onClick={() => setActiveTab('editor')}
                className={`px-4 py-2 rounded-xl text-xs font-bold transition flex items-center gap-2 ${
                  activeTab === 'editor'
                    ? 'bg-slate-800 text-white shadow-sm border border-slate-700'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                <ArrowRightLeft className="w-3.5 h-3.5 text-blue-400" />
                <span>المحرر الثنائي (Side-by-Side)</span>
              </button>

              <button
                onClick={() => setActiveTab('preview')}
                className={`px-4 py-2 rounded-xl text-xs font-bold transition flex items-center gap-2 ${
                  activeTab === 'preview'
                    ? 'bg-slate-800 text-white shadow-sm border border-slate-700'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                <Eye className="w-3.5 h-3.5 text-emerald-400" />
                <span>معاينة حية للمكونات (Live Preview)</span>
              </button>

              <button
                onClick={() => setActiveTab('playground')}
                className={`px-4 py-2 rounded-xl text-xs font-bold transition flex items-center gap-2 ${
                  activeTab === 'playground'
                    ? 'bg-slate-800 text-white shadow-sm border border-slate-700'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                <Play className="w-3.5 h-3.5 text-amber-400" />
                <span>محول الأكواد المباشر (Playground)</span>
              </button>

              <button
                onClick={() => setActiveTab('export')}
                className={`px-4 py-2 rounded-xl text-xs font-bold transition flex items-center gap-2 ${
                  activeTab === 'export'
                    ? 'bg-slate-800 text-white shadow-sm border border-slate-700'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                <Download className="w-3.5 h-3.5 text-purple-400" />
                <span>حزمة Next.js المصدرة</span>
              </button>
            </div>

            {/* Target Path Info */}
            {activeFile && (
              <div className="hidden lg:flex items-center gap-2 text-xs text-slate-400 font-mono">
                <span className="text-slate-500">المسار الناتج في Next.js:</span>
                <span className="px-2 py-1 rounded bg-slate-800 text-emerald-400 border border-slate-700/60">
                  {transpileResult?.targetPath || activeFile.targetPath}
                </span>
              </div>
            )}
          </div>

          {/* TAB 1: DUAL EDITOR VIEW */}
          {activeTab === 'editor' && (
            <div className="flex-1 grid grid-cols-1 lg:grid-cols-2 divide-y lg:divide-y-0 lg:divide-x lg:divide-x-reverse divide-slate-800 overflow-hidden">
              {/* Left Pane: Flutter / Dart */}
              <div className="flex flex-col h-full bg-slate-900/20 overflow-hidden">
                <div className="p-3 border-b border-slate-800/80 bg-slate-900/60 flex items-center justify-between text-xs">
                  <div className="flex items-center gap-2">
                    <span className="w-2.5 h-2.5 rounded-full bg-sky-500" />
                    <span className="font-bold text-sky-400">Flutter (Dart)</span>
                    <span className="text-slate-500 font-mono text-[11px] truncate max-w-xs">
                      {activeFile?.relativePath || 'لا يوجد ملف محدد'}
                    </span>
                  </div>
                  <button
                    onClick={() => copyToClipboard(transpileResult?.originalCode || '', true)}
                    className="p-1.5 rounded-lg hover:bg-slate-800 text-slate-400 hover:text-white transition flex items-center gap-1"
                    title="نسخ كود Dart"
                  >
                    {copiedDart ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
                    <span>نسخ</span>
                  </button>
                </div>

                <div className="flex-1 overflow-auto p-4 font-mono text-xs text-slate-300 leading-relaxed scrollbar-thin">
                  {converting ? (
                    <div className="h-full flex items-center justify-center text-slate-500 gap-2">
                      <RefreshCw className="w-4 h-4 animate-spin text-sky-400" />
                      جاري قراءة كود Dart...
                    </div>
                  ) : (
                    <pre className="whitespace-pre">
                      {transpileResult?.originalCode || '// اختر ملفاً من القائمة الجانبية لعرض الكود'}
                    </pre>
                  )}
                </div>
              </div>

              {/* Right Pane: Next.js / TypeScript / React */}
              <div className="flex flex-col h-full bg-slate-900/40 overflow-hidden">
                <div className="p-3 border-b border-slate-800/80 bg-slate-900/60 flex items-center justify-between text-xs">
                  <div className="flex items-center gap-2">
                    <span className="w-2.5 h-2.5 rounded-full bg-emerald-500" />
                    <span className="font-bold text-emerald-400">Next.js (TSX / Tailwind)</span>
                    <span className="text-slate-500 font-mono text-[11px] truncate max-w-xs">
                      {transpileResult?.targetPath || 'src/components/...'}
                    </span>
                  </div>
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => copyToClipboard(transpileResult?.convertedCode || '', false)}
                      className="p-1.5 rounded-lg hover:bg-slate-800 text-slate-400 hover:text-white transition flex items-center gap-1"
                      title="نسخ كود Next.js"
                    >
                      {copiedNext ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
                      <span>نسخ الكود المحول</span>
                    </button>
                  </div>
                </div>

                <div className="flex-1 overflow-auto p-4 font-mono text-xs text-emerald-300/90 leading-relaxed bg-slate-950/80 scrollbar-thin">
                  {converting ? (
                    <div className="h-full flex items-center justify-center text-slate-500 gap-2">
                      <Sparkles className="w-4 h-4 animate-spin text-emerald-400" />
                      جاري التحويل الذكي لكود Next.js...
                    </div>
                  ) : (
                    <pre className="whitespace-pre">
                      {transpileResult?.convertedCode || '// الكود المحول سيظهر هنا'}
                    </pre>
                  )}
                </div>
              </div>
            </div>
          )}

          {/* TAB 2: LIVE COMPONENT PREVIEW */}
          {activeTab === 'preview' && (
            <div className="flex-1 overflow-y-auto p-8 space-y-8 max-w-5xl mx-auto w-full">
              <div className="border-b border-slate-800 pb-4">
                <h2 className="text-xl font-bold text-white flex items-center gap-2">
                  <Eye className="w-5 h-5 text-emerald-400" />
                  معاينة حية للمكونات المحولة إلى Next.js
                </h2>
                <p className="text-xs text-slate-400 mt-1">
                  هذه المكونات تم تحويلها من ودجات Flutter مثل <code className="text-blue-400">MetricCard</code> و <code className="text-blue-400">DashboardScreen</code> مباشرة
                </p>
              </div>

              {/* Converted MetricCards Interactive Demo */}
              <div className="space-y-4">
                <h3 className="text-sm font-bold text-slate-300">بطاقات المؤشرات (MetricCard Component):</h3>
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                  {/* Metric 1 */}
                  <div className="relative overflow-hidden rounded-3xl p-5 border border-slate-800 bg-gradient-to-br from-slate-900 via-slate-900 to-blue-950/30 shadow-lg hover:shadow-xl transition">
                    <div className="flex items-center justify-between mb-4">
                      <div className="w-10 h-10 rounded-2xl bg-blue-600/15 text-blue-400 flex items-center justify-center font-bold">
                        <TrendingUp className="w-5 h-5" />
                      </div>
                      <div className="w-2.5 h-2.5 rounded-full bg-blue-500 ring-4 ring-blue-500/20" />
                    </div>
                    <div className="space-y-1">
                      <p className="text-xs font-semibold text-slate-400">إجمالي المبيعات</p>
                      <h3 className="text-2xl font-black text-white">12,500,000 ج.م</h3>
                      <p className="text-[11px] text-emerald-400 font-medium">↑ +14% مقارنة بالشهر السابق</p>
                    </div>
                  </div>

                  {/* Metric 2 */}
                  <div className="relative overflow-hidden rounded-3xl p-5 border border-slate-800 bg-gradient-to-br from-slate-900 via-slate-900 to-emerald-950/30 shadow-lg hover:shadow-xl transition">
                    <div className="flex items-center justify-between mb-4">
                      <div className="w-10 h-10 rounded-2xl bg-emerald-600/15 text-emerald-400 flex items-center justify-center font-bold">
                        <DollarSign className="w-5 h-5" />
                      </div>
                      <div className="w-2.5 h-2.5 rounded-full bg-emerald-500 ring-4 ring-emerald-500/20" />
                    </div>
                    <div className="space-y-1">
                      <p className="text-xs font-semibold text-slate-400">التحصيلات النقدية</p>
                      <h3 className="text-2xl font-black text-white">4,850,000 ج.م</h3>
                      <p className="text-[11px] text-slate-400">تم تحصيل 78% من المستحق</p>
                    </div>
                  </div>

                  {/* Metric 3 */}
                  <div className="relative overflow-hidden rounded-3xl p-5 border border-slate-800 bg-gradient-to-br from-slate-900 via-slate-900 to-amber-950/30 shadow-lg hover:shadow-xl transition">
                    <div className="flex items-center justify-between mb-4">
                      <div className="w-10 h-10 rounded-2xl bg-amber-600/15 text-amber-400 flex items-center justify-center font-bold">
                        <Calendar className="w-5 h-5" />
                      </div>
                      <div className="w-2.5 h-2.5 rounded-full bg-amber-500 ring-4 ring-amber-500/20" />
                    </div>
                    <div className="space-y-1">
                      <p className="text-xs font-semibold text-slate-400">الأقساط المستحقة</p>
                      <h3 className="text-2xl font-black text-white">24 قسط</h3>
                      <p className="text-[11px] text-amber-400">خلال الـ 30 يوماً القادمة</p>
                    </div>
                  </div>

                  {/* Metric 4 */}
                  <div className="relative overflow-hidden rounded-3xl p-5 border border-slate-800 bg-gradient-to-br from-slate-900 via-slate-900 to-purple-950/30 shadow-lg hover:shadow-xl transition">
                    <div className="flex items-center justify-between mb-4">
                      <div className="w-10 h-10 rounded-2xl bg-purple-600/15 text-purple-400 flex items-center justify-center font-bold">
                        <Building2 className="w-5 h-5" />
                      </div>
                      <div className="w-2.5 h-2.5 rounded-full bg-purple-500 ring-4 ring-purple-500/20" />
                    </div>
                    <div className="space-y-1">
                      <p className="text-xs font-semibold text-slate-400">الوحدات السكنية</p>
                      <h3 className="text-2xl font-black text-white">48 وحدة</h3>
                      <p className="text-[11px] text-purple-400">3 مشروعات نشطة</p>
                    </div>
                  </div>
                </div>
              </div>

              {/* Converted Quick Actions Panel */}
              <div className="rounded-3xl p-6 border border-slate-800 bg-slate-900/60 shadow-lg">
                <h3 className="text-base font-bold text-white mb-2">روابط سريعة (AppPanel Component)</h3>
                <p className="text-xs text-slate-400 mb-4">تم تحويلها من OutlinedButton.icon في Flutter إلى أزرار Next.js Link تفاعلية</p>
                <div className="flex flex-wrap gap-3">
                  <button className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl border border-slate-700 bg-slate-800 hover:bg-slate-750 text-white font-medium text-xs transition">
                    <Building2 className="w-4 h-4 text-blue-400" />
                    <span>المشروعات والعقارات</span>
                  </button>
                  <button className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl border border-slate-700 bg-slate-800 hover:bg-slate-750 text-white font-medium text-xs transition">
                    <Receipt className="w-4 h-4 text-emerald-400" />
                    <span>دفتر المصروفات والتشوينات</span>
                  </button>
                  <button className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl border border-slate-700 bg-slate-800 hover:bg-slate-750 text-white font-medium text-xs transition">
                    <Users className="w-4 h-4 text-purple-400" />
                    <span>سجل الشركاء والتسويات</span>
                  </button>
                  <button className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl border border-slate-700 bg-slate-800 hover:bg-slate-750 text-white font-medium text-xs transition">
                    <DollarSign className="w-4 h-4 text-amber-400" />
                    <span>جدول الأقساط والدفعات</span>
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* TAB 3: PLAYGROUND CONVERTER */}
          {activeTab === 'playground' && (
            <div className="flex-1 flex flex-col p-6 overflow-hidden">
              <div className="mb-4 flex items-center justify-between">
                <div>
                  <h2 className="text-lg font-bold text-white flex items-center gap-2">
                    <Play className="w-5 h-5 text-amber-400" />
                    محول الأكواد المباشر (Direct Flutter Snippet Converter)
                  </h2>
                  <p className="text-xs text-slate-400 mt-0.5">
                    الصق أي كود فلاتر (ودجت، موديل، أو دالة) وسيتم تحويله فورياً لكود Next.js مع Tailwind
                  </p>
                </div>
                <button
                  onClick={handlePlaygroundConvert}
                  disabled={converting}
                  className="px-5 py-2.5 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 font-extrabold text-xs flex items-center gap-2 shadow-lg shadow-amber-500/20 transition active:scale-95 disabled:opacity-50"
                >
                  <Sparkles className="w-4 h-4" />
                  <span>تحويل الكود الآن</span>
                </button>
              </div>

              <div className="flex-1 grid grid-cols-1 lg:grid-cols-2 gap-4 overflow-hidden">
                <div className="flex flex-col rounded-2xl border border-slate-800 bg-slate-900/60 overflow-hidden">
                  <div className="p-3 border-b border-slate-800 bg-slate-900 flex items-center justify-between text-xs font-bold text-slate-300">
                    <span>كود Flutter (Dart) للمدخلات:</span>
                  </div>
                  <textarea
                    value={customDartCode}
                    onChange={e => setCustomDartCode(e.target.value)}
                    className="flex-1 p-4 bg-transparent font-mono text-xs text-sky-300 focus:outline-none resize-none leading-relaxed"
                    placeholder="الصق كود فلاتر هنا..."
                    dir="ltr"
                  />
                </div>

                <div className="flex flex-col rounded-2xl border border-slate-800 bg-slate-900/60 overflow-hidden">
                  <div className="p-3 border-b border-slate-800 bg-slate-900 flex items-center justify-between text-xs font-bold text-emerald-400">
                    <span>النتيجة بـ Next.js (TSX / Tailwind):</span>
                    {playgroundResult && (
                      <button
                        onClick={() => copyToClipboard(playgroundResult, false)}
                        className="text-[11px] font-normal text-slate-400 hover:text-white flex items-center gap-1"
                      >
                        <Copy className="w-3 h-3" />
                        <span>نسخ</span>
                      </button>
                    )}
                  </div>
                  <div className="flex-1 p-4 bg-slate-950 font-mono text-xs text-emerald-300 overflow-auto leading-relaxed" dir="ltr">
                    <pre className="whitespace-pre">
                      {playgroundResult || '// اضغط على "تحويل الكود الآن" لرؤية النتيجة'}
                    </pre>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* TAB 4: EXPORT & CLI INSTRUCTIONS */}
          {activeTab === 'export' && (
            <div className="flex-1 overflow-y-auto p-8 max-w-4xl mx-auto w-full space-y-6">
              <div className="border-b border-slate-800 pb-4">
                <h2 className="text-xl font-bold text-white flex items-center gap-2">
                  <Download className="w-5 h-5 text-purple-400" />
                  حزمة Next.js المصدرة والتشغيل
                </h2>
                <p className="text-xs text-slate-400 mt-1">
                  يمكنك تشغيل التحويل الآلي من الموقع أو تشغيل السكربت من الطرفية (Terminal)
                </p>
              </div>

              {batchProgress && (
                <div className={`p-4 rounded-2xl border ${batchProgress.running ? 'bg-blue-600/10 border-blue-500/30' : 'bg-emerald-600/10 border-emerald-500/30'}`}>
                  <div className="flex items-center gap-2 text-sm font-bold">
                    {batchProgress.running ? (
                      <RefreshCw className="w-4 h-4 animate-spin text-blue-400" />
                    ) : (
                      <CheckCircle2 className="w-4 h-4 text-emerald-400" />
                    )}
                    <span>{batchProgress.message}</span>
                  </div>
                </div>
              )}

              {/* Action Box */}
              <div className="p-6 rounded-3xl border border-slate-800 bg-slate-900/60 flex flex-col sm:flex-row items-center justify-between gap-4">
                <div>
                  <h3 className="text-base font-bold text-white">تصدير جميع ملفات lib دفعة واحدة</h3>
                  <p className="text-xs text-slate-400 mt-1">
                    يقوم بحفظ الملفات المحولة مباشرة داخل مجلد <code className="text-emerald-400 font-mono">src/converted_app/</code>
                  </p>
                </div>
                <button
                  onClick={handleBatchExport}
                  className="px-6 py-3 rounded-2xl bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 text-white font-extrabold text-xs shadow-lg shadow-blue-600/25 transition active:scale-95 flex items-center gap-2 shrink-0"
                >
                  <Sparkles className="w-4 h-4" />
                  <span>بدء التصدير الشامل</span>
                </button>
              </div>

              {/* Terminal CLI Instructions */}
              <div className="space-y-3">
                <h3 className="text-sm font-bold text-slate-300">تشغيل التحويل من الطرفية (Terminal CLI):</h3>
                <div className="p-4 rounded-2xl bg-slate-900 border border-slate-800 font-mono text-xs text-slate-300 space-y-2" dir="ltr">
                  <p className="text-slate-500"># الدخول لمجلد مشروع الويب</p>
                  <p className="text-blue-400">cd &quot;/home/ibrahim-elshishtawy/flutter project/Aqar-El-Masryeen/aqar_web_converter&quot;</p>
                  <p className="text-slate-500 mt-2"># تشغيل سكربت التحويل الآلي</p>
                  <p className="text-emerald-400">npm run convert</p>
                  <p className="text-slate-500 mt-2"># تشغيل موقع الويب</p>
                  <p className="text-amber-400">npm run dev</p>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
