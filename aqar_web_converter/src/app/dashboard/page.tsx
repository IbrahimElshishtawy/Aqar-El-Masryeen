'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import {
  TrendingUp,
  DollarSign,
  Calendar,
  Building2,
  Receipt,
  Users,
  BarChart3,
  ArrowUpRight,
  Plus,
  AlertCircle,
  CheckCircle2,
  Sparkles,
} from 'lucide-react';
import AppShell from '@/components/layout/AppShell';
import MetricCard from '@/components/ui/MetricCard';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { initialProjects, initialUnits, initialInstallments, initialExpenses } from '@/services/store';

export default function DashboardPage() {
  const [projects] = useState(initialProjects);
  const [installments, setInstallments] = useState(initialInstallments);
  const [expenses] = useState(initialExpenses);

  // Calculations
  const totalSales = 72000000 + 55000000 + 29000000;
  const totalCollected = initialUnits
    .filter(u => u.status === 'sold')
    .reduce((acc, u) => acc + u.downPayment, 0) +
    installments.filter(i => i.status === 'paid').reduce((acc, i) => acc + i.paidAmount, 0);

  const totalExpenseAmount = expenses.reduce((acc, e) => acc + e.amount, 0);
  const overdueCount = installments.filter(i => i.status === 'overdue').length;

  return (
    <AppShell
      title="الرئيسية | لوحة المتابعة الشاملة"
      subtitle="ملخص مالي مشترك لكل المشاريع والتحصيلات والمصروفات والأقساط"
      actions={
        <div className="flex items-center gap-2">
          <Link
            href="/properties"
            className="px-4 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-500 text-white font-bold text-xs flex items-center gap-2 shadow-lg shadow-blue-600/25 transition active:scale-95"
          >
            <Plus className="w-4 h-4" />
            <span>مشروع جديد</span>
          </Link>
        </div>
      }
    >
      <div className="space-y-8">
        {/* KPI Metric Cards Row */}
        <section className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <MetricCard
            label="إجمالي القيمة البيعية للمشروعات"
            value={`${(totalSales / 1000000).toFixed(1)} مليون ج.م`}
            icon={TrendingUp}
            color="blue"
            trend="↑ +18% نمو المبيعات"
            subtext="موزعة على 3 مشروعات نشطة"
          />

          <MetricCard
            label="إجمالي التحصيلات النقدية"
            value={`${(totalCollected / 1000000).toFixed(2)} مليون ج.م`}
            icon={DollarSign}
            color="emerald"
            subtext="مقدمات تعاقد وأقساط مسددة"
          />

          <MetricCard
            label="الأقساط المتأخرة والمستحقة"
            value={`${overdueCount} أقساط`}
            icon={Calendar}
            color="rose"
            subtext="تحتاج إلى متابعة تحصيل عاجلة"
          />

          <MetricCard
            label="إجمالي المصروفات المنفذة"
            value={`${(totalExpenseAmount / 1000000).toFixed(2)} مليون ج.م`}
            icon={Receipt}
            color="amber"
            subtext="إنشاءات وتشوينات ومواد بناء"
          />
        </section>

        {/* Quick Links Banner */}
        <section className="p-6 rounded-3xl bg-slate-900/80 border border-slate-800 shadow-lg">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="text-base font-bold text-white">روابط سريعة للأقسام الأساسية</h3>
              <p className="text-xs text-slate-400 mt-0.5">انتقل مباشرة لإدارة الأقساط أو تسجيل التشوينات أو حساب الشركاء</p>
            </div>
          </div>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
            <Link
              href="/properties"
              className="p-4 rounded-2xl bg-slate-800/60 hover:bg-slate-800 border border-slate-700/60 text-right transition flex items-center justify-between group"
            >
              <div>
                <Building2 className="w-5 h-5 text-blue-400 mb-2 group-hover:scale-110 transition" />
                <span className="text-xs font-bold text-white block">المشروعات</span>
                <span className="text-[10px] text-slate-400">3 مشاريع قيد العمل</span>
              </div>
              <ArrowUpRight className="w-4 h-4 text-slate-500 group-hover:text-blue-400 transition" />
            </Link>

            <Link
              href="/installments"
              className="p-4 rounded-2xl bg-slate-800/60 hover:bg-slate-800 border border-slate-700/60 text-right transition flex items-center justify-between group"
            >
              <div>
                <Calendar className="w-5 h-5 text-emerald-400 mb-2 group-hover:scale-110 transition" />
                <span className="text-xs font-bold text-white block">جدول الأقساط</span>
                <span className="text-[10px] text-slate-400">توليد ومتابعة التحصيل</span>
              </div>
              <ArrowUpRight className="w-4 h-4 text-slate-500 group-hover:text-emerald-400 transition" />
            </Link>

            <Link
              href="/expenses"
              className="p-4 rounded-2xl bg-slate-800/60 hover:bg-slate-800 border border-slate-700/60 text-right transition flex items-center justify-between group"
            >
              <div>
                <Receipt className="w-5 h-5 text-amber-400 mb-2 group-hover:scale-110 transition" />
                <span className="text-xs font-bold text-white block">دفتر المصروفات</span>
                <span className="text-[10px] text-slate-400">حديد، أسمنت، مقاولين</span>
              </div>
              <ArrowUpRight className="w-4 h-4 text-slate-500 group-hover:text-amber-400 transition" />
            </Link>

            <Link
              href="/partners"
              className="p-4 rounded-2xl bg-slate-800/60 hover:bg-slate-800 border border-slate-700/60 text-right transition flex items-center justify-between group"
            >
              <div>
                <Users className="w-5 h-5 text-purple-400 mb-2 group-hover:scale-110 transition" />
                <span className="text-xs font-bold text-white block">تسويات الشركاء</span>
                <span className="text-[10px] text-slate-400">حصص ونسب رأس المال</span>
              </div>
              <ArrowUpRight className="w-4 h-4 text-slate-500 group-hover:text-purple-400 transition" />
            </Link>
          </div>
        </section>

        {/* 2-Column Section: Active Projects & Overdue Installments */}
        <section className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Projects Overview */}
          <div className="lg:col-span-2 p-6 rounded-3xl bg-slate-900/80 border border-slate-800 shadow-lg space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-base font-bold text-white">المشروعات الحالية</h3>
                <p className="text-xs text-slate-400">متابعة نسب التنفيذ والمبيعات لكل مشروع</p>
              </div>
              <Link href="/properties" className="text-xs font-semibold text-blue-400 hover:text-blue-300">
                عرض كافة المشروعات ←
              </Link>
            </div>

            <div className="space-y-3">
              {projects.map(project => (
                <Link
                  key={project.id}
                  href={`/properties/${project.id}`}
                  className="p-4 rounded-2xl bg-slate-800/40 hover:bg-slate-800/80 border border-slate-700/60 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 transition group"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-blue-600/10 text-blue-400 flex items-center justify-center font-bold">
                      <Building2 className="w-5 h-5" />
                    </div>
                    <div>
                      <h4 className="text-sm font-bold text-white group-hover:text-blue-400 transition">{project.name}</h4>
                      <p className="text-xs text-slate-400">{project.location}</p>
                    </div>
                  </div>

                  <div className="flex items-center gap-6 w-full sm:w-auto justify-between sm:justify-end">
                    <div className="text-left sm:text-right">
                      <span className="text-[11px] text-slate-400 block">إجمالي الوحدات: {project.apartmentCount} وحدة</span>
                      <span className="text-xs font-mono font-bold text-emerald-400">
                        {(project.totalSalesTarget / 1000000).toFixed(1)}M ج.م
                      </span>
                    </div>
                    <StatusBadge status={project.status} type="property" />
                  </div>
                </Link>
              ))}
            </div>
          </div>

          {/* Due & Overdue Installments Feed */}
          <div className="p-6 rounded-3xl bg-slate-900/80 border border-slate-800 shadow-lg space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-base font-bold text-white">تنبيهات الأقساط</h3>
                <p className="text-xs text-slate-400">الأقساط المستحقة والمتأخرة</p>
              </div>
              <Link href="/installments" className="text-xs font-semibold text-blue-400 hover:text-blue-300">
                الكل ←
              </Link>
            </div>

            <div className="space-y-3">
              {installments.slice(0, 4).map(inst => (
                <div
                  key={inst.id}
                  className="p-3.5 rounded-2xl bg-slate-800/40 border border-slate-700/60 flex items-center justify-between gap-2"
                >
                  <div>
                    <h5 className="text-xs font-bold text-white">{inst.customerName}</h5>
                    <p className="text-[10px] text-slate-400 mt-0.5">
                      القسط #{inst.sequence} - تاريخ الاستحقاق: {inst.dueDate}
                    </p>
                  </div>
                  <div className="text-left shrink-0">
                    <span className="text-xs font-mono font-bold text-white block">
                      {inst.amount.toLocaleString()} ج.م
                    </span>
                    <StatusBadge status={inst.status} type="installment" />
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>
      </div>
    </AppShell>
  );
}
