'use client';

import React from 'react';
import Link from 'next/link';
import { Phone, MessageCircle, Calculator, ShieldCheck } from 'lucide-react';

export function MobileFloatingBar() {
  return (
    <div className="fixed bottom-0 inset-x-0 z-40 bg-[#242424]/95 backdrop-blur-md border-t border-[#333333] px-4 py-2.5 md:hidden">
      <div className="flex items-center justify-between gap-2 max-w-md mx-auto">
        <a
          href="https://wa.me/201012345678"
          target="_blank"
          rel="noopener noreferrer"
          className="flex-1 py-2 px-3 rounded-xl bg-[#A89F91] text-[#242424] font-bold text-xs flex items-center justify-center gap-1.5 shadow-sm active:scale-95 transition"
        >
          <MessageCircle className="w-4 h-4" />
          <span>واتساب</span>
        </a>

        <a
          href="tel:+201012345678"
          className="flex-1 py-2 px-3 rounded-xl bg-[#333333] text-white font-bold text-xs flex items-center justify-center gap-1.5 active:scale-95 transition"
        >
          <Phone className="w-3.5 h-3.5 text-[#A89F91]" />
          <span>اتصال</span>
        </a>

        <Link
          href="#calculator"
          className="p-2.5 rounded-xl bg-[#333333] text-[#A89F91] hover:text-white transition"
          aria-label="حاسبة الأقساط"
        >
          <Calculator className="w-4 h-4" />
        </Link>

        <Link
          href="/dashboard"
          className="p-2.5 rounded-xl bg-[#333333] text-[#A89F91] hover:text-white transition"
          aria-label="لوحة الإدارة"
        >
          <ShieldCheck className="w-4 h-4" />
        </Link>
      </div>
    </div>
  );
}
