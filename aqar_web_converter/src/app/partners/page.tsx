'use client';

import React, { useState, useEffect } from 'react';
import {
  Users,
  Plus,
  DollarSign,
  TrendingUp,
  Scale,
  Percent,
  CheckCircle2,
  AlertCircle,
  X,
  FileText,
  ShieldCheck,
  History,
  Lock,
} from 'lucide-react';
import AppShell from '@/components/layout/AppShell';
import MetricCard from '@/components/ui/MetricCard';
import {
  Partner,
  PartnerLedgerEntry,
  PartnerLedgerSummaryRow,
  PartnerLedgerEntryType,
  PartnerLedgerEntryTypeLabels,
  PropertyProject,
} from '@/types';

export default function PartnersPage() {
  const [partners, setPartners] = useState<Partner[]>([]);
  const [ledgerRows, setLedgerRows] = useState<PartnerLedgerSummaryRow[]>([]);
  const [ledgerEntries, setLedgerEntries] = useState<PartnerLedgerEntry[]>([]);
  const [projects, setProjects] = useState<PropertyProject[]>([]);
  const [userRole, setUserRole] = useState<string>('admin');
  const [currentPartnerId, setCurrentPartnerId] = useState<string | undefined>();
  const [loading, setLoading] = useState(true);

  // Modals
  const [showAddPartnerModal, setShowAddPartnerModal] = useState(false);
  const [showAddLedgerModal, setShowAddLedgerModal] = useState(false);

  // New partner state
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [shareRatio, setShareRatio] = useState(25); // 25%
  const [initialCapital, setInitialCapital] = useState(5000000);

  // New ledger entry state
  const [targetPartnerId, setTargetPartnerId] = useState('');
  const [entryType, setEntryType] = useState<PartnerLedgerEntryType>(PartnerLedgerEntryType.Contribution);
  const [ledgerAmount, setLedgerAmount] = useState(500000);
  const [ledgerNotes, setLedgerNotes] = useState('');
  const [ledgerPropertyId, setLedgerPropertyId] = useState('prop-1');

  const [alertMessage, setAlertMessage] = useState('');

  const loadData = async () => {
    try {
      setLoading(true);
      const res = await fetch('/api/accounting/data');
      if (res.ok) {
        const json = await res.json();
        setPartners(json.data.partners || []);
        setLedgerEntries(json.data.partnerLedgers || []);
        setLedgerRows(json.data.reconciliation?.partnerLedgerRows || []);
        setProjects(json.data.projects || []);
        setUserRole(json.user?.role || 'admin');
        setCurrentPartnerId(json.user?.partnerId);
        if (json.data.partners?.[0]?.id) {
          setTargetPartnerId(json.data.partners[0].id);
        }
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleAddPartner = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name) return;

    try {
      const res = await fetch('/api/accounting/data', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: 'create_partner',
          payload: {
            name,
            phone,
            shareRatio: Number(shareRatio) / 100,
            initialCapital: Number(initialCapital),
          },
        }),
      });

      if (!res.ok) {
        const err = await res.json();
        throw new Error(err.error || 'فشل تسجيل الشريك');
      }

      setAlertMessage('تم إضافة الشريك الجديد وتوثيق رأس ماله التأسيسي بنجاح');
      setShowAddPartnerModal(false);
      setName('');
      setPhone('');
      await loadData();
      setTimeout(() => setAlertMessage(''), 4000);
    } catch (err: any) {
      alert(err.message);
    }
  };

  const handleAddLedgerEntry = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!targetPartnerId || !ledgerAmount) return;

    try {
      const res = await fetch('/api/accounting/data', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: 'create_partner_ledger_entry',
          payload: {
            partnerId: targetPartnerId,
            propertyId: ledgerPropertyId,
            entryType,
            amount: Number(ledgerAmount),
            notes: ledgerNotes,
            authorizedBy: 'current-user',
          },
        }),
      });

      if (!res.ok) {
        const err = await res.json();
        throw new Error(err.error || 'فشل تسجيل القيد');
      }

      setAlertMessage('تم تسجيل القيد في دفتر الأستاذ للشريك بنجاح وإعادة احتساب الأرصدة');
      setShowAddLedgerModal(false);
      setLedgerNotes('');
      await loadData();
      setTimeout(() => setAlertMessage(''), 4000);
    } catch (err: any) {
      alert(err.message);
    }
  };

  const totalCapital = partners.reduce((sum, p) => sum + p.initialCapital, 0);
  const totalPaidByPartners = ledgerRows.reduce((sum, r) => sum + r.totalPaid, 0);

  return (
    <AppShell
      title="الشركاء وحسابات الدخول والتسويات"
      subtitle="إدارة قيود دفاتر الشركاء، مساهمات رأس المال، التسويات اللحظية، وتوزيع المصروفات بدقة متناهية"
      actions={
        <div className="flex items-center gap-2">
          {userRole === 'admin' && (
            <>
              <button
                onClick={() => setShowAddLedgerModal(true)}
                className="px-3.5 py-2 rounded-xl bg-[#FFFFFF] border border-[#E2DFD8] text-[#242424] font-bold text-xs flex items-center gap-1.5 hover:bg-[#F4F4F2] transition"
              >
                <FileText className="w-4 h-4 text-[#A89F91]" />
                <span>إضافة قيد في دفتر الشريك</span>
              </button>

              <button
                onClick={() => setShowAddPartnerModal(true)}
                className="px-4 py-2 rounded-xl bg-[#242424] hover:bg-[#1A1A1A] text-white font-bold text-xs flex items-center gap-2 shadow-sm transition active:scale-95"
              >
                <Plus className="w-4 h-4 text-[#A89F91]" />
                <span>إضافة شريك جديد</span>
              </button>
            </>
          )}
        </div>
      }
    >
      <div className="space-y-8">
        {/* Success Alert */}
        {alertMessage && (
          <div className="p-4 rounded-2xl bg-emerald-50 border border-emerald-300 text-emerald-900 text-xs font-bold flex items-center gap-2 animate-in fade-in">
            <CheckCircle2 className="w-5 h-5 text-emerald-600" />
            <span>{alertMessage}</span>
          </div>
        )}

        {/* Partner Role Privacy Notice */}
        {userRole === 'partner' && (
          <div className="p-4 rounded-2xl bg-blue-50 border border-blue-200 text-blue-900 text-xs flex items-center gap-2.5">
            <Lock className="w-5 h-5 text-blue-600 shrink-0" />
            <span>
              أنت مسجل حالياً بصلاحية شريك استثماري. يتم عرض الحساب المالي الخاص بحصتك فقط تطبيقاً لقواعد الخصوصية وعزل البيانات.
            </span>
          </div>
        )}

        {/* KPI Row */}
        <section className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <MetricCard
            label="عدد الشركاء المعتمدين"
            value={`${partners.length} شركاء`}
            icon={Users}
            subtext="حسابات شراكة نشطة وموثقة"
          />

          <MetricCard
            label="إجمالي رأس المال التأسيسي"
            value={`${(totalCapital / 1000000).toFixed(2)}M ج.م`}
            icon={DollarSign}
            subtext="إجمالي مساهمات الشركاء في التأسيس"
          />

          <MetricCard
            label="إجمالي المبالغ المنفذة من الشركاء"
            value={`${(totalPaidByPartners / 1000000).toFixed(2)}M ج.م`}
            icon={Scale}
            subtext="إيداعات، مصروفات مباشرة، وسدادات موردين"
          />
        </section>

        {/* Live Partner Settlement Table (Calculator output) */}
        <section className="rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] p-6 shadow-sm space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="font-editorial text-base font-bold text-[#242424] flex items-center gap-2">
                <Scale className="w-5 h-5 text-[#A89F91]" />
                <span>جدول التسوية والتصفية المالية للشركاء (Live Settlement Ledger)</span>
              </h3>
              <p className="text-xs text-[#777777] mt-0.5">
                محتسب عبر معادلة التعرض المالي الكامل (المصروفات + التشوينات) وفق نسبة المشاركة
              </p>
            </div>
            <span className="text-xs font-mono font-bold text-[#777777]">{ledgerRows.length} شركاء</span>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-right text-xs">
              <thead className="bg-[#F4F4F2] text-[#777777] border-b border-[#E2DFD8]">
                <tr>
                  <th className="py-3 px-4 font-bold">اسم الشريك</th>
                  <th className="py-3 px-4 font-bold">نسبة المشاركة</th>
                  <th className="py-3 px-4 font-bold">إجمالي المسدد فعلياً</th>
                  <th className="py-3 px-4 font-bold">الحصة الواجب تحملها</th>
                  <th className="py-3 px-4 font-bold">المتبقي المطلوب سداده</th>
                  <th className="py-3 px-4 font-bold">صافي الموقف المالي</th>
                  <th className="py-3 px-4 font-bold">آخر حركة</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#E2DFD8]">
                {ledgerRows.map(row => {
                  const isCompanyOwing = row.balance > 0;
                  return (
                    <tr key={row.partner.id} className="hover:bg-[#FAF9F6] transition">
                      <td className="py-3.5 px-4">
                        <span className="font-bold text-[#242424] block">{row.partner.name}</span>
                        <span className="text-[10px] text-[#777777]">{row.partner.phone || 'بدون هاتف'}</span>
                      </td>

                      <td className="py-3.5 px-4 font-bold text-[#242424]">
                        {Math.round(row.partner.shareRatio * 100)}%
                      </td>

                      <td className="py-3.5 px-4 font-bold text-emerald-700">
                        {row.totalPaid.toLocaleString()} ج.م
                      </td>

                      <td className="py-3.5 px-4 font-bold text-[#242424]">
                        {row.expectedShare.toLocaleString()} ج.م
                      </td>

                      <td className="py-3.5 px-4 font-bold text-amber-700">
                        {row.totalOwed.toLocaleString()} ج.م
                      </td>

                      <td className="py-3.5 px-4">
                        <span
                          className={`inline-block font-bold px-2.5 py-1 rounded-full text-[11px] ${
                            isCompanyOwing
                              ? 'bg-emerald-100 text-emerald-800'
                              : 'bg-amber-100 text-amber-800'
                          }`}
                        >
                          {isCompanyOwing ? `+ ${row.balance.toLocaleString()} ج.م (دائن)` : `- ${Math.abs(row.balance).toLocaleString()} ج.م (مدين)`}
                        </span>
                      </td>

                      <td className="py-3.5 px-4 text-[#777777] text-[10px]">
                        {new Date(row.lastUpdated).toLocaleDateString('ar-EG')}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </section>

        {/* Partner Ledger Transaction Entries */}
        <section className="rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] p-6 shadow-sm space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="font-editorial text-base font-bold text-[#242424] flex items-center gap-2">
              <History className="w-5 h-5 text-[#A89F91]" />
              <span>سجل قيود دفتر الأستاذ للشركاء (Partner Ledger Entries)</span>
            </h3>
            <span className="text-xs text-[#777777]">{ledgerEntries.length} قيود مسجلة</span>
          </div>

          <div className="space-y-3">
            {ledgerEntries.map(entry => {
              const partner = partners.find(p => p.id === entry.partnerId);
              return (
                <div
                  key={entry.id}
                  className="p-4 rounded-2xl bg-[#F4F4F2] border border-[#E2DFD8] flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs"
                >
                  <div>
                    <div className="flex items-center gap-2 mb-1">
                      <span className="font-bold text-[#242424]">{partner?.name || 'شريك غير محدد'}</span>
                      <span className="bg-[#EBE8E1] text-[#242424] font-bold px-2 py-0.5 rounded-full text-[10px]">
                        {PartnerLedgerEntryTypeLabels[entry.entryType] || entry.entryType}
                      </span>
                    </div>
                    <p className="text-[11px] text-[#555555]">
                      {entry.notes || 'بدون ملاحظات إضافية'}
                    </p>
                  </div>

                  <div className="text-left shrink-0">
                    <span className="font-mono font-black text-sm text-[#242424] block">
                      {entry.amount.toLocaleString()} ج.م
                    </span>
                    <span className="text-[10px] text-[#777777]">
                      بتاريخ: {new Date(entry.createdAt).toLocaleDateString('ar-EG')}
                    </span>
                  </div>
                </div>
              );
            })}
          </div>
        </section>
      </div>

      {/* Add Partner Modal */}
      {showAddPartnerModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-[#FFFFFF] border border-[#E2DFD8] rounded-3xl max-w-lg w-full p-6 shadow-2xl relative animate-in zoom-in-95 duration-200">
            <button
              onClick={() => setShowAddPartnerModal(false)}
              className="absolute left-6 top-6 p-1.5 rounded-xl text-[#777777] hover:bg-[#F4F4F2] transition"
            >
              <X className="w-5 h-5" />
            </button>

            <h3 className="font-editorial text-lg font-bold text-[#242424] mb-1">إضافة شريك جديد في المنظومة</h3>
            <p className="text-xs text-[#777777] mb-4">إنشاء حساب شريك وتوثيق حصة رأس المال التأسيسية</p>

            <form onSubmit={handleAddPartner} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-[#242424] mb-1">اسم الشريك الثلاثي</label>
                <input
                  type="text"
                  required
                  placeholder="مثال: د. هاني عبد السلام القاضي"
                  value={name}
                  onChange={e => setName(e.target.value)}
                  className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none focus:border-[#242424]"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-[#242424] mb-1">رقم الهاتف للتواصل والتوثيق</label>
                <input
                  type="text"
                  placeholder="010xxxxxxxx"
                  value={phone}
                  onChange={e => setPhone(e.target.value)}
                  className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none focus:border-[#242424]"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-[#242424] mb-1">نسبة الشراكة (%)</label>
                  <input
                    type="number"
                    min={1}
                    max={100}
                    value={shareRatio}
                    onChange={e => setShareRatio(Number(e.target.value))}
                    className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none focus:border-[#242424]"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-[#242424] mb-1">رأس المال المودع (ج.م)</label>
                  <input
                    type="number"
                    step={100000}
                    value={initialCapital}
                    onChange={e => setInitialCapital(Number(e.target.value))}
                    className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none focus:border-[#242424]"
                  />
                </div>
              </div>

              <div className="pt-2 flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setShowAddPartnerModal(false)}
                  className="px-4 py-2 rounded-xl text-xs font-bold text-[#777777] hover:bg-[#F4F4F2] transition"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-5 py-2.5 rounded-xl bg-[#242424] hover:bg-[#1A1A1A] text-white font-bold text-xs transition"
                >
                  حفظ الشريك واعتماد الحصة
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Add Partner Ledger Entry Modal */}
      {showAddLedgerModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-[#FFFFFF] border border-[#E2DFD8] rounded-3xl max-w-lg w-full p-6 shadow-2xl relative animate-in zoom-in-95 duration-200">
            <button
              onClick={() => setShowAddLedgerModal(false)}
              className="absolute left-6 top-6 p-1.5 rounded-xl text-[#777777] hover:bg-[#F4F4F2] transition"
            >
              <X className="w-5 h-5" />
            </button>

            <h3 className="font-editorial text-lg font-bold text-[#242424] mb-1">إضافة قيد في دفتر أستاذ الشريك</h3>
            <p className="text-xs text-[#777777] mb-4">توثيق مساهمة، سداد تسوية، أو التزام مالي للشريك</p>

            <form onSubmit={handleAddLedgerEntry} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-[#242424] mb-1">الشريك المستهدف</label>
                <select
                  value={targetPartnerId}
                  onChange={e => setTargetPartnerId(e.target.value)}
                  className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none"
                >
                  {partners.map(p => (
                    <option key={p.id} value={p.id}>
                      {p.name} ({Math.round(p.shareRatio * 100)}%)
                    </option>
                  ))}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-[#242424] mb-1">نوع القيد المحاسبي</label>
                  <select
                    value={entryType}
                    onChange={e => setEntryType(e.target.value as PartnerLedgerEntryType)}
                    className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none"
                  >
                    <option value={PartnerLedgerEntryType.Contribution}>إيداع رأس مال ومساهمة</option>
                    <option value={PartnerLedgerEntryType.Settlement}>سداد تسوية أرباح</option>
                    <option value={PartnerLedgerEntryType.Adjustment}>تسوية قيد محاسبي</option>
                    <option value={PartnerLedgerEntryType.Obligation}>التزام مالي مستحق</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-bold text-[#242424] mb-1">المبلغ المالي (ج.م)</label>
                  <input
                    type="number"
                    step={10000}
                    required
                    value={ledgerAmount}
                    onChange={e => setLedgerAmount(Number(e.target.value))}
                    className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none focus:border-[#242424]"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-[#242424] mb-1">المشروع المرتبط</label>
                <select
                  value={ledgerPropertyId}
                  onChange={e => setLedgerPropertyId(e.target.value)}
                  className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none"
                >
                  {projects.map(p => (
                    <option key={p.id} value={p.id}>
                      {p.name}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-xs font-bold text-[#242424] mb-1">ملاحظات وبيان القيد</label>
                <textarea
                  rows={2}
                  placeholder="بيان تفصيلي بسبب القيد ورقم الإيداع البنكي أو الشيك..."
                  value={ledgerNotes}
                  onChange={e => setLedgerNotes(e.target.value)}
                  className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] placeholder-[#777777] focus:outline-none focus:border-[#242424]"
                />
              </div>

              <div className="pt-2 flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setShowAddLedgerModal(false)}
                  className="px-4 py-2 rounded-xl text-xs font-bold text-[#777777] hover:bg-[#F4F4F2] transition"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-5 py-2.5 rounded-xl bg-[#242424] hover:bg-[#1A1A1A] text-white font-bold text-xs transition"
                >
                  اعتماد وتوثيق القيد
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </AppShell>
  );
}
