import React from 'react';
import Link from 'next/link';
import { Building2 } from 'lucide-react';

export function HomeFooter() {
  return (
    <footer className="bg-[#1A1A1A] text-[#777777] border-t border-[#333333] pt-12 pb-24 md:pb-12">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex flex-col md:flex-row items-center justify-between gap-6 pb-8 border-b border-[#333333]">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-[#242424] text-white flex items-center justify-center font-serif text-base border border-[#333333]">
              <Building2 className="w-5 h-5 text-[#A89F91]" />
            </div>
            <div>
              <span className="font-editorial text-xl font-bold text-[#F4F4F2] block leading-none">
                عقار المصريين
              </span>
              <span className="text-[9px] uppercase tracking-wider text-[#A89F91] mt-1 block">
                Architectural Prestige & Real Estate
              </span>
            </div>
          </div>

          <div className="flex flex-wrap items-center justify-center gap-6 text-xs font-semibold text-[#A89F91]">
            <Link href="#projects" className="hover:text-white transition">المشروعات</Link>
            <Link href="#calculator" className="hover:text-white transition">حاسبة الأقساط</Link>
            <Link href="#about" className="hover:text-white transition">عن المنظومة</Link>
            <Link href="/dashboard" className="hover:text-white transition">بوابة الإدارة والمحاسبة</Link>
          </div>
        </div>

        <div className="pt-6 flex flex-col sm:flex-row items-center justify-between gap-4 text-[11px] text-[#555555]">
          <p>© 2026 شركة عقار المصريين للتطوير العقاري والمقاولات. جميع الحقوق محفوظة.</p>
          <p>معمارية فائقة الأداء مبنية بتقنية Next.js Server Components</p>
        </div>
      </div>
    </footer>
  );
}
