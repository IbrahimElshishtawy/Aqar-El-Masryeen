'use client';

import React, { useState, useEffect } from 'react';
import {
  Calendar,
  Plus,
  Search,
  CheckCircle2,
  DollarSign,
  AlertCircle,
  Clock,
  Filter,
  Check,
  X,
  CreditCard,
  FileCheck,
} from 'lucide-react';
import AppShell from '@/components/layout/AppShell';
import MetricCard from '@/components/ui/MetricCard';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { InstallmentPlanGenerator } from '@/services/calculators';
import { Installment, InstallmentStatus, InstallmentPlan, PropertyProject } from '@/types';

export default function InstallmentsPage() {
  const [installments, setInstallments] = useState<Installment[]>([]);
  const [projects, setProjects] = useState<PropertyProject[]>([]);
  const [filter, setFilter] = useState<string>('all');
  const [search, setSearch] = useState('');
  const [userRole, setUserRole] = useState<string>('admin');

  // Modals
  const [showGeneratorModal, setShowGeneratorModal] = useState(false);
  const [paymentModalInst, setPaymentModalInst] = useState<Installment | null>(null);
  const [payAmount, setPayAmount] = useState<number>(0);
  const [payMethod, setPayMethod] = useState<string>('bankTransfer');
  const [receiptNumber, setReceiptNumber] = useState<string>('');
  const [alertMessage, setAlertMessage] = useState('');

  // Generator form state
  const [customerName, setCustomerName] = useState('');
  const [totalAmount, setTotalAmount] = useState(1200000);
  const [installmentCount, setInstallmentCount] = useState(12);
  const [intervalDays, setIntervalDays] = useState(90); // Quarterly
  const [startDate, setStartDate] = useState('');

  const loadData = async () => {
    try {
      const res = await fetch('/api/accounting/data');
      if (res.ok) {
        const json = await res.json();
        setInstallments(json.data.installments || []);
        setProjects(json.data.projects || []);
        setUserRole(json.user?.role || 'admin');
      }
    } catch (e) {
      console.error(e);
    }
  };

  useEffect(() => {
    setStartDate(new Date().toISOString().split('T')[0]);
    loadData();
  }, []);

  const handleGeneratePlan = (e: React.FormEvent) => {
    e.preventDefault();
    const plan: InstallmentPlan = {
      id: `plan-${Date.now()}`,
      propertyId: projects[0]?.id || 'prop-1',
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
    setAlertMessage('تم توليد جدول الأقساط الزمني بنجاح');
    setTimeout(() => setAlertMessage(''), 4000);
  };

  const handleOpenPaymentModal = (inst: Installment) => {
    setPaymentModalInst(inst);
    setPayAmount(inst.amount - inst.paidAmount);
    setReceiptNumber(`REC-${Date.now().toString().slice(-4)}`);
  };

  const handleConfirmPayment = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!paymentModalInst) return;

    try {
      const res = await fetch('/api/accounting/data', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: 'record_customer_payment',
          payload: {
            propertyId: paymentModalInst.propertyId,
            unitId: paymentModalInst.unitId,
            installmentId: paymentModalInst.id,
            amount: Number(payAmount),
            customerName: paymentModalInst.customerName || 'عميل معتمد',
            receivedAt: new Date().toISOString().split('T')[0],
            paymentMethod: payMethod,
            paymentSource: 'installment',
            receiptNumber,
          },
        }),
      });

      if (!res.ok) {
        const err = await res.json();
        throw new Error(err.error || 'فشل تسجيل التحصيل');
      }

      setAlertMessage('تم تسجيل تحصيل القسط وتحديث حساب العميل والمشروع بنجاح');
      setPaymentModalInst(null);
      await loadData();
      setTimeout(() => setAlertMessage(''), 4000);
    } catch (err: any) {
      alert(err.message);
    }
  };

  const filtered = installments.filter(i => {
    const matchesFilter = filter === 'all' || i.status === filter;
    const matchesSearch = (i.customerName || '').includes(search) || i.id.includes(search);
    return matchesFilter && matchesSearch;
  });

  const totalPaid = installments.filter(i => i.status === InstallmentStatus.Paid).reduce((acc, i) => acc + i.paidAmount, 0);
  const totalPending = installments.filter(i => i.status !== InstallmentStatus.Paid).reduce((acc, i) => acc + (i.amount - i.paidAmount), 0);
  const overdueCount = installments.filter(i => i.status === InstallmentStatus.Overdue).length;

  return (
    <AppShell
      title="جدول الأقساط والتحصيل والمقبوضات"
      subtitle="توليد خطط السداد، متابعة استحقاق الأقساط، وتحصيل الشيكات والتحويلات المصرفية"
      actions={
        <div className="flex items-center gap-2">
          {userRole !== 'viewer' && (
            <button
              onClick={() => setShowGeneratorModal(true)}
              className="px-4 py-2.5 rounded-xl bg-[#242424] hover:bg-[#1A1A1A] text-white font-bold text-xs flex items-center gap-2 shadow-sm transition active:scale-95"
            >
              <Plus className="w-4 h-4 text-[#A89F91]" />
              <span>توليد خطة أقساط جديدة</span>
            </button>
          )}
        </div>
      }
    >
      <div className="space-y-6">
        {/* Success Alert */}
        {alertMessage && (
          <div className="p-4 rounded-2xl bg-emerald-50 border border-emerald-300 text-emerald-900 text-xs font-bold flex items-center gap-2 animate-in fade-in">
            <CheckCircle2 className="w-5 h-5 text-emerald-600" />
            <span>{alertMessage}</span>
          </div>
        )}

        {/* Metric Cards Row */}
        <section className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <MetricCard
            label="إجمالي الأقساط المحصلة"
            value={`${(totalPaid / 1000).toLocaleString()} ألف ج.م`}
            icon={CheckCircle2}
            subtext="مقبوضات مسددة بالحساب البنكي"
          />

          <MetricCard
            label="المستحقات المتبقية للتحصيل"
            value={`${(totalPending / 1000).toLocaleString()} ألف ج.م`}
            icon={DollarSign}
            subtext="أقساط مجدولة قيد السداد"
          />

          <MetricCard
            label="الأقساط المتأخرة"
            value={`${overdueCount} أقساط`}
            icon={AlertCircle}
            subtext="تجاوزت تاريخ الاستحقاق"
          />
        </section>

        {/* Search & Filter Bar */}
        <div className="flex flex-col sm:flex-row items-center justify-between gap-4 p-4 rounded-2xl bg-[#FFFFFF] border border-[#E2DFD8] shadow-sm">
          <div className="relative w-full sm:w-80">
            <Search className="w-4 h-4 text-[#777777] absolute right-3 top-3" />
            <input
              type="text"
              placeholder="بحث باسم العميل أو رقم القسط..."
              value={search}
              onChange={e => setSearch(e.target.value)}
              className="w-full pl-3 pr-9 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] placeholder-[#777777] focus:outline-none focus:border-[#242424]"
            />
          </div>

          <div className="flex items-center gap-2 overflow-x-auto w-full sm:w-auto pb-1 sm:pb-0">
            {[
              { id: 'all', label: 'كافة الأقساط' },
              { id: InstallmentStatus.Overdue, label: 'متأخرة' },
              { id: InstallmentStatus.Pending, label: 'مستحقة' },
              { id: InstallmentStatus.Paid, label: 'تم السداد' },
            ].map(tab => (
              <button
                key={tab.id}
                onClick={() => setFilter(tab.id)}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition ${
                  filter === tab.id
                    ? 'bg-[#242424] text-white'
                    : 'bg-[#F4F4F2] text-[#777777] hover:bg-[#EBE8E1] hover:text-[#242424]'
                }`}
              >
                {tab.label}
              </button>
            ))}
          </div>
        </div>

        {/* Installments Table */}
        <div className="rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] p-6 shadow-sm overflow-hidden space-y-4">
          <div className="overflow-x-auto">
            <table className="w-full text-right text-xs">
              <thead className="bg-[#F4F4F2] text-[#777777] border-b border-[#E2DFD8]">
                <tr>
                  <th className="py-3 px-4 font-bold">اسم العميل والقسط</th>
                  <th className="py-3 px-4 font-bold">قيمة القسط</th>
                  <th className="py-3 px-4 font-bold">المسدد فعلياً</th>
                  <th className="py-3 px-4 font-bold">تاريخ الاستحقاق</th>
                  <th className="py-3 px-4 font-bold">الحالة</th>
                  <th className="py-3 px-4 font-bold">إجراءات التحصيل</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#E2DFD8]">
                {filtered.map(inst => (
                  <tr key={inst.id} className="hover:bg-[#FAF9F6] transition">
                    <td className="py-3.5 px-4">
                      <span className="font-bold text-[#242424] block">{inst.customerName || 'عميل غير مسجل'}</span>
                      <span className="text-[10px] text-[#777777]">القسط #{inst.sequence}</span>
                    </td>

                    <td className="py-3.5 px-4 font-bold text-[#242424]">
                      {inst.amount.toLocaleString()} ج.م
                    </td>

                    <td className="py-3.5 px-4 font-bold text-emerald-700">
                      {inst.paidAmount.toLocaleString()} ج.م
                    </td>

                    <td className="py-3.5 px-4 text-[#777777]">
                      {inst.dueDate}
                    </td>

                    <td className="py-3.5 px-4">
                      <StatusBadge status={inst.status} type="installment" />
                    </td>

                    <td className="py-3.5 px-4">
                      {inst.status !== InstallmentStatus.Paid ? (
                        userRole !== 'viewer' ? (
                          <button
                            onClick={() => handleOpenPaymentModal(inst)}
                            className="px-3 py-1.5 rounded-xl bg-emerald-700 hover:bg-emerald-800 text-white font-bold text-[11px] flex items-center gap-1 shadow-sm transition active:scale-95"
                          >
                            <CreditCard className="w-3.5 h-3.5" />
                            <span>تسجيل تحصيل</span>
                          </button>
                        ) : (
                          <span className="text-[10px] text-[#999999]">للمشاهدة فقط</span>
                        )
                      ) : (
                        <span className="inline-flex items-center gap-1 text-[11px] font-bold text-emerald-700">
                          <Check className="w-3.5 h-3.5" />
                          <span>مسدد بالكامل</span>
                        </span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* Record Payment Modal */}
      {paymentModalInst && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-[#FFFFFF] border border-[#E2DFD8] rounded-3xl max-w-md w-full p-6 shadow-2xl relative animate-in zoom-in-95 duration-200">
            <button
              onClick={() => setPaymentModalInst(null)}
              className="absolute left-6 top-6 p-1.5 rounded-xl text-[#777777] hover:bg-[#F4F4F2] transition"
            >
              <X className="w-5 h-5" />
            </button>

            <h3 className="font-editorial text-lg font-bold text-[#242424] mb-1">تسجيل تحصيل قسط عميل</h3>
            <p className="text-xs text-[#777777] mb-4">
              العميل: {paymentModalInst.customerName} | القسط #{paymentModalInst.sequence}
            </p>

            <form onSubmit={handleConfirmPayment} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-[#242424] mb-1">المبلغ المحصل (ج.م)</label>
                <input
                  type="number"
                  required
                  value={payAmount}
                  onChange={e => setPayAmount(Number(e.target.value))}
                  className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs font-bold text-[#242424] focus:outline-none focus:border-[#242424]"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-[#242424] mb-1">طريقة الدفع</label>
                <select
                  value={payMethod}
                  onChange={e => setPayMethod(e.target.value)}
                  className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none"
                >
                  <option value="bankTransfer">تحويل بنكي</option>
                  <option value="cash">نقدي (كاش بالخزينة)</option>
                  <option value="cheque">شيك مصرفي</option>
                  <option value="wallet">محفظة إلكترونية</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-bold text-[#242424] mb-1">رقم الإيصال أو التحويل</label>
                <input
                  type="text"
                  required
                  value={receiptNumber}
                  onChange={e => setReceiptNumber(e.target.value)}
                  className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none"
                />
              </div>

              <div className="pt-2 flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setPaymentModalInst(null)}
                  className="px-4 py-2 rounded-xl text-xs font-bold text-[#777777] hover:bg-[#F4F4F2] transition"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-5 py-2.5 rounded-xl bg-emerald-700 hover:bg-emerald-800 text-white font-bold text-xs transition"
                >
                  تأكيد التحصيل وإصدار السند
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Generator Modal */}
      {showGeneratorModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-[#FFFFFF] border border-[#E2DFD8] rounded-3xl max-w-lg w-full p-6 shadow-2xl relative animate-in zoom-in-95 duration-200">
            <button
              onClick={() => setShowGeneratorModal(false)}
              className="absolute left-6 top-6 p-1.5 rounded-xl text-[#777777] hover:bg-[#F4F4F2] transition"
            >
              <X className="w-5 h-5" />
            </button>

            <h3 className="font-editorial text-lg font-bold text-[#242424] mb-1">توليد خطة أقساط جديدة</h3>
            <p className="text-xs text-[#777777] mb-4">إنشاء خطة سداد دورية محسوبة تلقائياً</p>

            <form onSubmit={handleGeneratePlan} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-[#242424] mb-1">اسم العميل</label>
                <input
                  type="text"
                  required
                  placeholder="مثال: م. مصطفى الشاذلي"
                  value={customerName}
                  onChange={e => setCustomerName(e.target.value)}
                  className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none focus:border-[#242424]"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-[#242424] mb-1">إجمالي المبلغ المقسط (ج.م)</label>
                  <input
                    type="number"
                    step={10000}
                    value={totalAmount}
                    onChange={e => setTotalAmount(Number(e.target.value))}
                    className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none focus:border-[#242424]"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-[#242424] mb-1">عدد الأقساط</label>
                  <input
                    type="number"
                    min={1}
                    max={60}
                    value={installmentCount}
                    onChange={e => setInstallmentCount(Number(e.target.value))}
                    className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none focus:border-[#242424]"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-[#242424] mb-1">دورية القسط (أيام)</label>
                  <select
                    value={intervalDays}
                    onChange={e => setIntervalDays(Number(e.target.value))}
                    className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none"
                  >
                    <option value={30}>شهري (30 يوم)</option>
                    <option value={90}>ربع سنوي (90 يوم)</option>
                    <option value={180}>نصف سنوي (180 يوم)</option>
                    <option value={365}>سنوي (365 يوم)</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-bold text-[#242424] mb-1">تاريخ استحقاق أول قسط</label>
                  <input
                    type="date"
                    required
                    value={startDate}
                    onChange={e => setStartDate(e.target.value)}
                    className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none focus:border-[#242424]"
                  />
                </div>
              </div>

              <div className="pt-2 flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setShowGeneratorModal(false)}
                  className="px-4 py-2 rounded-xl text-xs font-bold text-[#777777] hover:bg-[#F4F4F2] transition"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-5 py-2.5 rounded-xl bg-[#242424] hover:bg-[#1A1A1A] text-white font-bold text-xs transition"
                >
                  توليد وحفظ الخطة
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </AppShell>
  );
}
