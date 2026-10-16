'use client';

import React, { useState } from 'react';
import {
  Users,
  Plus,
  DollarSign,
  TrendingUp,
  Scale,
  Percent,
  CheckCircle2,
  AlertCircle,
  X
} from 'lucide-react';
import AppShell from '@/components/layout/AppShell';
import MetricCard from '@/components/ui/MetricCard';
import { initialPartners, initialExpenses } from '@/services/store';
import { PartnerSettlementCalculator } from '@/services/calculators';
import { Partner } from '@/types';

export default function PartnersPage() {
  const [partners, setPartners] = useState<Partner[]>(initialPartners);
  const [showAddModal, setShowAddModal] = useState(false);

  // New partner state
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [shareRatio, setShareRatio] = useState(25); // 25%
  const [initialCapital, setInitialCapital] = useState(5000000);

  const settlements = PartnerSettlementCalculator.build(partners, initialExpenses);
  const totalExpenses = initialExpenses.reduce((sum, item) => sum + item.amount, 0);

  const handleAddPartner = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name) return;

    const newPartner: Partner = {
      id: `partner-${Date.now()}`,
      name,
      phone,
      shareRatio: Number(shareRatio) / 100,
      initialCapital: Number(initialCapital),
      joinedDate: new Date().toISOString().split('T')[0],
      status: 'active',
    };

    setPartners([...partners, newPartner]);
    setShowAddModal(false);
    setName('');
    setPhone('');
  };

  return (
    <AppShell
      title="الشركاء والتسويات المالية"
      subtitle="حساب وتوزيع نسب الشراكة وتصفية الأرصدة والمصروفات بين الشركاء محاسبياً"
      actions={
        <button
          onClick={() => setShowAddModal(true)}
          className="px-4 py-2.5 rounded-xl bg-[#242424] hover:bg-[#1A1A1A] text-white font-bold text-xs flex items-center gap-2 shadow-sm transition active:scale-95"
        >
          <Plus className="w-4 h-4 text-[#A89F91]" />
          <span>إضافة شريك جديد</span>
        </button>
      }
    >
      <div className="space-y-8">
        {/* KPI Row */}
        <section className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <MetricCard
            label="عدد الشركاء المسجلين"
            value={`${partners.length} شركاء`}
            icon={Users}
            subtext="حسابات شراكة نشطة وموثقة"
          />

          <MetricCard
            label="إجمالي رأس المال المبدئي"
            value={`${(partners.reduce((sum, p) => sum + p.initialCapital, 0) / 1000000).toFixed(1)}M ج.م`}
            icon={DollarSign}
            subtext="إجمالي مساهمات الشركاء في المشروع"
          />

          <MetricCard
            label="إجمالي المصروفات المطلوب تسويتها"
            value={`${(totalExpenses / 1000000).toFixed(2)}M ج.م`}
            icon={Scale}
            subtext="يتم تقسيمها وفق نسبة رأس مال كل شريك"
          />
        </section>

        {/* Live Partner Settlement Table (Calculator output) */}
        <section className="rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] p-6 shadow-sm space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="font-editorial text-base font-bold text-[#242424] flex items-center gap-2">
                <Scale className="w-5 h-5 text-[#A89F91]" />
                <span>جدول التسوية والتصفية المالية للشركاء (Live Settlement)</span>
              </h3>
              <p className="text-xs text-[#777777] mt-0.5">
                محسوب برمجياً وفق الحصص الرأسمالية والمصروفات الفعلية
              </p>
            </div>
          </div>

          <div className="overflow-x-auto rounded-2xl border border-[#E2DFD8]">
            <table className="w-full text-right text-xs">
              <thead className="bg-[#F4F4F2] text-[#242424] font-bold border-b border-[#E2DFD8]">
                <tr>
                  <th className="p-3.5">اسم الشريك</th>
                  <th className="p-3.5">نسبة الشراكة (%)</th>
                  <th className="p-3.5">ما تم صرفه بالفعل</th>
                  <th className="p-3.5">المستحق عليه نظرياً</th>
                  <th className="p-3.5">موقف التسوية (الرصيد)</th>
                  <th className="p-3.5 text-center">الحالة</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#E2DFD8] text-[#242424]">
                {settlements.map(item => {
                  const isOwed = item.balanceDelta > 0;
                  const isZero = Math.abs(item.balanceDelta) < 1;
                  return (
                    <tr key={item.partnerId} className="hover:bg-[#F4F4F2] transition">
                      <td className="p-3.5 font-bold text-[#242424]">{item.partnerName}</td>
                      <td className="p-3.5 font-mono font-bold text-[#242424]">
                        {Math.round(item.shareRatio * 100)}%
                      </td>
                      <td className="p-3.5 font-mono font-bold text-[#242424]">
                        {item.contributedAmount.toLocaleString()} ج.م
                      </td>
                      <td className="p-3.5 font-mono text-[#777777]">
                        {Math.round(item.expectedContribution).toLocaleString()} ج.م
                      </td>
                      <td className="p-3.5 font-mono font-bold">
                        {isZero ? (
                          <span className="text-[#777777]">0 ج.م</span>
                        ) : isOwed ? (
                          <span className="text-emerald-700">
                            + {Math.round(item.balanceDelta).toLocaleString()} ج.م (له عند الشركاء)
                          </span>
                        ) : (
                          <span className="text-rose-700">
                            - {Math.round(Math.abs(item.balanceDelta)).toLocaleString()} ج.م (مطلوب سداده)
                          </span>
                        )}
                      </td>
                      <td className="p-3.5 text-center">
                        {isZero ? (
                          <span className="px-2.5 py-1 rounded-full bg-[#F4F4F2] text-[#777777] border border-[#E2DFD8] text-[11px] font-semibold">
                            متوازن
                          </span>
                        ) : isOwed ? (
                          <span className="px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-800 border border-emerald-200 text-[11px] font-semibold">
                            دائن (له مستحقات)
                          </span>
                        ) : (
                          <span className="px-2.5 py-1 rounded-full bg-rose-50 text-rose-800 border border-rose-200 text-[11px] font-semibold">
                            مدين (عليه فرق)
                          </span>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </section>

        {/* Partners Cards Grid */}
        <section className="space-y-4">
          <h3 className="font-editorial text-base font-bold text-[#242424]">بيانات الشركاء وحصص رأس المال</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {partners.map(partner => (
              <div
                key={partner.id}
                className="rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] p-6 shadow-sm flex flex-col justify-between"
              >
                <div>
                  <div className="flex items-start justify-between mb-4">
                    <div className="w-12 h-12 rounded-2xl bg-[#242424] text-white flex items-center justify-center font-bold">
                      <Users className="w-6 h-6 text-[#A89F91]" />
                    </div>
                    <span className="px-3 py-1 rounded-full bg-[#F4F4F2] text-[#242424] border border-[#E2DFD8] text-xs font-mono font-bold">
                      حصة {Math.round(partner.shareRatio * 100)}%
                    </span>
                  </div>

                  <h4 className="font-editorial text-base font-bold text-[#242424]">{partner.name}</h4>
                  <p className="text-xs text-[#777777] font-mono mt-0.5">{partner.phone || 'بدون هاتف'}</p>

                  <div className="my-4 p-3 rounded-2xl bg-[#F4F4F2] border border-[#E2DFD8] text-xs space-y-1.5">
                    <div className="flex justify-between">
                      <span className="text-[#777777]">رأس المال المساهم:</span>
                      <strong className="text-[#242424] font-mono">{partner.initialCapital.toLocaleString()} ج.م</strong>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-[#777777]">تاريخ الانضمام:</span>
                      <span className="text-[#242424] font-mono">{partner.joinedDate}</span>
                    </div>
                  </div>
                </div>

                <div className="pt-3 border-t border-[#E2DFD8] flex items-center justify-between text-xs">
                  <span className="text-[#777777]">الحالة: نشط</span>
                  <span className="text-emerald-700 font-bold flex items-center gap-1">
                    <CheckCircle2 className="w-3.5 h-3.5" />
                    تم التوثيق
                  </span>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* Add Partner Modal */}
        {showAddModal && (
          <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
            <div className="w-full max-w-md rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] p-6 space-y-4 shadow-2xl text-[#242424]">
              <div className="flex items-center justify-between pb-3 border-b border-[#E2DFD8]">
                <h3 className="font-editorial text-base font-bold text-[#242424] flex items-center gap-2">
                  <Users className="w-5 h-5 text-[#A89F91]" />
                  <span>إضافة شريك جديد</span>
                </h3>
                <button onClick={() => setShowAddModal(false)} className="text-[#777777] hover:text-[#242424]">
                  <X className="w-5 h-5" />
                </button>
              </div>

              <form onSubmit={handleAddPartner} className="space-y-4 text-xs">
                <div>
                  <label className="block text-[#242424] font-bold mb-1">اسم الشريك</label>
                  <input
                    type="text"
                    required
                    placeholder="مثال: م. طارق السعيد"
                    value={name}
                    onChange={e => setName(e.target.value)}
                    className="w-full px-3 py-2.5 rounded-xl bg-[#F4F4F2] border border-[#E2DFD8] text-[#242424] focus:outline-none focus:border-[#242424]"
                  />
                </div>

                <div>
                  <label className="block text-[#242424] font-bold mb-1">رقم الهاتف</label>
                  <input
                    type="text"
                    placeholder="010..."
                    value={phone}
                    onChange={e => setPhone(e.target.value)}
                    className="w-full px-3 py-2.5 rounded-xl bg-[#F4F4F2] border border-[#E2DFD8] text-[#242424] focus:outline-none focus:border-[#242424] font-mono"
                  />
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-[#242424] font-bold mb-1">نسبة الشراكة (%)</label>
                    <input
                      type="number"
                      required
                      min={1}
                      max={100}
                      value={shareRatio}
                      onChange={e => setShareRatio(Number(e.target.value))}
                      className="w-full px-3 py-2.5 rounded-xl bg-[#F4F4F2] border border-[#E2DFD8] text-[#242424] focus:outline-none focus:border-[#242424] font-mono"
                    />
                  </div>
                  <div>
                    <label className="block text-[#242424] font-bold mb-1">رأس المال (ج.م)</label>
                    <input
                      type="number"
                      required
                      value={initialCapital}
                      onChange={e => setInitialCapital(Number(e.target.value))}
                      className="w-full px-3 py-2.5 rounded-xl bg-[#F4F4F2] border border-[#E2DFD8] text-[#242424] focus:outline-none focus:border-[#242424] font-mono"
                    />
                  </div>
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
                    حفظ الشريك
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
