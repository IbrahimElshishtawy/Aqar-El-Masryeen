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
      subtitle="إدارة وتتبع المشروعات السكنية والتجارية ومخططات المبيعات"
      actions={
        <button
          onClick={() => setShowAddModal(true)}
          className="px-4 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-500 text-white font-bold text-xs flex items-center gap-2 shadow-lg shadow-blue-600/25 transition active:scale-95"
        >
          <Plus className="w-4 h-4" />
          <span>إضافة مشروع جديد</span>
        </button>
      }
    >
      <div className="space-y-6">
        {/* Controls Bar */}
        <div className="flex flex-col sm:flex-row items-center justify-between gap-4 p-4 rounded-2xl bg-slate-900/60 border border-slate-800">
          <div className="relative w-full sm:w-80">
            <Search className="w-4 h-4 text-slate-500 absolute right-3 top-3" />
            <input
              type="text"
              placeholder="بحث باسم المشروع أو الموقع..."
              value={search}
              onChange={e => setSearch(e.target.value)}
              className="w-full pl-3 pr-9 py-2 bg-slate-800/80 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-blue-500"
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
                className={`px-3 py-1.5 rounded-xl text-xs font-semibold shrink-0 transition ${
                  filter === tab.id
                    ? 'bg-blue-600 text-white'
                    : 'bg-slate-800 text-slate-400 hover:text-white'
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
              className="rounded-3xl bg-slate-900/80 border border-slate-800 hover:border-slate-700/80 p-6 flex flex-col justify-between transition-all duration-300 hover:shadow-xl group"
            >
              <div>
                <div className="flex items-start justify-between gap-2 mb-4">
                  <div className="w-12 h-12 rounded-2xl bg-blue-600/10 text-blue-400 flex items-center justify-center font-bold">
                    <Building2 className="w-6 h-6" />
                  </div>
                  <StatusBadge status={project.status} type="property" />
                </div>

                <h3 className="text-lg font-bold text-white group-hover:text-blue-400 transition mb-1">
                  {project.name}
                </h3>
                <div className="flex items-center gap-1.5 text-xs text-slate-400 mb-3">
                  <MapPin className="w-3.5 h-3.5 text-rose-400 shrink-0" />
                  <span className="truncate">{project.location}</span>
                </div>
                <p className="text-xs text-slate-400 line-clamp-2 mb-6">
                  {project.description}
                </p>

                {/* Specs Box */}
                <div className="grid grid-cols-2 gap-2 p-3 rounded-2xl bg-slate-800/50 border border-slate-700/50 text-xs mb-6">
                  <div>
                    <span className="text-[10px] text-slate-400 block">إجمالي الوحدات</span>
                    <strong className="text-slate-100 font-bold">{project.apartmentCount} وحدة</strong>
                  </div>
                  <div>
                    <span className="text-[10px] text-slate-400 block">المبيعات المستهدفة</span>
                    <strong className="text-emerald-400 font-mono font-bold">
                      {(project.totalSalesTarget / 1000000).toFixed(1)} مليون ج.م
                    </strong>
                  </div>
                </div>
              </div>

              <div className="pt-4 border-t border-slate-800/80 flex items-center justify-between">
                <div>
                  <span className="text-[10px] text-slate-500 block">ميزانية المشروع</span>
                  <span className="text-xs font-mono font-bold text-slate-300">
                    {project.totalBudget.toLocaleString()} ج.م
                  </span>
                </div>

                <Link
                  href={`/properties/${project.id}`}
                  className="px-4 py-2 rounded-xl bg-slate-800 hover:bg-blue-600 text-white font-bold text-xs transition flex items-center gap-1"
                >
                  <span>عرض التفاصيل والوحدات</span>
                </Link>
              </div>
            </div>
          ))}
        </div>

        {/* Add Project Modal */}
        {showAddModal && (
          <div className="fixed inset-0 bg-black/75 backdrop-blur-sm z-50 flex items-center justify-center p-4">
            <div className="w-full max-w-lg rounded-3xl bg-slate-900 border border-slate-800 p-6 space-y-4">
              <div className="flex items-center justify-between pb-3 border-b border-slate-800">
                <h3 className="text-base font-bold text-white flex items-center gap-2">
                  <Building2 className="w-5 h-5 text-blue-400" />
                  إضافة مشروع عقاري جديد
                </h3>
                <button onClick={() => setShowAddModal(false)} className="text-slate-400 hover:text-white">
                  <X className="w-5 h-5" />
                </button>
              </div>

              <form onSubmit={handleCreateProject} className="space-y-4 text-xs">
                <div>
                  <label className="block text-slate-300 font-bold mb-1">اسم المشروع</label>
                  <input
                    type="text"
                    required
                    placeholder="مثال: برج الفيروز ريزيدنس"
                    value={name}
                    onChange={e => setName(e.target.value)}
                    className="w-full px-3 py-2.5 rounded-xl bg-slate-800 border border-slate-700 text-white focus:outline-none focus:border-blue-500"
                  />
                </div>

                <div>
                  <label className="block text-slate-300 font-bold mb-1">الموقع / العنوان</label>
                  <input
                    type="text"
                    required
                    placeholder="مثال: الحي الأول - أكتوبر"
                    value={location}
                    onChange={e => setLocation(e.target.value)}
                    className="w-full px-3 py-2.5 rounded-xl bg-slate-800 border border-slate-700 text-white focus:outline-none focus:border-blue-500"
                  />
                </div>

                <div className="grid grid-cols-3 gap-3">
                  <div>
                    <label className="block text-slate-300 font-bold mb-1">عدد الوحدات</label>
                    <input
                      type="number"
                      required
                      value={apartmentCount}
                      onChange={e => setApartmentCount(Number(e.target.value))}
                      className="w-full px-3 py-2.5 rounded-xl bg-slate-800 border border-slate-700 text-white focus:outline-none focus:border-blue-500"
                    />
                  </div>
                  <div>
                    <label className="block text-slate-300 font-bold mb-1">الميزانية التقديرية</label>
                    <input
                      type="number"
                      required
                      value={totalBudget}
                      onChange={e => setTotalBudget(Number(e.target.value))}
                      className="w-full px-3 py-2.5 rounded-xl bg-slate-800 border border-slate-700 text-white focus:outline-none focus:border-blue-500 font-mono"
                    />
                  </div>
                  <div>
                    <label className="block text-slate-300 font-bold mb-1">المبيعات المستهدفة</label>
                    <input
                      type="number"
                      required
                      value={totalSalesTarget}
                      onChange={e => setTotalSalesTarget(Number(e.target.value))}
                      className="w-full px-3 py-2.5 rounded-xl bg-slate-800 border border-slate-700 text-white focus:outline-none focus:border-blue-500 font-mono"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-slate-300 font-bold mb-1">وصف المشروع</label>
                  <textarea
                    rows={3}
                    placeholder="تفاصيل المشروع ومراحل التنفيذ..."
                    value={description}
                    onChange={e => setDescription(e.target.value)}
                    className="w-full px-3 py-2.5 rounded-xl bg-slate-800 border border-slate-700 text-white focus:outline-none focus:border-blue-500"
                  />
                </div>

                <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-800">
                  <button
                    type="button"
                    onClick={() => setShowAddModal(false)}
                    className="px-4 py-2 rounded-xl text-slate-400 hover:text-white"
                  >
                    إلغاء
                  </button>
                  <button
                    type="submit"
                    className="px-5 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-500 text-white font-bold transition"
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
