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
  ArrowUpRight,
  Plus,
} from 'lucide-react';
import AppShell from '@/components/layout/AppShell';
import MetricCard from '@/components/ui/MetricCard';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { initialProjects, initialUnits, initialInstallments, initialExpenses } from '@/services/store';

export default function DashboardPage() {
  const [projects] = useState(initialProjects);
  const [installments] = useState(initialInstallments);
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
      title="لوحة المؤشرات المحاسبية العامة"
      subtitle="ملخص مالي وإداري شامل لكافة المشروعات، التحصيلات، دفاتر المصروفات، وأقساط العملاء"
      actions={
        <div className="flex items-center gap-2">
          <Link
            href="/properties"
            className="px-4 py-2.5 rounded-xl bg-[#242424] hover:bg-[#1A1A1A] text-white font-bold text-xs flex items-center gap-2 shadow-sm transition active:scale-95"
          >
            <Plus className="w-4 h-4 text-[#A89F91]" />
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
            trend="↑ +18% نمو المبيعات"
            subtext="موزعة على 3 مشروعات نشطة"
          />

          <MetricCard
            label="إجمالي التحصيلات النقدية"
            value={`${(totalCollected / 1000000).toFixed(2)} مليون ج.م`}
            icon={DollarSign}
            subtext="مقدمات تعاقد وأقساط مسددة"
          />

          <MetricCard
            label="الأقساط المتأخرة والمستحقة"
            value={`${overdueCount} أقساط`}
            icon={Calendar}
            subtext="تحتاج إلى متابعة تحصيل عاجلة"
          />

          <MetricCard
            label="إجمالي المصروفات المنفذة"
            value={`${(totalExpenseAmount / 1000000).toFixed(2)} مليون ج.م`}
            icon={Receipt}
            subtext="إنشاءات وتشوينات ومواد بناء"
          />
        </section>

        {/* Quick Links Banner */}
        <section className="p-6 rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="font-editorial text-base font-bold text-[#242424]">روابط سريعة للأقسام المحاسبية الأساسية</h3>
              <p className="text-xs text-[#777777] mt-0.5">انتقل مباشرة لإدارة جداول الأقساط أو تسجيل التشوينات أو حسابات الشركاء</p>
            </div>
          </div>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
            <Link
              href="/properties"
              className="p-4 rounded-2xl bg-[#F4F4F2] hover:bg-[#EBE8E1] border border-[#E2DFD8] text-right transition flex items-center justify-between group"
            >
              <div>
                <Building2 className="w-5 h-5 text-[#242424] mb-2 group-hover:scale-110 transition" />
                <span className="text-xs font-bold text-[#242424] block">المشروعات</span>
                <span className="text-[10px] text-[#777777]">3 مشاريع قيد العمل</span>
              </div>
              <ArrowUpRight className="w-4 h-4 text-[#777777] group-hover:text-[#242424] transition" />
            </Link>

            <Link
              href="/installments"
              className="p-4 rounded-2xl bg-[#F4F4F2] hover:bg-[#EBE8E1] border border-[#E2DFD8] text-right transition flex items-center justify-between group"
            >
              <div>
                <Calendar className="w-5 h-5 text-[#242424] mb-2 group-hover:scale-110 transition" />
                <span className="text-xs font-bold text-[#242424] block">جدول الأقساط</span>
                <span className="text-[10px] text-[#777777]">توليد ومتابعة التحصيل</span>
              </div>
              <ArrowUpRight className="w-4 h-4 text-[#777777] group-hover:text-[#242424] transition" />
            </Link>

            <Link
              href="/expenses"
              className="p-4 rounded-2xl bg-[#F4F4F2] hover:bg-[#EBE8E1] border border-[#E2DFD8] text-right transition flex items-center justify-between group"
            >
              <div>
                <Receipt className="w-5 h-5 text-[#242424] mb-2 group-hover:scale-110 transition" />
                <span className="text-xs font-bold text-[#242424] block">دفتر المصروفات</span>
                <span className="text-[10px] text-[#777777]">حديد، أسمنت، مقاولين</span>
              </div>
              <ArrowUpRight className="w-4 h-4 text-[#777777] group-hover:text-[#242424] transition" />
            </Link>

            <Link
              href="/partners"
              className="p-4 rounded-2xl bg-[#F4F4F2] hover:bg-[#EBE8E1] border border-[#E2DFD8] text-right transition flex items-center justify-between group"
            >
              <div>
                <Users className="w-5 h-5 text-[#242424] mb-2 group-hover:scale-110 transition" />
                <span className="text-xs font-bold text-[#242424] block">تسويات الشركاء</span>
                <span className="text-[10px] text-[#777777]">حصص ونسب رأس المال</span>
              </div>
              <ArrowUpRight className="w-4 h-4 text-[#777777] group-hover:text-[#242424] transition" />
            </Link>
          </div>
        </section>

        {/* 2-Column Section: Active Projects & Overdue Installments */}
        <section className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Projects Overview */}
          <div className="lg:col-span-2 p-6 rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] shadow-sm space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="font-editorial text-base font-bold text-[#242424]">المشروعات الحالية</h3>
                <p className="text-xs text-[#777777]">متابعة نسب التنفيذ والمبيعات لكل مشروع</p>
              </div>
              <Link href="/properties" className="text-xs font-bold text-[#242424] hover:text-[#777777] transition">
                عرض كافة المشروعات ←
              </Link>
            </div>

            <div className="space-y-3">
              {projects.map(project => (
                <Link
                  key={project.id}
                  href={`/properties/${project.id}`}
                  className="p-4 rounded-2xl bg-[#F4F4F2] hover:bg-[#EBE8E1] border border-[#E2DFD8] flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 transition group"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-[#242424] text-white flex items-center justify-center font-bold">
                      <Building2 className="w-5 h-5 text-[#A89F91]" />
                    </div>
                    <div>
                      <h4 className="text-sm font-bold text-[#242424] group-hover:text-[#A89F91] transition">{project.name}</h4>
                      <p className="text-xs text-[#777777]">{project.location}</p>
                    </div>
                  </div>

                  <div className="flex items-center gap-6 w-full sm:w-auto justify-between sm:justify-end">
                    <div className="text-left sm:text-right">
                      <span className="text-[11px] text-[#777777] block">إجمالي الوحدات: {project.apartmentCount} وحدة</span>
                      <span className="text-xs font-mono font-bold text-[#242424]">
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
          <div className="p-6 rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] shadow-sm space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="font-editorial text-base font-bold text-[#242424]">تنبيهات الأقساط</h3>
                <p className="text-xs text-[#777777]">الأقساط المستحقة والمتأخرة</p>
              </div>
              <Link href="/installments" className="text-xs font-bold text-[#242424] hover:text-[#777777] transition">
                الكل ←
              </Link>
            </div>

            <div className="space-y-3">
              {installments.slice(0, 4).map(inst => (
                <div
                  key={inst.id}
                  className="p-3.5 rounded-2xl bg-[#F4F4F2] border border-[#E2DFD8] flex items-center justify-between gap-2"
                >
                  <div>
                    <h5 className="text-xs font-bold text-[#242424]">{inst.customerName}</h5>
                    <p className="text-[10px] text-[#777777] mt-0.5">
                      القسط #{inst.sequence} - تاريخ الاستحقاق: {inst.dueDate}
                    </p>
                  </div>
                  <div className="text-left shrink-0">
                    <span className="text-xs font-mono font-bold text-[#242424] block">
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
