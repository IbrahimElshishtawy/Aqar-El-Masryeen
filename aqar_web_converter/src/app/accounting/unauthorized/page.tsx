'use client';

import React from 'react';
import Link from 'next/link';
import { ShieldAlert, ArrowRight, LogOut, Home } from 'lucide-react';
import { useRouter } from 'next/navigation';

export default function UnauthorizedPage() {
  const router = useRouter();

  const handleLogout = async () => {
    await fetch('/api/auth/logout', { method: 'POST' });
    router.push('/accounting/login');
  };

  return (
    <div
      className="min-h-screen bg-[#1A1A1A] text-[#F4F4F2] flex items-center justify-center p-4 font-sans selection:bg-[#A89F91] selection:text-white"
      dir="rtl"
    >
      <div className="w-full max-w-md bg-[#242424] border border-rose-900/50 rounded-3xl p-8 shadow-2xl text-center space-y-6">
        <div className="w-16 h-16 rounded-2xl bg-rose-950/60 border border-rose-800 flex items-center justify-center mx-auto text-rose-400">
          <ShieldAlert className="w-9 h-9" />
        </div>

        <div>
          <h1 className="font-editorial text-2xl font-bold text-white">غير مصرح لك بالوصول (403 Forbidden)</h1>
          <p className="text-xs text-[#999999] mt-2 leading-relaxed">
            حسابك الحالي لا يمتلك الصلاحيات الكافية للوصول إلى هذا القسم المحاسبي أو الإداري الحساس. تم تسجيل هذا النشاط في سجل التدقيق الأمني لمنظومة عقار المصريين.
          </p>
        </div>

        <div className="pt-2 flex flex-col sm:flex-row items-center justify-center gap-3">
          <Link
            href="/dashboard"
            className="w-full sm:w-auto px-5 py-2.5 rounded-xl bg-[#A89F91] hover:bg-[#B7AEA0] text-[#1A1A1A] text-xs font-bold transition flex items-center justify-center gap-2"
          >
            <Home className="w-4 h-4" />
            <span>لوحة المؤشرات المسموحة</span>
          </Link>

          <button
            onClick={handleLogout}
            className="w-full sm:w-auto px-5 py-2.5 rounded-xl bg-[#1A1A1A] hover:bg-[#2A2A2A] border border-[#333333] text-rose-300 text-xs font-bold transition flex items-center justify-center gap-2"
          >
            <LogOut className="w-4 h-4" />
            <span>تسجيل الخروج والتبديل</span>
          </button>
        </div>
      </div>
    </div>
  );
}
