'use client';

import React, { useState, useMemo } from 'react';
import Link from 'next/link';
import {
  Building2,
  Search,
  MapPin,
  Layers,
  ArrowUpRight,
  TrendingUp,
  Award
} from 'lucide-react';
import { PropertyProject } from '@/types';

interface ProjectExplorerProps {
  projects: PropertyProject[];
}

export function ProjectExplorer({ projects }: ProjectExplorerProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedLocation, setSelectedLocation] = useState('all');

  const filteredProjects = useMemo(() => {
    return projects.filter(p => {
      const matchSearch = p.name.includes(searchTerm) || p.location.includes(searchTerm);
      const matchLocation = selectedLocation === 'all' || p.location.includes(selectedLocation);
      return matchSearch && matchLocation;
    });
  }, [projects, searchTerm, selectedLocation]);

  return (
    <section id="projects" className="py-16 sm:py-24 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      {/* Section Header */}
      <div className="flex flex-col md:flex-row md:items-end justify-between mb-8 sm:mb-12 gap-4">
        <div>
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#EBE8E1] text-[#777777] text-xs font-bold mb-3">
            <Building2 className="w-3.5 h-3.5 text-[#A89F91]" />
            <span>المشروعات المعمارية القائمة</span>
          </div>
          <h2 className="font-editorial text-2xl sm:text-4xl font-black text-[#242424]">
            صروح معمارية تليق باستثمارك
          </h2>
          <p className="text-xs sm:text-sm text-[#777777] mt-2 max-w-xl">
            تصفح مشروعاتنا العقارية في أفضل المواقع الاستثمارية، مصممة بأعلى معايير الهندسة المعمارية مع جداول سداد مرنة.
          </p>
        </div>

        <span className="text-xs font-semibold text-[#777777] bg-[#FFFFFF] px-3.5 py-1.5 rounded-full border border-[#E2DFD8] self-start md:self-auto">
          عرض {filteredProjects.length} من أصل {projects.length} مشروعات
        </span>
      </div>

      {/* Filter and Search Bar */}
      <div className="mb-8 p-3 sm:p-4 rounded-2xl bg-[#FFFFFF] border border-[#E2DFD8] shadow-sm">
        <div className="grid grid-cols-1 sm:grid-cols-12 gap-3 items-center">
          {/* Search query input */}
          <div className="sm:col-span-8 relative">
            <div className="absolute inset-y-0 right-0 pr-3.5 flex items-center pointer-events-none text-[#777777]">
              <Search className="w-4 h-4" />
            </div>
            <input
              type="text"
              value={searchTerm}
              onChange={e => setSearchTerm(e.target.value)}
              placeholder="ابحث باسم المشروع، الحي، أو المنطقة..."
              className="w-full pr-10 pl-4 py-2.5 sm:py-3 rounded-xl bg-[#F4F4F2] border border-[#E2DFD8] text-xs font-semibold text-[#242424] placeholder-[#777777] focus:outline-none focus:border-[#242424] transition"
            />
          </div>

          {/* Location Select */}
          <div className="sm:col-span-4">
            <select
              value={selectedLocation}
              onChange={e => setSelectedLocation(e.target.value)}
              className="w-full px-3.5 py-2.5 sm:py-3 rounded-xl bg-[#F4F4F2] border border-[#E2DFD8] text-xs font-semibold text-[#242424] focus:outline-none focus:border-[#242424] transition appearance-none cursor-pointer"
            >
              <option value="all">كل المواقع الجغرافية</option>
              <option value="التجمع الخامس">التجمع الخامس</option>
              <option value="المعادي">كورنيش المعادي</option>
              <option value="الشيخ زايد">الشيخ زايد</option>
            </select>
          </div>
        </div>
      </div>

      {/* Projects Grid: Responsive Desktop & Mobile layout */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 sm:gap-8">
        {filteredProjects.map((project, idx) => (
          <div
            key={project.id}
            className="group rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] overflow-hidden shadow-sm hover:shadow-xl hover:border-[#A89F91] transition-all duration-300 flex flex-col justify-between"
          >
            {/* Top Visual Card */}
            <div>
              <div className="h-44 sm:h-52 bg-[#242424] p-5 sm:p-6 text-white relative flex flex-col justify-between overflow-hidden">
                <div
                  className="absolute inset-0 opacity-10 bg-repeat pointer-events-none"
                  style={{
                    backgroundImage: `radial-gradient(#A89F91 1px, transparent 1px)`,
                    backgroundSize: '16px 16px',
                  }}
                />

                <div className="flex items-center justify-between relative z-10">
                  <span className="px-3 py-1 rounded-full text-[10px] font-bold bg-[#1A1A1A] text-[#A89F91] border border-[#A89F91]/30">
                    {idx === 0 ? 'المشروع النموذجي' : 'فرصة استثمارية'}
                  </span>
                  <span className="text-xs font-mono font-bold text-[#A89F91]">
                    {project.apartmentCount} وحدة
                  </span>
                </div>

                <div className="relative z-10">
                  <h3 className="font-editorial text-xl sm:text-2xl font-bold tracking-tight text-[#F4F4F2] group-hover:text-[#A89F91] transition">
                    {project.name}
                  </h3>
                  <div className="flex items-center gap-1.5 text-xs text-[#777777] mt-1.5">
                    <MapPin className="w-3.5 h-3.5 text-[#A89F91]" />
                    <span>{project.location}</span>
                  </div>
                </div>
              </div>

              {/* Card Body & Specs */}
              <div className="p-5 sm:p-6 space-y-4">
                <p className="text-xs text-[#777777] line-clamp-2 leading-relaxed">
                  {project.description}
                </p>

                <div className="grid grid-cols-2 gap-2.5 pt-3 border-t border-[#E2DFD8]">
                  <div className="p-2.5 rounded-xl bg-[#F4F4F2]">
                    <span className="text-[10px] text-[#777777] block font-semibold">مستهدف المبيعات</span>
                    <span className="text-xs sm:text-sm font-bold text-[#242424] font-mono mt-0.5 block">
                      {(project.totalSalesTarget / 1000000).toFixed(0)} مليون ج.م
                    </span>
                  </div>
                  <div className="p-2.5 rounded-xl bg-[#F4F4F2]">
                    <span className="text-[10px] text-[#777777] block font-semibold">حالة المشروع</span>
                    <span className="text-xs sm:text-sm font-bold text-[#242424] mt-0.5 block">
                      {project.status === 'active' ? 'قيد الإنشاء والبيع' : 'دراسة وتخطيط'}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            {/* Action Footer */}
            <div className="p-5 sm:p-6 pt-0">
              <Link
                href={`/properties/${project.id}`}
                className="w-full py-3 rounded-xl bg-[#F4F4F2] group-hover:bg-[#242424] group-hover:text-white text-[#242424] font-bold text-xs flex items-center justify-center gap-2 border border-[#E2DFD8] group-hover:border-[#242424] transition duration-200"
              >
                <span>تفاصيل المشروع والوحدات</span>
                <ArrowUpRight className="w-4 h-4 text-[#A89F91]" />
              </Link>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
