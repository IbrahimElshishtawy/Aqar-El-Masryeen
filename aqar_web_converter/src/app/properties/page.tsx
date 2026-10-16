'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import {
  Building2,
  Plus,
  MapPin,
  TrendingUp,
  DollarSign,
  Layers,
  Search,
  CheckCircle2,
  X
} from 'lucide-react';
import AppShell from '@/components/layout/AppShell';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { initialProjects } from '@/services/store';
import { PropertyProject, PropertyStatus } from '@/types';

export default function PropertiesPage() {
  const [projects, setProjects] = useState<PropertyProject[]>(initialProjects);
  const [filter, setFilter] = useState<string>('all');
  const [search, setSearch] = useState('');
  const [showAddModal, setShowAddModal] = useState(false);

  // New property form state
  const [name, setName] = useState('');
  const [location, setLocation] = useState('');
  const [apartmentCount, setApartmentCount] = useState(20);
  const [totalBudget, setTotalBudget] = useState(15000000);
  const [totalSalesTarget, setTotalSalesTarget] = useState(25000000);
  const [description, setDescription] = useState('');

  const filtered = projects.filter(p => {
    const matchesFilter = filter === 'all' || p.status === filter;
    const matchesSearch = p.name.includes(search) || p.location.includes(search);
    return matchesFilter && matchesSearch;
  });

  const handleCreateProject = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !location) return;

    const newProject: PropertyProject = {
      id: `prop-${Date.now()}`,
      name,
      location,
      apartmentCount: Number(apartmentCount),
      description,
      status: PropertyStatus.Active,
      totalBudget: Number(totalBudget),
      totalSalesTarget: Number(totalSalesTarget),
      createdAt: new Date().toISOString().split('T')[0],
      updatedAt: new Date().toISOString().split('T')[0],
      createdBy: 'admin',
      workspaceId: 'main-ws',
      archived: false,
    };

    setProjects([newProject, ...projects]);
    setShowAddModal(false);
    setName('');
    setLocation('');
    setDescription('');
  };

  return (
    <AppShell
      title="المشروعات والعقارات"
      subtitle="إدارة وتتبع المشروعات السكنية والتجارية ومخططات المبيعات المحاسبية"
      actions={
        <button
          onClick={() => setShowAddModal(true)}
          className="px-4 py-2.5 rounded-xl bg-[#242424] hover:bg-[#1A1A1A] text-white font-bold text-xs flex items-center gap-2 shadow-sm transition active:scale-95"
        >
          <Plus className="w-4 h-4 text-[#A89F91]" />
          <span>إضافة مشروع جديد</span>
        </button>
      }
    >
      <div className="space-y-6">
        {/* Controls Bar */}
        <div className="flex flex-col sm:flex-row items-center justify-between gap-4 p-4 rounded-2xl bg-[#FFFFFF] border border-[#E2DFD8] shadow-sm">
          <div className="relative w-full sm:w-80">
            <Search className="w-4 h-4 text-[#777777] absolute right-3 top-3" />
            <input
              type="text"
              placeholder="بحث باسم المشروع أو الموقع..."
              value={search}
              onChange={e => setSearch(e.target.value)}
              className="w-full pl-3 pr-9 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] placeholder-[#777777] focus:outline-none focus:border-[#242424]"
            />
          </div>

          <div className="flex items-center gap-2 overflow-x-auto w-full sm:w-auto pb-1 sm:pb-0">
            {[
              { id: 'all', label: 'كافة المشروعات' },
              { id: PropertyStatus.Active, label: 'نشط' },
              { id: PropertyStatus.Planning, label: 'تحت الإنشاء' },
              { id: PropertyStatus.Delivered, label: 'تم التسليم' },
            ].map(tab => (
              <button
                key={tab.id}
                onClick={() => setFilter(tab.id)}
                className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold shrink-0 transition border ${
                  filter === tab.id
                    ? 'bg-[#242424] text-white border-[#242424]'
                    : 'bg-[#F4F4F2] text-[#777777] border-[#E2DFD8] hover:text-[#242424]'
                }`}
              >
                {tab.label}
              </button>
            ))}
          </div>
        </div>

        {/* Projects Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filtered.map(project => (
            <div
              key={project.id}
              className="rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] hover:border-[#A89F91]/50 p-6 flex flex-col justify-between transition-all duration-300 shadow-sm hover:shadow-xl group"
            >
              <div>
                <div className="flex items-start justify-between gap-2 mb-4">
                  <div className="w-12 h-12 rounded-2xl bg-[#242424] text-white flex items-center justify-center font-bold">
                    <Building2 className="w-6 h-6 text-[#A89F91]" />
                  </div>
                  <StatusBadge status={project.status} type="property" />
                </div>

                <h3 className="font-editorial text-lg font-bold text-[#242424] group-hover:text-[#A89F91] transition mb-1">
                  {project.name}
                </h3>
                <div className="flex items-center gap-1.5 text-xs text-[#777777] mb-3">
                  <MapPin className="w-3.5 h-3.5 text-[#A89F91] shrink-0" />
                  <span className="truncate">{project.location}</span>
                </div>
                <p className="text-xs text-[#777777] line-clamp-2 mb-6">
                  {project.description}
                </p>

                {/* Specs Box */}
                <div className="grid grid-cols-2 gap-2 p-3 rounded-2xl bg-[#F4F4F2] border border-[#E2DFD8] text-xs mb-6">
                  <div>
                    <span className="text-[10px] text-[#777777] block">إجمالي الوحدات</span>
                    <strong className="text-[#242424] font-bold">{project.apartmentCount} وحدة</strong>
                  </div>
                  <div>
                    <span className="text-[10px] text-[#777777] block">المبيعات المستهدفة</span>
                    <strong className="text-[#242424] font-mono font-bold">
                      {(project.totalSalesTarget / 1000000).toFixed(1)} مليون ج.م
                    </strong>
                  </div>
                </div>
              </div>

              <div className="pt-4 border-t border-[#E2DFD8] flex items-center justify-between">
                <div>
                  <span className="text-[10px] text-[#777777] block">ميزانية المشروع</span>
                  <span className="text-xs font-mono font-bold text-[#242424]">
                    {project.totalBudget.toLocaleString()} ج.م
                  </span>
                </div>

                <Link
                  href={`/properties/${project.id}`}
                  className="px-4 py-2 rounded-xl bg-[#242424] hover:bg-[#1A1A1A] text-white font-bold text-xs transition flex items-center gap-1"
                >
                  <span>عرض التفاصيل والوحدات</span>
                </Link>
              </div>
            </div>
          ))}
        </div>

        {/* Add Project Modal */}
        {showAddModal && (
          <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
            <div className="w-full max-w-lg rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] p-6 space-y-4 shadow-2xl text-[#242424]">
              <div className="flex items-center justify-between pb-3 border-b border-[#E2DFD8]">
                <h3 className="font-editorial text-base font-bold text-[#242424] flex items-center gap-2">
                  <Building2 className="w-5 h-5 text-[#A89F91]" />
                  <span>إضافة مشروع عقاري جديد</span>
                </h3>
                <button onClick={() => setShowAddModal(false)} className="text-[#777777] hover:text-[#242424]">
                  <X className="w-5 h-5" />
                </button>
              </div>

              <form onSubmit={handleCreateProject} className="space-y-4 text-xs">
                <div>
                  <label className="block text-[#242424] font-bold mb-1">اسم المشروع</label>
                  <input
                    type="text"
                    required
                    placeholder="مثال: برج الفيروز ريزيدنس"
                    value={name}
                    onChange={e => setName(e.target.value)}
                    className="w-full px-3 py-2.5 rounded-xl bg-[#F4F4F2] border border-[#E2DFD8] text-[#242424] focus:outline-none focus:border-[#242424]"
                  />
                </div>

                <div>
                  <label className="block text-[#242424] font-bold mb-1">الموقع / العنوان</label>
                  <input
                    type="text"
                    required
                    placeholder="مثال: الحي الأول - أكتوبر"
                    value={location}
                    onChange={e => setLocation(e.target.value)}
                    className="w-full px-3 py-2.5 rounded-xl bg-[#F4F4F2] border border-[#E2DFD8] text-[#242424] focus:outline-none focus:border-[#242424]"
                  />
                </div>

                <div className="grid grid-cols-3 gap-3">
                  <div>
                    <label className="block text-[#242424] font-bold mb-1">عدد الوحدات</label>
                    <input
                      type="number"
                      required
                      value={apartmentCount}
                      onChange={e => setApartmentCount(Number(e.target.value))}
                      className="w-full px-3 py-2.5 rounded-xl bg-[#F4F4F2] border border-[#E2DFD8] text-[#242424] focus:outline-none focus:border-[#242424]"
                    />
                  </div>
                  <div>
                    <label className="block text-[#242424] font-bold mb-1">الميزانية التقديرية</label>
                    <input
                      type="number"
                      required
                      value={totalBudget}
                      onChange={e => setTotalBudget(Number(e.target.value))}
                      className="w-full px-3 py-2.5 rounded-xl bg-[#F4F4F2] border border-[#E2DFD8] text-[#242424] focus:outline-none focus:border-[#242424] font-mono"
                    />
                  </div>
                  <div>
                    <label className="block text-[#242424] font-bold mb-1">المبيعات المستهدفة</label>
                    <input
                      type="number"
                      required
                      value={totalSalesTarget}
                      onChange={e => setTotalSalesTarget(Number(e.target.value))}
                      className="w-full px-3 py-2.5 rounded-xl bg-[#F4F4F2] border border-[#E2DFD8] text-[#242424] focus:outline-none focus:border-[#242424] font-mono"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-[#242424] font-bold mb-1">وصف المشروع</label>
                  <textarea
                    rows={3}
                    placeholder="تفاصيل المشروع ومراحل التنفيذ..."
                    value={description}
                    onChange={e => setDescription(e.target.value)}
                    className="w-full px-3 py-2.5 rounded-xl bg-[#F4F4F2] border border-[#E2DFD8] text-[#242424] focus:outline-none focus:border-[#242424]"
                  />
                </div>

                <div className="flex items-center justify-end gap-3 pt-3 border-t border-[#E2DFD8]">
                  <button
                    type="button"
                    onClick={() => setShowAddModal(false)}
                    className="px-4 py-2 rounded-xl text-[#777777] hover:text-[#242424]"
                  >
                    إلغاء
                  </button>
                  <button
                    type="submit"
                    className="px-5 py-2.5 rounded-xl bg-[#242424] hover:bg-[#1A1A1A] text-white font-bold transition shadow-sm"
                  >
                    حفظ المشروع
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </div>
    </AppShell>
  );
}
