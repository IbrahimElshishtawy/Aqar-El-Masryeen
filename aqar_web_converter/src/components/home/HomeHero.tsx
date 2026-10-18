import React from 'react';
import Link from 'next/link';
import { ArrowRight, ShieldCheck } from 'lucide-react';

export function HomeHero() {
  return (
    <section className="relative pt-12 pb-16 lg:pt-20 lg:pb-24 overflow-hidden border-b border-[#E2DFD8]">
      {/* Geometric background grid */}
      <div
        className="absolute inset-0 pointer-events-none opacity-[0.035]"
        style={{
          backgroundImage: `radial-gradient(#242424 1px, transparent 1px)`,
          backgroundSize: '24px 24px',
        }}
      />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        <div className="text-center max-w-3xl mx-auto space-y-5">
          {/* Tagline Badge */}
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-[#EBE8E1] border border-[#E2DFD8] text-xs font-bold text-[#777777]">
            <span className="w-2 h-2 rounded-full bg-[#A89F91]" />
            <span className="tracking-wide">ARCHITECTURAL PRESTIGE • المنظومة العقارية الذكية</span>
          </div>

          {/* Main Title */}
          <h1 className="font-editorial text-3xl sm:text-5xl lg:text-6xl font-black text-[#242424] leading-[1.2] tracking-tight">
            عقار المصريين.. فخامة معمارية راسخة وإدارة مالية محكمة
          </h1>

          {/* Subtitle */}
          <p className="text-sm sm:text-lg text-[#777777] leading-relaxed max-w-2xl mx-auto font-normal">
            صرح عقاري واستثماري مصري رائد يجمع بين روعة التصميم المعماري الحديث والشفافية المحاسبية المطلقة في إدارة الوحدات، جداول الأقساط، وحسابات الشركاء بدقة لا تقبل الخطأ.
          </p>

          {/* Hero Action Buttons */}
          <div className="flex flex-wrap items-center justify-center gap-3 pt-3">
            <Link
              href="#projects"
              className="w-full sm:w-auto px-6 py-3.5 rounded-full bg-[#242424] hover:bg-[#111111] text-white font-bold text-sm flex items-center justify-center gap-2.5 shadow-md hover:shadow-lg transition active:scale-95"
            >
              <span>استكشف المشروعات والوحدات</span>
              <ArrowRight className="w-4 h-4 text-[#A89F91]" />
            </Link>

            <Link
              href="#calculator"
              className="w-full sm:w-auto px-6 py-3.5 rounded-full bg-[#F4F4F2] hover:bg-[#EBE8E1] text-[#242424] font-bold text-sm border border-[#242424] transition active:scale-95 text-center"
            >
              <span>حاسبة الأقساط التفاعلية</span>
            </Link>

            <Link
              href="/dashboard"
              className="w-full sm:w-auto px-5 py-3.5 rounded-full bg-[#A89F91]/20 hover:bg-[#A89F91]/30 text-[#242424] font-bold text-sm border border-[#A89F91]/40 transition active:scale-95 flex items-center justify-center gap-2"
            >
              <ShieldCheck className="w-4 h-4 text-[#777777]" />
              <span>دخول برنامج المحاسبة</span>
            </Link>
          </div>
        </div>
      </div>
    </section>
  );
}
