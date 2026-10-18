'use client';

import React, { useState, Suspense } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import Link from 'next/link';
import {
  Building2,
  Lock,
  Mail,
  ShieldCheck,
  ArrowRight,
  Eye,
  EyeOff,
  AlertCircle,
  KeyRound,
  Users,
  CheckCircle2,
} from 'lucide-react';

export default function AccountingLoginPage() {
  return (
    <Suspense fallback={<div className="min-h-screen bg-[#1E1E1E] flex items-center justify-center text-white">جاري التحميل...</div>}>
      <LoginFormContent />
    </Suspense>
  );
}

function LoginFormContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const redirectPath = searchParams.get('redirect') || '/dashboard';
  const isExpired = searchParams.get('expired') === 'true';

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(isExpired ? 'انتهت صلاحية جلسة العمل، يرجى تسجيل الدخول مجدداً' : '');

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });

      const data = await res.json();

      if (!res.ok) {
        throw new Error(data.error || 'فشل تسجيل الدخول');
      }

      router.push(redirectPath);
      router.refresh();
    } catch (err: any) {
      setError(err?.message || 'حدث خطأ أثناء تسجيل الدخول');
    } finally {
      setLoading(false);
    }
  };

  const handleQuickFill = (testEmail: string) => {
    setEmail(testEmail);
    setPassword('Aqar@2026Secure');
    setError('');
  };

  return (
    <div
      className="min-h-screen bg-[#1A1A1A] text-[#F4F4F2] flex flex-col justify-between font-sans selection:bg-[#A89F91] selection:text-white"
      dir="rtl"
    >
      {/* Top Navbar */}
      <header className="p-6 flex items-center justify-between max-w-6xl mx-auto w-full">
        <Link href="/" className="flex items-center gap-3 group">
          <div className="w-10 h-10 rounded-xl bg-[#242424] border border-[#A89F91]/40 flex items-center justify-center text-white group-hover:bg-[#A89F91] transition">
            <Building2 className="w-5 h-5 text-[#A89F91] group-hover:text-[#242424]" />
          </div>
          <div>
            <span className="font-editorial text-lg font-black text-white block">عقار المصريين</span>
            <span className="text-[9px] uppercase tracking-wider text-[#A89F91]">بوابة الدخول المحاسبي الآمن</span>
          </div>
        </Link>

        <Link
          href="/"
          className="px-3.5 py-2 rounded-xl bg-[#242424] hover:bg-[#2A2A2A] border border-[#333333] text-xs font-semibold text-[#A89F91] hover:text-white transition flex items-center gap-2"
        >
          <ArrowRight className="w-4 h-4" />
          <span>العودة للموقع العام</span>
        </Link>
      </header>

      {/* Main Content Card */}
      <main className="flex-1 flex items-center justify-center p-4">
        <div className="w-full max-w-md bg-[#242424] border border-[#333333] rounded-3xl p-8 shadow-2xl relative overflow-hidden">
          {/* Subtle Glow Accent */}
          <div className="absolute -top-24 -left-24 w-48 h-48 bg-[#A89F91]/10 rounded-full blur-3xl pointer-events-none" />

          {/* Header */}
          <div className="text-center mb-6">
            <div className="w-14 h-14 rounded-2xl bg-[#1A1A1A] border border-[#A89F91]/50 flex items-center justify-center mx-auto mb-3 shadow-lg">
              <ShieldCheck className="w-7 h-7 text-[#A89F91]" />
            </div>
            <h1 className="font-editorial text-2xl font-bold text-white tracking-tight">تسجيل الدخول للمنظومة المحاسبية</h1>
            <p className="text-xs text-[#888888] mt-1.5 leading-relaxed">
              منطقة مشفرة ومحمية خاصة بإدارة الحسابات وتوزيع الأرباح وأسعار المشروعات
            </p>
          </div>

          {/* Error Alert */}
          {error && (
            <div className="mb-5 p-3.5 rounded-2xl bg-rose-950/60 border border-rose-800/80 text-rose-200 text-xs flex items-start gap-2.5 animate-in fade-in duration-200">
              <AlertCircle className="w-4 h-4 shrink-0 text-rose-400 mt-0.5" />
              <span>{error}</span>
            </div>
          )}

          {/* Login Form */}
          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="block text-xs font-bold text-[#E2DFD8] mb-1.5">البريد الإلكتروني المعتمد</label>
              <div className="relative">
                <Mail className="w-4 h-4 text-[#777777] absolute right-3.5 top-3.5" />
                <input
                  type="email"
                  required
                  placeholder="admin@aqarelmasryeen.com"
                  value={email}
                  onChange={e => setEmail(e.target.value)}
                  className="w-full bg-[#1A1A1A] border border-[#333333] focus:border-[#A89F91] rounded-2xl pr-10 pl-4 py-3 text-xs text-white placeholder-[#555555] focus:outline-none transition"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold text-[#E2DFD8] mb-1.5">كلمة المرور المشفرة</label>
              <div className="relative">
                <Lock className="w-4 h-4 text-[#777777] absolute right-3.5 top-3.5" />
                <input
                  type={showPassword ? 'text' : 'password'}
                  required
                  placeholder="••••••••••••"
                  value={password}
                  onChange={e => setPassword(e.target.value)}
                  className="w-full bg-[#1A1A1A] border border-[#333333] focus:border-[#A89F91] rounded-2xl pr-10 pl-11 py-3 text-xs text-white placeholder-[#555555] focus:outline-none transition"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute left-3.5 top-3 text-[#777777] hover:text-[#A89F91] transition"
                  aria-label="إظهار كلمة المرور"
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3.5 rounded-2xl bg-[#A89F91] hover:bg-[#B7AEA0] text-[#1A1A1A] font-bold text-sm flex items-center justify-center gap-2 shadow-lg transition active:scale-98 disabled:opacity-50 mt-2"
            >
              {loading ? (
                <span>جاري التحقق من الصلاحيات...</span>
              ) : (
                <>
                  <KeyRound className="w-4 h-4" />
                  <span>دخول آمن للمنظومة</span>
                </>
              )}
            </button>
          </form>

          {/* Quick Role Fill Helper for Pair Programming & Audit Review */}
          <div className="mt-6 pt-5 border-t border-[#333333]">
            <p className="text-[11px] font-bold text-[#A89F91] mb-2.5 text-center">حسابات الفحص والمطابقة (انقر للتعبئة الفورية):</p>
            <div className="grid grid-cols-2 gap-2 text-[10px]">
              <button
                type="button"
                onClick={() => handleQuickFill('admin@aqarelmasryeen.com')}
                className="p-2 rounded-xl bg-[#1A1A1A] hover:bg-[#2A2A2A] border border-[#333333] text-right text-[#E2DFD8] transition"
              >
                <span className="font-bold block text-white">مدير المنظومة (Admin)</span>
                <span className="text-[9px] text-[#777777]">كامل الصلاحيات والتسويات</span>
              </button>

              <button
                type="button"
                onClick={() => handleQuickFill('accountant@aqarelmasryeen.com')}
                className="p-2 rounded-xl bg-[#1A1A1A] hover:bg-[#2A2A2A] border border-[#333333] text-right text-[#E2DFD8] transition"
              >
                <span className="font-bold block text-white">رئيس الحسابات (Accountant)</span>
                <span className="text-[9px] text-[#777777]">المصروفات والتحصيلات</span>
              </button>

              <button
                type="button"
                onClick={() => handleQuickFill('hossam.ghanem@aqarelmasryeen.com')}
                className="p-2 rounded-xl bg-[#1A1A1A] hover:bg-[#2A2A2A] border border-[#333333] text-right text-[#E2DFD8] transition"
              >
                <span className="font-bold block text-white">الشريك (Partner - 40%)</span>
                <span className="text-[9px] text-[#777777]">دفتر الشريك وحسابه فقط</span>
              </button>

              <button
                type="button"
                onClick={() => handleQuickFill('viewer@aqarelmasryeen.com')}
                className="p-2 rounded-xl bg-[#1A1A1A] hover:bg-[#2A2A2A] border border-[#333333] text-right text-[#E2DFD8] transition"
              >
                <span className="font-bold block text-white">المراقب (Viewer)</span>
                <span className="text-[9px] text-[#777777]">مشاهدة وقراءة فقط</span>
              </button>
            </div>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="p-6 text-center text-[11px] text-[#777777]">
        جميع الحقوق محفوظة لمنظومة عقار المصريين © 2026 | نظام محاسبي وإداري مشفر بتقنية HMAC-SHA256
      </footer>
    </div>
  );
}
