'use client';

import React from 'react';
import {
  BarChart3,
  TrendingUp,
  DollarSign,
  Receipt,
  Download,
  Printer,
  Building2,
  PieChart,
  ArrowUpRight
} from 'lucide-react';
import AppShell from '@/components/layout/AppShell';
import MetricCard from '@/components/ui/MetricCard';
import { initialProjects, initialUnits, initialExpenses, initialInstallments } from '@/services/store';

export default function ReportsPage() {
  const totalSalesTarget = initialProjects.reduce((acc, p) => acc + p.totalSalesTarget, 0);
  const totalBudget = initialProjects.reduce((acc, p) => acc + p.totalBudget, 0);

  const totalCollected = initialUnits
    .filter(u => u.status === 'sold')
    .reduce((acc, u) => acc + u.downPayment, 0) +
    initialInstallments.filter(i => i.status === 'paid').reduce((acc, i) => acc + i.paidAmount, 0);

  const totalExpenses = initialExpenses.reduce((acc, e) => acc + e.amount, 0);
  const netProfit = totalCollected - totalExpenses;
  const roi = totalBudget > 0 ? ((totalSalesTarget - totalBudget) / totalBudget) * 100 : 0;

  return (
    <AppShell
      title="التقارير المالية والتحليلات"
      subtitle="تحليل التدفقات النقدية، نسب الأرباح المحققة، والعائد الاستثماري للمشروعات"
      actions={
        <button
          onClick={() => window.print()}
          className="px-4 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-white font-bold text-xs flex items-center gap-2 border border-slate-700 transition"
        >
          <Printer className="w-4 h-4" />
          <span>طباعة التقرير</span>
        </button>
      }
    >
      <div className="space-y-8">
        {/* KPI Row */}
        <section className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <MetricCard
            label="إجمالي المبيعات التقديرية"
            value={`${(totalSalesTarget / 1000000).toFixed(1)}M ج.م`}
            icon={TrendingUp}
            color="blue"
            subtext="لجميع المشروعات المسجلة"
          />

          <MetricCard
            label="صافي النقد المحصل"
            value={`${(totalCollected / 1000000).toFixed(2)}M ج.م`}
            icon={DollarSign}
            color="emerald"
            subtext="مقدمات + أقساط محصلة"
          />

          <MetricCard
            label="إجمالي المصروفات المنفذة"
            value={`${(totalExpenses / 1000000).toFixed(2)}M ج.م`}
            icon={Receipt}
            color="amber"
            subtext="تشوينات، مقاولين، وتراخيص"
          />

          <MetricCard
            label="العائد الاستثماري المتوقع (ROI)"
            value={`${Math.round(roi)}%`}
            icon={PieChart}
            color="purple"
            subtext="بناءً على التكلفة والمبيعات"
          />
        </section>

        {/* Project By Project Breakdown */}
        <section className="rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] p-6 shadow-sm space-y-4">
          <h3 className="font-editorial text-base font-bold text-[#242424]">التقرير المالي والتحليلي لكل مشروع</h3>

          <div className="space-y-4">
            {initialProjects.map(project => {
              const projectSold = initialUnits.filter(u => u.propertyId === project.id && u.status === 'sold');
              const projectSales = projectSold.reduce((acc, u) => acc + u.salePrice, 0);
              const projectExp = initialExpenses.filter(e => e.propertyId === project.id).reduce((acc, e) => acc + e.amount, 0);
              const progressPct = project.totalSalesTarget > 0 ? Math.round((projectSales / project.totalSalesTarget) * 100) : 0;

              return (
                <div
                  key={project.id}
                  className="p-5 rounded-2xl bg-[#F4F4F2] border border-[#E2DFD8] space-y-3"
                >
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl bg-[#242424] text-white flex items-center justify-center font-bold">
                        <Building2 className="w-5 h-5 text-[#A89F91]" />
                      </div>
                      <div>
                        <h4 className="font-editorial text-sm font-bold text-[#242424]">{project.name}</h4>
                        <p className="text-xs text-[#777777]">{project.location}</p>
                      </div>
                    </div>

                    <div className="flex items-center gap-4 text-xs font-mono">
                      <div>
                        <span className="text-[10px] text-[#777777] block">المبيعات المحققة</span>
                        <strong className="text-[#242424] font-bold">{projectSales.toLocaleString()} ج.م</strong>
                      </div>
                      <div>
                        <span className="text-[10px] text-[#777777] block">المصروفات المنفذة</span>
                        <strong className="text-[#777777] font-bold">{projectExp.toLocaleString()} ج.م</strong>
                      </div>
                    </div>
                  </div>

                  {/* Progress bar */}
                  <div>
                    <div className="flex justify-between text-[11px] text-[#777777] mb-1">
                      <span>نسبة إنجاز المبيعات المستهدفة</span>
                      <span className="font-mono font-bold text-[#242424]">{progressPct}%</span>
                    </div>
                    <div className="w-full h-2.5 rounded-full bg-[#E2DFD8] overflow-hidden">
                      <div
                        className="h-full bg-[#242424] rounded-full transition-all duration-500"
                        style={{ width: `${Math.min(progressPct, 100)}%` }}
                      />
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </section>
      </div>
    </AppShell>
  );
}
