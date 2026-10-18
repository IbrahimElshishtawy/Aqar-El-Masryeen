'use client';

import React, { useState, useEffect } from 'react';
import {
  BarChart3,
  TrendingUp,
  DollarSign,
  Receipt,
  Download,
  Printer,
  Building2,
  PieChart,
  ArrowUpRight,
  Filter,
  Calendar,
  Scale,
  CheckCircle2,
} from 'lucide-react';
import AppShell from '@/components/layout/AppShell';
import MetricCard from '@/components/ui/MetricCard';
import { CompanyReconciliation } from '@/lib/accounting/engine';
import { PropertyProject, UnitSale, ExpenseRecord, Installment } from '@/types';

export default function ReportsPage() {
  const [reconciliation, setReconciliation] = useState<CompanyReconciliation | null>(null);
  const [projects, setProjects] = useState<PropertyProject[]>([]);
  const [units, setUnits] = useState<UnitSale[]>([]);
  const [expenses, setExpenses] = useState<ExpenseRecord[]>([]);
  const [installments, setInstallments] = useState<Installment[]>([]);
  const [selectedPropertyId, setSelectedPropertyId] = useState<string>('all');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadData() {
      try {
        setLoading(true);
        const res = await fetch('/api/accounting/data');
        if (res.ok) {
          const json = await res.json();
          setReconciliation(json.data.reconciliation);
          setProjects(json.data.projects || []);
          setUnits(json.data.units || []);
          setExpenses(json.data.expenses || []);
          setInstallments(json.data.installments || []);
        }
      } catch (e) {
        console.error(e);
      } finally {
        setLoading(false);
      }
    }
    loadData();
  }, []);

  const totalSales = reconciliation?.totalSalesValue || 0;
  const totalCollected = reconciliation?.totalCollected || 0;
  const totalExpenses = reconciliation?.totalExpenseExposure || 0;
  const netProfit = reconciliation?.netCompanyProfit || 0;
  const collectionRate = totalSales > 0 ? Math.round((totalCollected / totalSales) * 100) : 0;
  const expenseRatio = totalSales > 0 ? Math.round((totalExpenses / totalSales) * 100) : 0;

  const filteredProjects = selectedPropertyId === 'all'
    ? projects
    : projects.filter(p => p.id === selectedPropertyId);

  return (
    <AppShell
      title="التقارير المحاسبية والتحليلات المالية المعتمدة"
      subtitle="تحليل التدفقات النقدية، نسب الأرباح المحققة، كشوفات التسوية، والعائد الاستثماري للمشروعات"
      actions={
        <div className="flex items-center gap-2">
          <select
            value={selectedPropertyId}
            onChange={e => setSelectedPropertyId(e.target.value)}
            className="px-3 py-2 bg-[#FFFFFF] border border-[#E2DFD8] rounded-xl text-xs font-bold text-[#242424] focus:outline-none"
          >
            <option value="all">كافة المشروعات</option>
            {projects.map(p => (
              <option key={p.id} value={p.id}>
                {p.name}
              </option>
            ))}
          </select>

          <button
            onClick={() => window.print()}
            className="px-4 py-2 rounded-xl bg-[#242424] hover:bg-[#1A1A1A] text-white font-bold text-xs flex items-center gap-2 shadow-sm transition"
          >
            <Printer className="w-4 h-4 text-[#A89F91]" />
            <span>طباعة التقرير المالي</span>
          </button>
        </div>
      }
    >
      <div className="space-y-8">
        {/* KPI Row */}
        <section className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <MetricCard
            label="إجمالي المبيعات التعاقدية"
            value={`${(totalSales / 1000000).toFixed(2)}M ج.م`}
            icon={TrendingUp}
            subtext="عقود البيع والوحدات المحجوزة"
          />

          <MetricCard
            label="صافي النقد المحصل فعلياً"
            value={`${(totalCollected / 1000000).toFixed(2)}M ج.م`}
            icon={DollarSign}
            subtext={`نسبة التحصيل: ${collectionRate}%`}
          />

          <MetricCard
            label="إجمالي التكاليف والمصروفات"
            value={`${(totalExpenses / 1000000).toFixed(2)}M ج.م`}
            icon={Receipt}
            subtext={`نسبة المصروفات للمبيعات: ${expenseRatio}%`}
          />

          <MetricCard
            label="صافي الأرباح الاستثمارية"
            value={`${(netProfit / 1000000).toFixed(2)}M ج.م`}
            icon={PieChart}
            subtext={netProfit >= 0 ? 'أرباح تعاقدية إيجابية' : 'عجز مرحلي'}
          />
        </section>

        {/* Financial Flow Analysis */}
        <section className="p-6 rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] shadow-sm space-y-4">
          <h3 className="font-editorial text-base font-bold text-[#242424]">تحليل الموقف المالي وحركة السيولة النقدية</h3>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs">
            <div className="p-4 rounded-2xl bg-[#F4F4F2] border border-[#E2DFD8] space-y-2">
              <span className="text-[#777777] font-bold block">المستحقات الآجلة طرف العملاء (Receivables)</span>
              <span className="text-lg font-black text-[#242424] block">
                {((reconciliation?.totalOutstandingReceivables || 0) / 1000000).toFixed(2)} مليون ج.م
              </span>
              <p className="text-[10px] text-[#777777]">أقساط مجدولة ومتبقي دفعات تعاقدية قيد السداد</p>
            </div>

            <div className="p-4 rounded-2xl bg-[#F4F4F2] border border-[#E2DFD8] space-y-2">
              <span className="text-[#777777] font-bold block">مديونيات الموردين والتشوينات (Payables)</span>
              <span className="text-lg font-black text-amber-700 block">
                {((reconciliation?.totalSupplierDuesPayable || 0) / 1000000).toFixed(2)} مليون ج.م
              </span>
              <p className="text-[10px] text-[#777777]">التزامات شراء حديد وأسمنت ومواد قيد الاستحقاق</p>
            </div>

            <div className="p-4 rounded-2xl bg-[#F4F4F2] border border-[#E2DFD8] space-y-2">
              <span className="text-[#777777] font-bold block">صافي التدفق النقدي التشغيلي (Net Cash Flow)</span>
              <span className={`text-lg font-black block ${(reconciliation?.netCashFlow || 0) >= 0 ? 'text-emerald-700' : 'text-rose-700'}`}>
                {((reconciliation?.netCashFlow || 0) / 1000000).toFixed(2)} مليون ج.م
              </span>
              <p className="text-[10px] text-[#777777]">المحصل الفعلي مطروحاً منه إجمالي المنصرف النقدي</p>
            </div>
          </div>
        </section>

        {/* Project By Project Breakdown */}
        <section className="rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] p-6 shadow-sm space-y-4">
          <h3 className="font-editorial text-base font-bold text-[#242424]">التقرير المالي والتحليلي التفصيلي لكل مشروع</h3>

          <div className="space-y-4">
            {filteredProjects.map(project => {
              const projectUnits = units.filter(u => u.propertyId === project.id);
              const projectSoldUnits = projectUnits.filter(u => u.status === 'sold' || u.customerName?.trim());
              const projectSales = projectSoldUnits.reduce((acc, u) => acc + u.salePrice, 0);
              const projectExpenses = expenses.filter(e => e.propertyId === project.id).reduce((acc, e) => acc + e.amount, 0);
              const projectDownPayments = projectSoldUnits.reduce((acc, u) => acc + u.downPayment, 0);
              const projectInstallments = installments.filter(i => i.propertyId === project.id && i.status === 'paid');
              const projectCollections = projectDownPayments + projectInstallments.reduce((acc, i) => acc + i.paidAmount, 0);
              const projectNet = projectSales - projectExpenses;

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
                        <h4 className="text-sm font-bold text-[#242424]">{project.name}</h4>
                        <p className="text-xs text-[#777777]">{project.location}</p>
                      </div>
                    </div>

                    <div className="flex items-center gap-4 text-xs font-mono">
                      <div>
                        <span className="text-[10px] text-[#777777] block">المبيعات المحققة</span>
                        <span className="font-bold text-[#242424]">{(projectSales / 1000000).toFixed(2)}M ج.م</span>
                      </div>
                      <div>
                        <span className="text-[10px] text-[#777777] block">المتحصلات</span>
                        <span className="font-bold text-emerald-700">{(projectCollections / 1000000).toFixed(2)}M ج.م</span>
                      </div>
                      <div>
                        <span className="text-[10px] text-[#777777] block">المصروفات</span>
                        <span className="font-bold text-amber-700">{(projectExpenses / 1000000).toFixed(2)}M ج.م</span>
                      </div>
                      <div>
                        <span className="text-[10px] text-[#777777] block">صافي الربح</span>
                        <span className="font-bold text-[#242424]">{(projectNet / 1000000).toFixed(2)}M ج.م</span>
                      </div>
                    </div>
                  </div>

                  <div className="pt-2 border-t border-[#E2DFD8] flex items-center justify-between text-[11px] text-[#777777]">
                    <span>عدد الوحدات المباعة: {projectSoldUnits.length} من أصل {project.apartmentCount} وحدة</span>
                    <span className="font-bold text-[#242424]">
                      الميزانية التقديرية: {(project.totalBudget / 1000000).toFixed(1)} مليون ج.م
                    </span>
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
