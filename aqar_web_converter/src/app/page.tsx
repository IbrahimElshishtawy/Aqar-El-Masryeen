import React from 'react';
import type { Metadata } from 'next';
import { initialProjects } from '@/services/store';
import { HomeNavbar } from '@/components/home/HomeNavbar';
import { HomeHero } from '@/components/home/HomeHero';
import { HomeStats } from '@/components/home/HomeStats';
import { ProjectExplorer } from '@/components/home/ProjectExplorer';
import { InstallmentCalculatorSection } from '@/components/home/InstallmentCalculatorSection';
import { WhyChooseUs } from '@/components/home/WhyChooseUs';
import { HomeConsultationSection } from '@/components/home/HomeConsultationSection';
import { HomeFooter } from '@/components/home/HomeFooter';
import { MobileFloatingBar } from '@/components/home/MobileFloatingBar';

export const metadata: Metadata = {
  title: 'عقار المصريين | Architectural Prestige & Real Estate',
  description: 'صرح عقاري واستثماري مصري رائد يجمع بين روعة التصميم المعماري الحديث والشفافية المحاسبية المطلقة في إدارة الوحدات وجداول الأقساط.',
  openGraph: {
    title: 'عقار المصريين | Architectural Prestige',
    description: 'المنظومة العقارية الذكية لإدارة المشروعات والوحدات وجداول السداد المحكمة.',
    type: 'website',
  },
};


export default function HomePage() {
  return (
    <div
      className="min-h-screen bg-[#F4F4F2] text-[#242424] font-sans selection:bg-[#A89F91] selection:text-white"
      dir="rtl"
    >
      {/* 1. Header with Desktop Nav & Mobile Drawer */}
      <HomeNavbar />

      {/* 2. Server-Rendered Hero Section */}
      <HomeHero />

      {/* 3. Server-Rendered High-Trust Stats Bar */}
      <HomeStats />

      {/* 4. Client Island: Interactive Search, Location Filters & Projects Grid */}
      <ProjectExplorer projects={initialProjects} />

      {/* 5. Client Island: Interactive Down-Payment & Installment Calculator */}
      <InstallmentCalculatorSection />

      {/* 6. Server-Rendered Architectural Prestige Features */}
      <WhyChooseUs />

      {/* 7. Client Island: Consultation & Private Investment Request */}
      <HomeConsultationSection />

      {/* 8. Server-Rendered Footer */}
      <HomeFooter />

      {/* 9. Mobile Only Floating Bottom Action Bar */}
      <MobileFloatingBar />
    </div>
  );
}
