'use client';

import React, { useState, useEffect } from 'react';
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
  Scale,
  History,
  ShieldCheck,
  CheckCircle2,
  AlertTriangle,
  ArrowDownLeft,
  ChevronLeft,
} from 'lucide-react';
import AppShell from '@/components/layout/AppShell';
import MetricCard from '@/components/ui/MetricCard';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { CompanyReconciliation } from '@/lib/accounting/engine';
import { PropertyProject, Installment, ExpenseRecord, PartnerLedgerSummaryRow } from '@/types';

export default function DashboardPage() {
  const [loading, setLoading] = useState(true);
  const [reconciliation, setReconciliation] = useState<CompanyReconciliation | null>(null);
  const [projects, setProjects] = useState<PropertyProject[]>([]);
  const [installments, setInstallments] = useState<Installment[]>([]);
  const [expenses, setExpenses] = useState<ExpenseRecord[]>([]);
  const [userRole, setUserRole] = useState<string>('admin');

  useEffect(() => {
    async function fetchData() {
      try {
        setLoading(true);
        const res = await fetch('/api/accounting/data');
        if (res.ok) {
          const json = await res.json();
          setReconciliation(json.data.reconciliation);
          setProjects(json.data.projects || []);
          setInstallments(json.data.installments || []);
          setExpenses(json.data.expenses || []);
          setUserRole(json.user?.role || 'admin');
        }
      } catch (err) {
        console.error('Failed to load accounting data', err);
      } finally {
        setLoading(false);
      }
    }
    fetchData();
  }, []);

  const totalSales = reconciliation?.totalSalesValue || 0;
  const totalCollected = reconciliation?.totalCollected || 0;
  const totalExpenseExposure = reconciliation?.totalExpenseExposure || 0;
  const netProfit = reconciliation?.netCompanyProfit || 0;
  const overdueCount = installments.filter(i => i.status === 'overdue').length;

  return (
    <AppShell
      title="لوحة المؤشرات المحاسبية العامة"
      subtitle="ملخص مالي وإداري شامل لكافة المشروعات، التحصيلات، دفاتر المصروفات، وأقساط العملاء"
      actions={
        <div className="flex items-center gap-2">
          {userRole === 'admin' && (
            <Link
              href="/properties"
              className="px-4 py-2.5 rounded-xl bg-[#242424] hover:bg-[#1A1A1A] text-white font-bold text-xs flex items-center gap-2 shadow-sm transition active:scale-95"
            >
              <Plus className="w-4 h-4 text-[#A89F91]" />
              <span>مشروع جديد</span>
            </Link>
          )}
          <Link
            href="/price-monitoring"
            className="px-3.5 py-2.5 rounded-xl bg-[#F4F4F2] hover:bg-[#EBE8E1] border border-[#E2DFD8] text-xs font-bold text-[#242424] transition flex items-center gap-1.5"
          >
            <TrendingUp className="w-4 h-4 text-[#A89F91]" />
            <span>رصد الأسعار</span>
          </Link>
        </div>
      }
    >
      <div className="space-y-8">
        {/* KPI Metric Cards Row */}
        <section className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <MetricCard
            label="إجمالي القيمة التعاقدية للمبيعات"
            value={`${(totalSales / 1000000).toFixed(2)}M ج.م`}
            icon={TrendingUp}
            trend="عقود ومبيعات فعلية"
            subtext="موزعة على المشروعات المسجلة"
          />

          <MetricCard
            label="إجمالي التحصيلات النقدية المحققة"
            value={`${(totalCollected / 1000000).toFixed(2)}M ج.م`}
            icon={DollarSign}
            subtext={`متبقي مستحقات: ${((reconciliation?.totalOutstandingReceivables || 0) / 1000000).toFixed(2)}M ج.م`}
          />

          <MetricCard
            label="إجمالي التكاليف والمصروفات"
            value={`${(totalExpenseExposure / 1000000).toFixed(2)}M ج.م`}
            icon={Receipt}
            subtext={`مصروفات: ${((reconciliation?.totalGeneralExpenses || 0) / 1000000).toFixed(2)}M + تشوينات`}
          />

          <MetricCard
            label="صافي الأرباح التقديرية للشركة"
            value={`${(netProfit / 1000000).toFixed(2)}M ج.م`}
            icon={Scale}
            subtext={netProfit >= 0 ? 'فائض أرباح تشغيلي' : 'عجز مرحلي قيد التسوية'}
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
                <span className="text-[10px] text-[#777777]">{projects.length} مشاريع مسجلة</span>
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
                <span className="text-[10px] text-[#777777]">{overdueCount} أقساط متأخرة</span>
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
                <span className="text-[10px] text-[#777777]">إنشاءات ومواد بناء</span>
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
                <span className="text-[10px] text-[#777777]">توزيع الحصص والأرصدة</span>
              </div>
              <ArrowUpRight className="w-4 h-4 text-[#777777] group-hover:text-[#242424] transition" />
            </Link>
          </div>
        </section>

        {/* Live Partner Balances & Reconciliation Summary */}
        {reconciliation?.partnerLedgerRows && reconciliation.partnerLedgerRows.length > 0 && (
          <section className="rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] p-6 shadow-sm space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="font-editorial text-base font-bold text-[#242424] flex items-center gap-2">
                  <Scale className="w-5 h-5 text-[#A89F91]" />
                  <span>أرصدة الشركاء والتسوية المالية اللحظية (Partner Balances)</span>
                </h3>
                <p className="text-xs text-[#777777] mt-0.5">
                  محتسبة وفق نسبة المشاركة الفعلية وإجمالي المصروفات والتشوينات المسددة
                </p>
              </div>
              <Link
                href="/partners"
                className="text-xs font-bold text-[#242424] hover:text-[#777777] transition flex items-center gap-1"
              >
                <span>كشف الحساب الكامل</span>
                <ChevronLeft className="w-4 h-4" />
              </Link>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {reconciliation.partnerLedgerRows.map((row: PartnerLedgerSummaryRow) => {
                const isCompanyOwing = row.balance > 0;
                return (
                  <div
                    key={row.partner.id}
                    className="p-4 rounded-2xl bg-[#F4F4F2] border border-[#E2DFD8] space-y-3"
                  >
                    <div className="flex items-center justify-between">
                      <div>
                        <span className="font-bold text-[#242424] block">{row.partner.name}</span>
                        <span className="text-[11px] text-[#777777]">
                          نسبة الشراكة: {Math.round(row.partner.shareRatio * 100)}%
                        </span>
                      </div>
                      <span
                        className={`text-xs font-bold px-2.5 py-1 rounded-full ${
                          isCompanyOwing
                            ? 'bg-emerald-100 text-emerald-800'
                            : 'bg-amber-100 text-amber-800'
                        }`}
                      >
                        {isCompanyOwing ? 'مستحق له طرف الشركة' : 'مطلوب سداده للشركة'}
                      </span>
                    </div>

                    <div className="grid grid-cols-3 gap-2 pt-2 border-t border-[#E2DFD8] text-center text-xs">
                      <div>
                        <span className="text-[10px] text-[#777777] block">المسدد فعلياً</span>
                        <span className="font-bold text-[#242424]">
                          {(row.totalPaid / 1000).toLocaleString()} ألف
                        </span>
                      </div>
                      <div>
                        <span className="text-[10px] text-[#777777] block">الحصة المستهدفة</span>
                        <span className="font-bold text-[#242424]">
                          {(row.expectedShare / 1000).toLocaleString()} ألف
                        </span>
                      </div>
                      <div>
                        <span className="text-[10px] text-[#777777] block">صافي الرصيد</span>
                        <span className={`font-bold ${isCompanyOwing ? 'text-emerald-700' : 'text-amber-700'}`}>
                          {Math.abs(row.balance / 1000).toLocaleString()} ألف ج.م
                        </span>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </section>
        )}

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
