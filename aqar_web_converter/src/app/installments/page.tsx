'use client';

import React, { useState } from 'react';
import {
  Calendar,
  Plus,
  Search,
  CheckCircle2,
  DollarSign,
  AlertCircle,
  Clock,
  Filter,
  Check
} from 'lucide-react';
import AppShell from '@/components/layout/AppShell';
import MetricCard from '@/components/ui/MetricCard';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { initialInstallments } from '@/services/store';
import { InstallmentPlanGenerator } from '@/services/calculators';
import { Installment, InstallmentStatus, InstallmentPlan } from '@/types';

export default function InstallmentsPage() {
  const [installments, setInstallments] = useState<Installment[]>(initialInstallments);
  const [filter, setFilter] = useState<string>('all');
  const [search, setSearch] = useState('');
  const [showGeneratorModal, setShowGeneratorModal] = useState(false);

  // Generator form state
  const [customerName, setCustomerName] = useState('');
  const [totalAmount, setTotalAmount] = useState(1200000);
  const [installmentCount, setInstallmentCount] = useState(12);
  const [intervalDays, setIntervalDays] = useState(90); // Quarterly
  const [startDate, setStartDate] = useState('2026-05-01');

  React.useEffect(() => {
    setStartDate(new Date().toISOString().split('T')[0]);
  }, []);

  const handleGeneratePlan = (e: React.FormEvent) => {
    e.preventDefault();
    const plan: InstallmentPlan = {
      id: `plan-${Date.now()}`,
      propertyId: 'prop-1',
      unitId: 'unit-custom',
      customerName: customerName || 'عميل تجريبي',
      totalAmount: Number(totalAmount),
      installmentCount: Number(installmentCount),
      installmentAmount: Math.round(Number(totalAmount) / Number(installmentCount)),
      intervalDays: Number(intervalDays),
      startDate,
      workspaceId: 'main-ws',
    };

    const newGenerated = InstallmentPlanGenerator.generate(plan);
    setInstallments([...newGenerated, ...installments]);
    setShowGeneratorModal(false);
    setCustomerName('');
  };

  const handleMarkAsPaid = (instId: string) => {
    setInstallments(prev =>
      prev.map(i => {
        if (i.id === instId) {
          return {
            ...i,
            status: InstallmentStatus.Paid,
            paidAmount: i.amount,
            paidDate: new Date().toISOString().split('T')[0],
          };
        }
        return i;
      })
    );
  };

  const filtered = installments.filter(i => {
    const matchesFilter = filter === 'all' || i.status === filter;
    const matchesSearch = (i.customerName || '').includes(search) || i.id.includes(search);
    return matchesFilter && matchesSearch;
  });

  const totalPaid = installments.filter(i => i.status === InstallmentStatus.Paid).reduce((acc, i) => acc + i.paidAmount, 0);
  const totalPending = installments.filter(i => i.status !== InstallmentStatus.Paid).reduce((acc, i) => acc + i.amount, 0);
  const overdueCount = installments.filter(i => i.status === InstallmentStatus.Overdue).length;

  return (
    <AppShell
      title="جدول الأقساط والتحصيل"
      subtitle="توليد خطط السداد ومتابعة استحقاق الأقساط وتحصيل الشيكات والدفعات"
      actions={
        <button
          onClick={() => setShowGeneratorModal(true)}
          className="px-4 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-500 text-white font-bold text-xs flex items-center gap-2 shadow-lg shadow-blue-600/25 transition active:scale-95"
        >
          <Plus className="w-4 h-4" />
          <span>توليد خطة أقساط جديدة</span>
        </button>
      }
    >
      <div className="space-y-6">
        {/* Metric Cards Row */}
        <section className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <MetricCard
            label="إجمالي الأقساط المحصلة"
            value={`${(totalPaid / 1000).toLocaleString()} ألف ج.م`}
            icon={CheckCircle2}
            color="emerald"
            subtext="تم تحصيلها وإيداعها"
          />

          <MetricCard
            label="إجمالي الأقساط المتبقية"
            value={`${(totalPending / 1000).toLocaleString()} ألف ج.م`}
            icon={Clock}
            color="blue"
            subtext="أقساط مجدولة قيد الاستحقاق"
          />

          <MetricCard
            label="الأقساط المتأخرة السداد"
            value={`${overdueCount} أقساط`}
            icon={AlertCircle}
            color="rose"
            subtext="تجاوزت تاريخ الاستحقاق"
          />
        </section>

        {/* Filter and Search Bar */}
        <div className="flex flex-col sm:flex-row items-center justify-between gap-4 p-4 rounded-2xl bg-slate-900/60 border border-slate-800">
          <div className="relative w-full sm:w-80">
            <Search className="w-4 h-4 text-slate-500 absolute right-3 top-3" />
            <input
              type="text"
              placeholder="بحث باسم العميل أو رقم القسط..."
              value={search}
              onChange={e => setSearch(e.target.value)}
              className="w-full pl-3 pr-9 py-2 bg-slate-800/80 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-blue-500"
            />
          </div>

          <div className="flex items-center gap-2 overflow-x-auto w-full sm:w-auto pb-1 sm:pb-0">
            {[
              { id: 'all', label: 'كافة الأقساط' },
              { id: InstallmentStatus.Overdue, label: 'متأخر' },
              { id: InstallmentStatus.Pending, label: 'مستحق' },
              { id: InstallmentStatus.Paid, label: 'مسدد' },
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

        {/* Installments Table */}
        <div className="rounded-3xl bg-slate-900/80 border border-slate-800 p-6 shadow-lg space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-base font-bold text-white">سجل الأقساط المستحقة</h3>
            <span className="text-xs text-slate-400">{filtered.length} قسط معروض</span>
          </div>

          <div className="overflow-x-auto rounded-2xl border border-slate-800">
            <table className="w-full text-right text-xs">
              <thead className="bg-slate-800/80 text-slate-300 font-bold border-b border-slate-700">
                <tr>
                  <th className="p-3.5">العميل</th>
                  <th className="p-3.5">رقم القسط</th>
                  <th className="p-3.5">تاريخ الاستحقاق</th>
                  <th className="p-3.5">قيمة القسط</th>
                  <th className="p-3.5">المبلغ المسدد</th>
                  <th className="p-3.5">الحالة</th>
                  <th className="p-3.5 text-center">الإجراء</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800 text-slate-200">
                {filtered.map(inst => (
                  <tr key={inst.id} className="hover:bg-slate-800/40 transition">
                    <td className="p-3.5 font-bold text-white">{inst.customerName || 'عميل'}</td>
                    <td className="p-3.5 font-mono">القسط #{inst.sequence}</td>
                    <td className="p-3.5 font-mono text-slate-300">{inst.dueDate}</td>
                    <td className="p-3.5 font-mono font-bold text-emerald-400">
                      {inst.amount.toLocaleString()} ج.م
                    </td>
                    <td className="p-3.5 font-mono text-slate-300">
                      {inst.paidAmount.toLocaleString()} ج.م
                    </td>
                    <td className="p-3.5">
                      <StatusBadge status={inst.status} type="installment" />
                    </td>
                    <td className="p-3.5 text-center">
                      {inst.status !== InstallmentStatus.Paid ? (
                        <button
                          onClick={() => handleMarkAsPaid(inst.id)}
                          className="px-3 py-1.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-[11px] font-bold transition flex items-center gap-1 mx-auto"
                        >
                          <Check className="w-3.5 h-3.5" />
                          <span>تحصيل القسط</span>
                        </button>
                      ) : (
                        <span className="text-[11px] text-slate-500 font-mono">مسدد في {inst.paidDate}</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Generator Modal */}
        {showGeneratorModal && (
          <div className="fixed inset-0 bg-black/75 backdrop-blur-sm z-50 flex items-center justify-center p-4">
            <div className="w-full max-w-lg rounded-3xl bg-slate-900 border border-slate-800 p-6 space-y-4">
              <div className="pb-3 border-b border-slate-800">
                <h3 className="text-base font-bold text-white flex items-center gap-2">
                  <Calendar className="w-5 h-5 text-blue-400" />
                  مولد خطة أقساط ذكي (Installment Plan Generator)
                </h3>
                <p className="text-xs text-slate-400 mt-1">
                  يقوم بحساب مواعيد الاستحقاق وقيمة القسط المتساوية تلقائياً بناءً على كود فلاتر الأصلي
                </p>
              </div>

              <form onSubmit={handleGeneratePlan} className="space-y-4 text-xs">
                <div>
                  <label className="block text-slate-300 font-bold mb-1">اسم العميل المشتري</label>
                  <input
                    type="text"
                    required
                    placeholder="مثال: أحمد عبد الله"
                    value={customerName}
                    onChange={e => setCustomerName(e.target.value)}
                    className="w-full px-3 py-2.5 rounded-xl bg-slate-800 border border-slate-700 text-white focus:outline-none focus:border-blue-500"
                  />
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-slate-300 font-bold mb-1">المبلغ الإجمالي للتقسيط</label>
                    <input
                      type="number"
                      required
                      value={totalAmount}
                      onChange={e => setTotalAmount(Number(e.target.value))}
                      className="w-full px-3 py-2.5 rounded-xl bg-slate-800 border border-slate-700 text-white focus:outline-none focus:border-blue-500 font-mono"
                    />
                  </div>
                  <div>
                    <label className="block text-slate-300 font-bold mb-1">عدد الأقساط</label>
                    <input
                      type="number"
                      required
                      value={installmentCount}
                      onChange={e => setInstallmentCount(Number(e.target.value))}
                      className="w-full px-3 py-2.5 rounded-xl bg-slate-800 border border-slate-700 text-white focus:outline-none focus:border-blue-500 font-mono"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-slate-300 font-bold mb-1">الدورية (الفترة بالأيام)</label>
                    <select
                      value={intervalDays}
                      onChange={e => setIntervalDays(Number(e.target.value))}
                      className="w-full px-3 py-2.5 rounded-xl bg-slate-800 border border-slate-700 text-white focus:outline-none focus:border-blue-500"
                    >
                      <option value={30}>شهري (كل 30 يوم)</option>
                      <option value={90}>ربع سنوي (كل 3 شهور)</option>
                      <option value={180}>نصف سنوي (كل 6 شهور)</option>
                      <option value={365}>سنوي (كل سنة)</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-slate-300 font-bold mb-1">تاريخ استحقاق أول قسط</label>
                    <input
                      type="date"
                      required
                      value={startDate}
                      onChange={e => setStartDate(e.target.value)}
                      className="w-full px-3 py-2.5 rounded-xl bg-slate-800 border border-slate-700 text-white focus:outline-none focus:border-blue-500 font-mono"
                    />
                  </div>
                </div>

                <div className="p-3.5 rounded-2xl bg-slate-800/60 border border-slate-700 text-xs">
                  <span className="text-slate-400 block">قيمة القسط الفردي المقدرة:</span>
                  <strong className="text-emerald-400 font-mono text-base block mt-0.5">
                    {Math.round(totalAmount / installmentCount).toLocaleString()} ج.م
                  </strong>
                </div>

                <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-800">
                  <button
                    type="button"
                    onClick={() => setShowGeneratorModal(false)}
                    className="px-4 py-2 rounded-xl text-slate-400 hover:text-white"
                  >
                    إلغاء
                  </button>
                  <button
                    type="submit"
                    className="px-5 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-500 text-white font-bold transition"
                  >
                    توليد جدول الأقساط
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
