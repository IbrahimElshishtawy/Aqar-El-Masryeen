'use client';

import React, { useState, useMemo } from 'react';
import Link from 'next/link';
import {
  Building2,
  Calendar,
  Receipt,
  Users,
  ShieldCheck,
  Search,
  ArrowRight,
  ArrowUpRight,
  CheckCircle2,
  Phone,
  MessageCircle,
  MapPin,
  TrendingUp,
  DollarSign,
  ChevronDown,
  Layers,
  Sparkles,
  Lock,
  Compass,
  FileSpreadsheet,
  Award
} from 'lucide-react';
import { initialProjects } from '@/services/store';

export default function HomePage() {
  // Search & Filter State
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedLocation, setSelectedLocation] = useState('all');
  const [selectedType, setSelectedType] = useState('all');

  // Installment Calculator State
  const [calcPrice, setCalcPrice] = useState<number>(3000000);
  const [calcDownPaymentPercent, setCalcDownPaymentPercent] = useState<number>(20);
  const [calcYears, setCalcYears] = useState<number>(3);
  const [calcFrequency, setCalcFrequency] = useState<'monthly' | 'quarterly'>('quarterly');

  // Consultation form state
  const [contactName, setContactName] = useState('');
  const [contactPhone, setContactPhone] = useState('');
  const [contactProject, setContactProject] = useState('كمبوند الأندلس ريزيدنس');
  const [submitted, setSubmitted] = useState(false);

  // Calculator computations
  const downPaymentAmount = useMemo(() => {
    return (calcPrice * calcDownPaymentPercent) / 100;
  }, [calcPrice, calcDownPaymentPercent]);

  const remainingAmount = useMemo(() => {
    return Math.max(0, calcPrice - downPaymentAmount);
  }, [calcPrice, downPaymentAmount]);

  const totalInstallmentsCount = useMemo(() => {
    return calcFrequency === 'monthly' ? calcYears * 12 : calcYears * 4;
  }, [calcFrequency, calcYears]);

  const installmentValue = useMemo(() => {
    if (totalInstallmentsCount === 0) return 0;
    return Math.round(remainingAmount / totalInstallmentsCount);
  }, [remainingAmount, totalInstallmentsCount]);

  // Filtered projects
  const filteredProjects = useMemo(() => {
    return initialProjects.filter(p => {
      const matchSearch = p.name.includes(searchTerm) || p.location.includes(searchTerm);
      const matchLocation = selectedLocation === 'all' || p.location.includes(selectedLocation);
      return matchSearch && matchLocation;
    });
  }, [searchTerm, selectedLocation]);

  const handleConsultationSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!contactName || !contactPhone) return;
    setSubmitted(true);
    setTimeout(() => {
      setSubmitted(false);
      setContactName('');
      setContactPhone('');
    }, 4000);
  };

  return (
    <div className="min-h-screen bg-[#F4F4F2] text-[#242424] font-sans selection:bg-[#A89F91] selection:text-white" dir="rtl">
      {/* Top Architectural Prestige Header */}
      <header className="sticky top-0 z-50 bg-[#F4F4F2]/95 backdrop-blur-md border-b border-[#E2DFD8] transition-all duration-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-20 flex items-center justify-between">
          {/* Logo & Brand Identity */}
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

          {/* Nav Links */}
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

          {/* Action CTAs: Admin Portal & Quick Contact */}
          <div className="flex items-center gap-3">
            <Link
              href="/dashboard"
              className="px-4 py-2.5 rounded-full bg-[#242424] hover:bg-[#1A1A1A] text-white text-xs font-bold flex items-center gap-2 shadow-sm transition active:scale-95 border border-[#242424]"
            >
              <Lock className="w-3.5 h-3.5 text-[#A89F91]" />
              <span>إدارة الأدمن والمحاسبة</span>
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
          </div>
        </div>
      </header>

      {/* Hero Section: Architectural Prestige Editorial */}
      <section className="relative pt-12 pb-20 lg:pt-20 lg:pb-28 overflow-hidden border-b border-[#E2DFD8]">
        {/* Subtle geometric architectural grid pattern */}
        <div
          className="absolute inset-0 pointer-events-none opacity-[0.035]"
          style={{
            backgroundImage: `radial-gradient(#242424 1px, transparent 1px)`,
            backgroundSize: '24px 24px',
          }}
        />

        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          <div className="text-center max-w-3xl mx-auto space-y-6">
            {/* Pill Tag */}
            <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-[#EBE8E1] border border-[#E2DFD8] text-xs font-bold text-[#777777]">
              <span className="w-2 h-2 rounded-full bg-[#A89F91]" />
              <span className="tracking-wide">ARCHITECTURAL PRESTIGE EDITORIAL • المنظومة العقارية الذكية</span>
            </div>

            {/* Editorial Headline */}
            <h1 className="font-editorial text-4xl sm:text-5xl lg:text-6xl font-black text-[#242424] leading-[1.18] tracking-tight">
              عقار المصريين.. فخامة معمارية راسخة وإدارة مالية محكمة
            </h1>

            {/* Subtitle */}
            <p className="text-base sm:text-lg text-[#777777] leading-relaxed max-w-2xl mx-auto font-normal">
              صرح عقاري واستثماري مصري رائد يجمع بين روعة التصميم المعماري الحديث والشفافية المحاسبية المطلقة في إدارة الوحدات، جداول الأقساط، وحسابات الشركاء بدقة لا تقبل الخطأ.
            </p>

            {/* Hero CTAs */}
            <div className="flex flex-wrap items-center justify-center gap-3 pt-2">
              <Link
                href="#projects"
                className="px-6 py-3.5 rounded-full bg-[#242424] hover:bg-[#111111] text-white font-bold text-sm flex items-center gap-2.5 shadow-md hover:shadow-lg transition active:scale-95"
              >
                <span>استكشف المشروعات والوحدات</span>
                <ArrowRight className="w-4 h-4 text-[#A89F91]" />
              </Link>

              <Link
                href="#calculator"
                className="px-6 py-3.5 rounded-full bg-[#F4F4F2] hover:bg-[#EBE8E1] text-[#242424] font-bold text-sm border border-[#242424] transition active:scale-95"
              >
                <span>حاسبة الأقساط التفاعلية</span>
              </Link>

              <Link
                href="/dashboard"
                className="px-5 py-3.5 rounded-full bg-[#A89F91]/20 hover:bg-[#A89F91]/30 text-[#242424] font-bold text-sm border border-[#A89F91]/40 transition active:scale-95 flex items-center gap-2"
              >
                <ShieldCheck className="w-4 h-4 text-[#777777]" />
                <span>دخول برنامج المحاسبة</span>
              </Link>
            </div>
          </div>

          {/* Quick Search & Filter Bar (Matching User Reference Image) */}
          <div className="mt-14 max-w-4xl mx-auto">
            <div className="p-3 sm:p-4 rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] shadow-xl shadow-black/5">
              <div className="grid grid-cols-1 sm:grid-cols-12 gap-3 items-center">
                {/* Search query input */}
                <div className="sm:col-span-5 relative">
                  <div className="absolute inset-y-0 right-0 pr-3.5 flex items-center pointer-events-none text-[#777777]">
                    <Search className="w-4 h-4" />
                  </div>
                  <input
                    type="text"
                    value={searchTerm}
                    onChange={e => setSearchTerm(e.target.value)}
                    placeholder="ابحث باسم المشروع، الحي، أو المنطقة..."
                    className="w-full pr-10 pl-4 py-3 rounded-2xl bg-[#F4F4F2] border border-[#E2DFD8] text-xs font-semibold text-[#242424] placeholder-[#777777] focus:outline-none focus:border-[#242424] transition"
                  />
                </div>

                {/* Location Select */}
                <div className="sm:col-span-3">
                  <select
                    value={selectedLocation}
                    onChange={e => setSelectedLocation(e.target.value)}
                    className="w-full px-3.5 py-3 rounded-2xl bg-[#F4F4F2] border border-[#E2DFD8] text-xs font-semibold text-[#242424] focus:outline-none focus:border-[#242424] transition appearance-none cursor-pointer"
                  >
                    <option value="all">كل المواقع الجغرافية</option>
                    <option value="التجمع الخامس">التجمع الخامس</option>
                    <option value="المعادي">كورنيش المعادي</option>
                    <option value="الشيخ زايد">الشيخ زايد</option>
                  </select>
                </div>

                {/* Property Type Select */}
                <div className="sm:col-span-2">
                  <select
                    value={selectedType}
                    onChange={e => setSelectedType(e.target.value)}
                    className="w-full px-3.5 py-3 rounded-2xl bg-[#F4F4F2] border border-[#E2DFD8] text-xs font-semibold text-[#242424] focus:outline-none focus:border-[#242424] transition appearance-none cursor-pointer"
                  >
                    <option value="all">جميع النماذج</option>
                    <option value="apartment">شقق سكنية</option>
                    <option value="penthouse">بنتهاوس فاخر</option>
                    <option value="duplex">دوبلكس</option>
                    <option value="commercial">تجاري وإداري</option>
                  </select>
                </div>

                {/* Filter CTA */}
                <div className="sm:col-span-2">
                  <button
                    onClick={() => {
                      const el = document.getElementById('projects');
                      if (el) el.scrollIntoView({ behavior: 'smooth' });
                    }}
                    className="w-full py-3 rounded-2xl bg-[#242424] hover:bg-[#1A1A1A] text-white font-bold text-xs flex items-center justify-center gap-1.5 transition active:scale-95"
                  >
                    <Search className="w-3.5 h-3.5 text-[#A89F91]" />
                    <span>بحث</span>
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* Statistics Band in Neutral Tone */}
          <div className="mt-14 grid grid-cols-2 lg:grid-cols-4 gap-4 max-w-5xl mx-auto">
            <div className="p-5 rounded-2xl bg-[#FFFFFF] border border-[#E2DFD8] text-center">
              <span className="font-editorial text-3xl font-black text-[#242424] block font-mono">156M+</span>
              <span className="text-xs font-semibold text-[#777777] mt-1 block">إجمالي مبيعات المشروعات</span>
            </div>
            <div className="p-5 rounded-2xl bg-[#FFFFFF] border border-[#E2DFD8] text-center">
              <span className="font-editorial text-3xl font-black text-[#242424] block font-mono">76</span>
              <span className="text-xs font-semibold text-[#777777] mt-1 block">وحدة عقارية راقية</span>
            </div>
            <div className="p-5 rounded-2xl bg-[#FFFFFF] border border-[#E2DFD8] text-center">
              <span className="font-editorial text-3xl font-black text-[#242424] block font-mono">98.6%</span>
              <span className="text-xs font-semibold text-[#777777] mt-1 block">نسبة الالتزام والتحصيل</span>
            </div>
            <div className="p-5 rounded-2xl bg-[#FFFFFF] border border-[#E2DFD8] text-center">
              <span className="font-editorial text-3xl font-black text-[#242424] block font-mono">100%</span>
              <span className="text-xs font-semibold text-[#777777] mt-1 block">دقة محاسبية مشددة</span>
            </div>
          </div>
        </div>
      </section>

      {/* Featured Projects Section */}
      <section id="projects" className="py-20 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex flex-col md:flex-row md:items-end justify-between mb-12 gap-4">
          <div>
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#EBE8E1] text-[#777777] text-xs font-bold mb-3">
              <Building2 className="w-3.5 h-3.5 text-[#A89F91]" />
              <span>المشروعات المعمارية القائمة</span>
            </div>
            <h2 className="font-editorial text-3xl sm:text-4xl font-black text-[#242424]">
              صروح معمارية تليق باستثمارك
            </h2>
            <p className="text-sm text-[#777777] mt-2 max-w-xl">
              تصفح مشروعاتنا العقارية في أفضل المواقع الاستثمارية، مصممة بأعلى معايير الهندسة المعمارية مع جداول سداد مرنة.
            </p>
          </div>

          <div className="flex items-center gap-2">
            <Link
              href="/dashboard"
              className="px-4 py-2 rounded-full border border-[#242424] text-[#242424] hover:bg-[#242424] hover:text-white transition text-xs font-bold flex items-center gap-1.5"
            >
              <span>إدارة المشروعات من لوحة الأدمن</span>
              <ArrowLeftIcon className="w-3.5 h-3.5" />
            </Link>
          </div>
        </div>

        {/* Projects Cards Grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {filteredProjects.map(project => (
            <div
              key={project.id}
              className="rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] overflow-hidden shadow-sm hover:shadow-xl transition-all duration-300 flex flex-col justify-between group"
            >
              <div>
                {/* Visual Header Representation */}
                <div className="h-48 bg-[#242424] relative flex items-center justify-center p-6 text-center overflow-hidden">
                  <div
                    className="absolute inset-0 opacity-15"
                    style={{
                      backgroundImage: `radial-gradient(#A89F91 1px, transparent 1px)`,
                      backgroundSize: '16px 16px',
                    }}
                  />
                  <div className="relative z-10 text-[#F4F4F2]">
                    <div className="w-12 h-12 rounded-2xl bg-[#A89F91]/20 border border-[#A89F91]/30 mx-auto flex items-center justify-center text-[#A89F91] mb-3 group-hover:scale-110 transition duration-300">
                      <Building2 className="w-6 h-6" />
                    </div>
                    <span className="font-editorial text-lg font-bold block">{project.name}</span>
                    <span className="text-[11px] text-[#A89F91] block mt-0.5">{project.location}</span>
                  </div>

                  {/* Status Badge */}
                  <div className="absolute top-4 right-4">
                    <span className="px-3 py-1 rounded-full bg-[#F4F4F2]/90 backdrop-blur-md text-[#242424] text-[10px] font-bold border border-[#E2DFD8]">
                      {project.status === 'active' ? 'قيد التنفيذ والمبيعات' : 'مرحلة التخطيط'}
                    </span>
                  </div>
                </div>

                {/* Content Body */}
                <div className="p-6 space-y-4">
                  <p className="text-xs text-[#777777] line-clamp-2 leading-relaxed">
                    {project.description}
                  </p>

                  <div className="grid grid-cols-2 gap-3 py-3 border-y border-[#E2DFD8] text-xs">
                    <div>
                      <span className="text-[11px] text-[#777777] block">إجمالي الوحدات</span>
                      <span className="font-bold text-[#242424] mt-0.5 block">{project.apartmentCount} وحدة</span>
                    </div>
                    <div>
                      <span className="text-[11px] text-[#777777] block">حجم المبيعات المتوقع</span>
                      <span className="font-bold font-mono text-[#242424] mt-0.5 block">
                        {(project.totalSalesTarget / 1000000).toFixed(1)} مليون ج.م
                      </span>
                    </div>
                  </div>

                  <div className="flex items-center justify-between text-xs text-[#777777]">
                    <span className="flex items-center gap-1">
                      <MapPin className="w-3.5 h-3.5 text-[#A89F91]" />
                      <span>{project.location}</span>
                    </span>
                    <span className="text-[10px] font-mono text-[#A89F91] font-bold">نظام تقسيط حتى 5 سنوات</span>
                  </div>
                </div>
              </div>

              {/* Card Footer Actions */}
              <div className="p-6 pt-0 flex items-center gap-2">
                <button
                  onClick={() => {
                    setCalcPrice(project.totalSalesTarget / project.apartmentCount);
                    const calcSection = document.getElementById('calculator');
                    if (calcSection) calcSection.scrollIntoView({ behavior: 'smooth' });
                  }}
                  className="flex-1 py-2.5 rounded-2xl bg-[#242424] hover:bg-[#1A1A1A] text-white text-xs font-bold transition flex items-center justify-center gap-2"
                >
                  <Calendar className="w-3.5 h-3.5 text-[#A89F91]" />
                  <span>احسب القسط لهذه الوحدة</span>
                </button>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Interactive Smart Installment Calculator */}
      <section id="calculator" className="py-20 bg-[#EBE8E1] border-y border-[#E2DFD8]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-2xl mx-auto mb-12">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#FFFFFF] border border-[#E2DFD8] text-xs font-bold text-[#777777] mb-3">
              <Calendar className="w-3.5 h-3.5 text-[#A89F91]" />
              <span>حاسبة الأقساط الذكية التفاعلية</span>
            </div>
            <h2 className="font-editorial text-3xl sm:text-4xl font-black text-[#242424]">
              خطط لاستثمارك بدقة واضحة
            </h2>
            <p className="text-sm text-[#777777] mt-2">
              اختر قيمة الوحدة ونظام السداد المفضل لديك، وشاهد التفصيل المالي الدقيق للمقدم والأقساط الدورية مباشرة.
            </p>
          </div>

          <div className="max-w-4xl mx-auto rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] p-6 sm:p-10 shadow-xl">
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
              {/* Controls Column */}
              <div className="lg:col-span-7 space-y-6">
                {/* Unit Price Input */}
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <label className="text-xs font-bold text-[#242424]">سعر الوحدة الإجمالي (ج.م)</label>
                    <span className="font-mono text-sm font-bold text-[#242424]">
                      {calcPrice.toLocaleString()} ج.م
                    </span>
                  </div>
                  <input
                    type="range"
                    min={1000000}
                    max={10000000}
                    step={100000}
                    value={calcPrice}
                    onChange={e => setCalcPrice(Number(e.target.value))}
                    className="w-full accent-[#242424] cursor-pointer"
                  />
                  <div className="flex justify-between text-[10px] text-[#777777] mt-1 font-mono">
                    <span>1,000,000 ج.م</span>
                    <span>5,000,000 ج.م</span>
                    <span>10,000,000 ج.م</span>
                  </div>
                </div>

                {/* Down Payment Percentage */}
                <div>
                  <label className="text-xs font-bold text-[#242424] block mb-2">
                    نسبة مقدم التعاقد: <span className="text-[#A89F91] font-mono font-bold">%{calcDownPaymentPercent}</span>
                  </label>
                  <div className="grid grid-cols-5 gap-2">
                    {[10, 15, 20, 25, 30].map(percent => (
                      <button
                        key={percent}
                        type="button"
                        onClick={() => setCalcDownPaymentPercent(percent)}
                        className={`py-2 rounded-xl text-xs font-bold transition border ${
                          calcDownPaymentPercent === percent
                            ? 'bg-[#242424] text-white border-[#242424]'
                            : 'bg-[#F4F4F2] text-[#777777] border-[#E2DFD8] hover:border-[#242424]'
                        }`}
                      >
                        %{percent}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Duration in Years */}
                <div>
                  <label className="text-xs font-bold text-[#242424] block mb-2">
                    فترة السداد (سنوات): <span className="text-[#A89F91] font-mono font-bold">{calcYears} سنوات</span>
                  </label>
                  <div className="grid grid-cols-5 gap-2">
                    {[1, 2, 3, 4, 5].map(years => (
                      <button
                        key={years}
                        type="button"
                        onClick={() => setCalcYears(years)}
                        className={`py-2 rounded-xl text-xs font-bold transition border ${
                          calcYears === years
                            ? 'bg-[#242424] text-white border-[#242424]'
                            : 'bg-[#F4F4F2] text-[#777777] border-[#E2DFD8] hover:border-[#242424]'
                        }`}
                      >
                        {years} {years === 1 ? 'سنة' : years === 2 ? 'سنتان' : 'سنوات'}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Installment Frequency */}
                <div>
                  <label className="text-xs font-bold text-[#242424] block mb-2">دورية دفع القسط</label>
                  <div className="grid grid-cols-2 gap-3">
                    <button
                      type="button"
                      onClick={() => setCalcFrequency('quarterly')}
                      className={`py-2.5 rounded-xl text-xs font-bold transition border ${
                        calcFrequency === 'quarterly'
                          ? 'bg-[#242424] text-white border-[#242424]'
                          : 'bg-[#F4F4F2] text-[#777777] border-[#E2DFD8]'
                      }`}
                    >
                      أقساط ربع سنوية (كل 3 شهور)
                    </button>
                    <button
                      type="button"
                      onClick={() => setCalcFrequency('monthly')}
                      className={`py-2.5 rounded-xl text-xs font-bold transition border ${
                        calcFrequency === 'monthly'
                          ? 'bg-[#242424] text-white border-[#242424]'
                          : 'bg-[#F4F4F2] text-[#777777] border-[#E2DFD8]'
                      }`}
                    >
                      أقساط شهرية (كل شهر)
                    </button>
                  </div>
                </div>
              </div>

              {/* Result Summary Box (Architectural Editorial Styled) */}
              <div className="lg:col-span-5 rounded-2xl bg-[#242424] text-white p-6 space-y-6">
                <div>
                  <span className="text-[10px] uppercase tracking-wider text-[#A89F91] font-bold block">
                    الملخص المالي للخطة المقترحة
                  </span>
                  <h3 className="font-editorial text-xl font-bold mt-1 text-[#F4F4F2]">
                    جدول الأقساط المعتمد
                  </h3>
                </div>

                <div className="space-y-3 text-xs">
                  <div className="flex items-center justify-between pb-2 border-b border-[#333333]">
                    <span className="text-[#A89F91]">مقدم التعاقد ({calcDownPaymentPercent}%):</span>
                    <span className="font-mono font-bold text-white text-sm">
                      {downPaymentAmount.toLocaleString()} ج.م
                    </span>
                  </div>

                  <div className="flex items-center justify-between pb-2 border-b border-[#333333]">
                    <span className="text-[#A89F91]">إجمالي المبلغ المتبقي:</span>
                    <span className="font-mono font-bold text-white text-sm">
                      {remainingAmount.toLocaleString()} ج.م
                    </span>
                  </div>

                  <div className="flex items-center justify-between pb-2 border-b border-[#333333]">
                    <span className="text-[#A89F91]">عدد الأقساط الإجمالية:</span>
                    <span className="font-mono font-bold text-white text-sm">
                      {totalInstallmentsCount} قسط {calcFrequency === 'quarterly' ? 'ربع سنوي' : 'شهري'}
                    </span>
                  </div>

                  {/* Primary Highlight */}
                  <div className="p-4 rounded-xl bg-[#1A1A1A] border border-[#333333] space-y-1">
                    <span className="text-[11px] text-[#A89F91] block font-semibold">
                      قيمة القسط الدوري المستحق
                    </span>
                    <span className="font-editorial text-2xl font-black text-white block font-mono">
                      {installmentValue.toLocaleString()} ج.م
                    </span>
                    <span className="text-[10px] text-[#777777] block">
                      {calcFrequency === 'quarterly' ? 'يسدد كل 3 أشهر بانتظام' : 'يسدد شهرياً بانتظام'}
                    </span>
                  </div>
                </div>

                <a
                  href={`https://wa.me/201012345678?text=${encodeURIComponent(
                    `مرحباً عقار المصريين، أود الاستفسار عن خطة سداد لوحدة بقيمة ${calcPrice.toLocaleString()} ج.م بمقدم ${downPaymentAmount.toLocaleString()} ج.م وقسط دوري ${installmentValue.toLocaleString()} ج.م.`
                  )}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="w-full py-3 rounded-xl bg-[#A89F91] hover:bg-[#978E80] text-[#242424] font-bold text-xs flex items-center justify-center gap-2 transition"
                >
                  <MessageCircle className="w-4 h-4" />
                  <span>تثبيت هذه الخطة والتواصل عبر واتساب</span>
                </a>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* System Pillars & Accounting Advantage Section */}
      <section id="about" className="py-20 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-2xl mx-auto mb-16">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#EBE8E1] text-[#777777] text-xs font-bold mb-3">
            <ShieldCheck className="w-3.5 h-3.5 text-[#A89F91]" />
            <span>الركائز الجوهرية لمنظومة عقار المصريين</span>
          </div>
          <h2 className="font-editorial text-3xl sm:text-4xl font-black text-[#242424]">
            لماذا يثق المستثمرون والعملاء في عقار المصريين؟
          </h2>
          <p className="text-sm text-[#777777] mt-2">
            بنينا منظومة العمل على أساسين راسخين: التميز المعماري في البناء، والدقة المحاسبية المطلقة في الإدارة المالية.
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          <div className="p-6 rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] space-y-3">
            <div className="w-11 h-11 rounded-2xl bg-[#242424] text-white flex items-center justify-center">
              <Calendar className="w-5 h-5 text-[#A89F91]" />
            </div>
            <h3 className="font-bold text-sm text-[#242424]">جدولة ذكية للأقساط</h3>
            <p className="text-xs text-[#777777] leading-relaxed">
              توليد شيتات الأقساط آلياً، مع تنبيهات استحقاق مبكرة وتحديث فوري للمتبقي والمسدد لكل عميل.
            </p>
          </div>

          <div className="p-6 rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] space-y-3">
            <div className="w-11 h-11 rounded-2xl bg-[#242424] text-white flex items-center justify-center">
              <Receipt className="w-5 h-5 text-[#A89F91]" />
            </div>
            <h3 className="font-bold text-sm text-[#242424]">ضبط المصروفات والتشوينات</h3>
            <p className="text-xs text-[#777777] leading-relaxed">
              تسجيل أدق تفاصيل فواتير الأسمنت والحديد ومستحقات المقاولين لضمان عدم إهدار أي مليم من ميزانية المشروع.
            </p>
          </div>

          <div className="p-6 rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] space-y-3">
            <div className="w-11 h-11 rounded-2xl bg-[#242424] text-white flex items-center justify-center">
              <Users className="w-5 h-5 text-[#A89F91]" />
            </div>
            <h3 className="font-bold text-sm text-[#242424]">شفافية تامة مع الشركاء</h3>
            <p className="text-xs text-[#777777] leading-relaxed">
              حساب نسب رؤوس الأموال والأرباح وتوزيع العوائد وتوثيق مسحوبات الشركاء بتقارير فورية معتمدة.
            </p>
          </div>

          <div className="p-6 rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] space-y-3">
            <div className="w-11 h-11 rounded-2xl bg-[#242424] text-white flex items-center justify-center">
              <ShieldCheck className="w-5 h-5 text-[#A89F91]" />
            </div>
            <h3 className="font-bold text-sm text-[#242424]">ضمانات وعقود قانونية</h3>
            <p className="text-xs text-[#777777] leading-relaxed">
              كافة الوحدات والتعاقدات موثقة بتراخيص بناء معتمدة وجداول تسليم ملزمة تضمن حقوق المشتري والمطور.
            </p>
          </div>
        </div>
      </section>

      {/* Admin Accounting Portal Feature Banner */}
      <section className="py-16 bg-[#242424] text-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="rounded-3xl bg-[#1A1A1A] border border-[#333333] p-8 sm:p-12 flex flex-col lg:flex-row items-center justify-between gap-8">
            <div className="space-y-4 max-w-2xl text-center lg:text-right">
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#333333] text-[#A89F91] text-xs font-bold">
                <Lock className="w-3.5 h-3.5" />
                <span>خاص بالإدارة العامة ومسؤولي الحسابات</span>
              </div>
              <h2 className="font-editorial text-3xl sm:text-4xl font-black text-white">
                برنامج المحاسبة وإدارة الأصول العقارية (Admin Portal)
              </h2>
              <p className="text-sm text-[#A89F91] leading-relaxed">
                هل أنت من مسؤولي شركة عقار المصريين أو الشركاء؟ يمكنك الانتقال المباشر إلى لوحة إدارة الأدمن الشاملة لمتابعة حركة الخزينة، إدخال الشيكات، تسوية حسابات المقاولين، وتوليد التقارير المالية التفصيلية.
              </p>
            </div>

            <div className="shrink-0 flex flex-col sm:flex-row items-center gap-3">
              <Link
                href="/dashboard"
                className="px-8 py-4 rounded-full bg-[#A89F91] hover:bg-[#978E80] text-[#242424] font-black text-sm transition shadow-lg flex items-center gap-2 active:scale-95"
              >
                <Lock className="w-4 h-4 text-[#242424]" />
                <span>دخول لوحة تحكم الأدمن والمحاسبة</span>
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* Contact & Consultation Form */}
      <section id="contact" className="py-20 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="max-w-3xl mx-auto rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] p-8 sm:p-12 shadow-sm text-center">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#EBE8E1] text-[#777777] text-xs font-bold mb-3">
            <Phone className="w-3.5 h-3.5 text-[#A89F91]" />
            <span>طلب معاينة أو استشارة عقارية</span>
          </div>
          <h2 className="font-editorial text-3xl font-black text-[#242424] mb-2">
            تواصل مع مستشار عقار المصريين
          </h2>
          <p className="text-xs text-[#777777] mb-8">
            اترك بياناتك وسيتواصل معك أحد خبرائنا لتقديم المعاينة الميدانية وجدول السداد الأنسب لميزانيتك.
          </p>

          {submitted ? (
            <div className="p-6 rounded-2xl bg-[#EBE8E1] text-[#242424] flex items-center justify-center gap-3 font-bold text-sm">
              <CheckCircle2 className="w-5 h-5 text-emerald-600" />
              <span>تم استلام طلبك بنجاح! سيتواصل معك فريق المبيعات خلال ساعات قليلة.</span>
            </div>
          ) : (
            <form onSubmit={handleConsultationSubmit} className="space-y-4 text-right">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="text-xs font-bold text-[#242424] block mb-1.5">الاسم بالكامل</label>
                  <input
                    type="text"
                    required
                    value={contactName}
                    onChange={e => setContactName(e.target.value)}
                    placeholder="مثال: م. محمد الأحمدي"
                    className="w-full px-4 py-3 rounded-2xl bg-[#F4F4F2] border border-[#E2DFD8] text-xs font-semibold text-[#242424] focus:outline-none focus:border-[#242424]"
                  />
                </div>
                <div>
                  <label className="text-xs font-bold text-[#242424] block mb-1.5">رقم الهاتف أو الواتساب</label>
                  <input
                    type="tel"
                    required
                    value={contactPhone}
                    onChange={e => setContactPhone(e.target.value)}
                    placeholder="010XXXXXXXX"
                    className="w-full px-4 py-3 rounded-2xl bg-[#F4F4F2] border border-[#E2DFD8] text-xs font-semibold text-[#242424] focus:outline-none focus:border-[#242424]"
                  />
                </div>
              </div>

              <div>
                <label className="text-xs font-bold text-[#242424] block mb-1.5">المشروع محل الاهتمام</label>
                <select
                  value={contactProject}
                  onChange={e => setContactProject(e.target.value)}
                  className="w-full px-4 py-3 rounded-2xl bg-[#F4F4F2] border border-[#E2DFD8] text-xs font-semibold text-[#242424] focus:outline-none focus:border-[#242424]"
                >
                  <option value="كمبوند الأندلس ريزيدنس">كمبوند الأندلس ريزيدنس (التجمع الخامس)</option>
                  <option value="برج النيل بلازا">برج النيل بلازا (كورنيش المعادي)</option>
                  <option value="عمارة الياسمين الراقية">عمارة الياسمين الراقية (الشيخ زايد)</option>
                </select>
              </div>

              <button
                type="submit"
                className="w-full py-3.5 rounded-2xl bg-[#242424] hover:bg-[#1A1A1A] text-white font-bold text-xs shadow-md transition active:scale-95"
              >
                إرسال طلب الاستشارة والمعاينة
              </button>
            </form>
          )}
        </div>
      </section>

      {/* Editorial Footer */}
      <footer className="bg-[#FFFFFF] border-t border-[#E2DFD8] pt-16 pb-12 text-[#777777] text-xs">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8 mb-12">
            <div className="space-y-3">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg bg-[#242424] text-white flex items-center justify-center font-bold">
                  <Building2 className="w-4 h-4 text-[#A89F91]" />
                </div>
                <span className="font-editorial text-lg font-black text-[#242424]">عقار المصريين</span>
              </div>
              <p className="text-[11px] leading-relaxed text-[#777777]">
                الصرح العقاري الرائد لإدارة وتطوير المشروعات والوحدات الفاخرة وفق أعلى معايير الشفافية والدقة المحاسبية.
              </p>
            </div>

            <div>
              <h4 className="font-bold text-[#242424] mb-3">روابط الموقع</h4>
              <ul className="space-y-2">
                <li><Link href="#projects" className="hover:text-[#242424]">المشروعات المعمارية</Link></li>
                <li><Link href="#calculator" className="hover:text-[#242424]">حاسبة الأقساط</Link></li>
                <li><Link href="#about" className="hover:text-[#242424]">ركائز المنظومة</Link></li>
                <li><Link href="/dashboard" className="text-[#242424] font-bold">بوابة إدارة الأدمن</Link></li>
              </ul>
            </div>

            <div>
              <h4 className="font-bold text-[#242424] mb-3">المشروعات النشطة</h4>
              <ul className="space-y-2">
                <li>كمبوند الأندلس ريزيدنس - القاهرة الجديدة</li>
                <li>برج النيل بلازا - كورنيش المعادي</li>
                <li>عمارة الياسمين الراقية - الشيخ زايد</li>
              </ul>
            </div>

            <div>
              <h4 className="font-bold text-[#242424] mb-3">التواصل والعمليات</h4>
              <p className="text-[11px] mb-2">القاهرة، جمهورية مصر العربية</p>
              <p className="text-[11px] font-mono text-[#242424] font-bold">هاتف: 01012345678</p>
              <p className="text-[11px] font-mono text-[#777777]">admin@elmasryeen.com</p>
            </div>
          </div>

          <div className="pt-8 border-t border-[#E2DFD8] flex flex-col sm:flex-row items-center justify-between text-[11px] text-[#777777] gap-4">
            <p>© 2026 عقار المصريين (El Masryeen). جميع الحقوق محفوظة.</p>
            <p className="text-[10px] text-[#A89F91] font-mono">Architectural Prestige Editorial Edition</p>
          </div>
        </div>
      </footer>
    </div>
  );
}

function ArrowLeftIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg
      fill="none"
      viewBox="0 0 24 24"
      strokeWidth={2}
      stroke="currentColor"
      {...props}
    >
      <path strokeLinecap="round" strokeLinejoin="round" d="M10.5 19.5 3 12m0 0 7.5-7.5M3 12h18" />
    </svg>
  );
}
