'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { Building2, Menu, X, ShieldCheck, MessageCircle, Phone } from 'lucide-react';

export function HomeNavbar() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  return (
    <header className="sticky top-0 z-50 bg-[#F4F4F2]/95 backdrop-blur-md border-b border-[#E2DFD8] transition-all duration-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-20 flex items-center justify-between">
        {/* Brand Logo */}
        <Link href="/" className="flex items-center gap-3.5 group">
          <div className="w-11 h-11 rounded-xl bg-[#242424] text-white flex items-center justify-center font-serif text-lg tracking-wider shadow-md group-hover:bg-[#A89F91] transition duration-300">
            <Building2 className="w-6 h-6 text-[#F4F4F2]" />
          </div>
          <div>
            <span className="font-editorial text-2xl font-black tracking-tight text-[#242424] block leading-none">
              عقار المصريين
            </span>
            <span className="text-[10px] tracking-[0.2em] uppercase font-bold text-[#777777] mt-1 block">
              Architectural Prestige & Real Estate
            </span>
          </div>
        </Link>

        {/* Desktop Navigation */}
        <nav className="hidden lg:flex items-center gap-8 text-sm font-semibold text-[#777777]">
          <Link href="#projects" className="hover:text-[#242424] transition">
            المشروعات المعمارية
          </Link>
          <Link href="#calculator" className="hover:text-[#242424] transition">
            حاسبة الأقساط
          </Link>
          <Link href="#about" className="hover:text-[#242424] transition">
            عن المنظومة
          </Link>
          <Link href="#contact" className="hover:text-[#242424] transition">
            تواصل معنا
          </Link>
        </nav>

        {/* Action CTAs */}
        <div className="flex items-center gap-3">
          <Link
            href="/dashboard"
            className="px-4 py-2.5 rounded-full bg-[#242424] hover:bg-[#1A1A1A] text-white text-xs font-bold flex items-center gap-2 shadow-sm transition active:scale-95 border border-[#242424]"
          >
            <ShieldCheck className="w-3.5 h-3.5 text-[#A89F91]" />
            <span className="hidden sm:inline">إدارة الأدمن والمحاسبة</span>
            <span className="sm:hidden">الأدمن</span>
          </Link>

          <a
            href="https://wa.me/201012345678"
            target="_blank"
            rel="noopener noreferrer"
            className="hidden sm:flex items-center gap-1.5 px-3.5 py-2.5 rounded-full bg-[#EBE8E1] hover:bg-[#E2DFD8] text-[#242424] text-xs font-semibold border border-[#E2DFD8] transition"
          >
            <MessageCircle className="w-4 h-4 text-[#777777]" />
            <span>استفسار فوري</span>
          </a>

          {/* Mobile Menu Button */}
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="lg:hidden p-2 rounded-xl bg-[#EBE8E1] text-[#242424] hover:bg-[#E2DFD8] transition"
            aria-label="القائمة"
          >
            {mobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>
      </div>

      {/* Mobile Drawer Menu */}
      {mobileMenuOpen && (
        <div className="lg:hidden border-t border-[#E2DFD8] bg-[#F4F4F2] px-6 py-5 space-y-4 animate-in fade-in slide-in-from-top-2 duration-200">
          <nav className="flex flex-col gap-3 font-semibold text-[#242424]">
            <Link
              href="#projects"
              onClick={() => setMobileMenuOpen(false)}
              className="p-3 rounded-xl hover:bg-[#EBE8E1] transition flex items-center justify-between"
            >
              <span>المشروعات المعمارية</span>
            </Link>
            <Link
              href="#calculator"
              onClick={() => setMobileMenuOpen(false)}
              className="p-3 rounded-xl hover:bg-[#EBE8E1] transition flex items-center justify-between"
            >
              <span>حاسبة الأقساط</span>
            </Link>
            <Link
              href="#about"
              onClick={() => setMobileMenuOpen(false)}
              className="p-3 rounded-xl hover:bg-[#EBE8E1] transition flex items-center justify-between"
            >
              <span>عن المنظومة</span>
            </Link>
            <Link
              href="/accounting/login"
              onClick={() => setMobileMenuOpen(false)}
              className="p-3 rounded-xl bg-[#242424] text-white transition flex items-center justify-between font-bold"
            >
              <div className="flex items-center gap-2">
                <ShieldCheck className="w-4 h-4 text-[#A89F91]" />
                <span>دخول بوابة المحاسبة والشركاء</span>
              </div>
            </Link>
            <Link
              href="#contact"
              onClick={() => setMobileMenuOpen(false)}
              className="p-3 rounded-xl hover:bg-[#EBE8E1] transition flex items-center justify-between"
            >
              <span>تواصل معنا</span>
            </Link>
          </nav>
          <div className="pt-3 border-t border-[#E2DFD8] flex gap-2">
            <a
              href="tel:+201012345678"
              className="flex-1 py-3 rounded-xl bg-[#EBE8E1] text-[#242424] font-bold text-center text-xs flex items-center justify-center gap-2"
            >
              <Phone className="w-4 h-4 text-[#777777]" />
              <span>اتصال هاتفي</span>
            </a>
            <a
              href="https://wa.me/201012345678"
              target="_blank"
              rel="noopener noreferrer"
              className="flex-1 py-3 rounded-xl bg-[#242424] text-white font-bold text-center text-xs flex items-center justify-center gap-2"
            >
              <MessageCircle className="w-4 h-4 text-[#A89F91]" />
              <span>واتساب</span>
            </a>
          </div>
        </div>
      )}
    </header>
  );
}
