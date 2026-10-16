'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import {
  Building2,
  ArrowRight,
  Plus,
  MapPin,
  TrendingUp,
  DollarSign,
  Users,
  CheckCircle2,
  Receipt,
  Calendar,
  X
} from 'lucide-react';
import AppShell from '@/components/layout/AppShell';
import MetricCard from '@/components/ui/MetricCard';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { initialProjects, initialUnits, initialExpenses, initialInstallments } from '@/services/store';
import { PropertyFinancialSummary } from '@/services/calculators';
import { UnitSale, UnitType, UnitStatus, UnitTypeLabels } from '@/types';

export default function PropertyDetailPage() {
  return (
    <React.Suspense fallback={<div className="min-h-screen bg-slate-950 p-8 text-center text-slate-400">جاري تحميل بيانات المشروع...</div>}>
      <PropertyDetailContent />
    </React.Suspense>
  );
}

function PropertyDetailContent() {
  const params = useParams();
  const propertyId = (params?.id as string) || 'prop-1';

  const project = initialProjects.find(p => p.id === propertyId) || initialProjects[0];
  const [units, setUnits] = useState<UnitSale[]>(initialUnits.filter(u => u.propertyId === project.id));
  const [showAddUnitModal, setShowAddUnitModal] = useState(false);

  // New unit form
  const [unitNumber, setUnitNumber] = useState('');
  const [unitType, setUnitType] = useState<UnitType>(UnitType.Apartment);
  const [floor, setFloor] = useState(1);
  const [areaSqm, setAreaSqm] = useState(150);
  const [salePrice, setSalePrice] = useState(2500000);
  const [downPayment, setDownPayment] = useState(500000);
  const [customerName, setCustomerName] = useState('');
  const [customerPhone, setCustomerPhone] = useState('');

  const summary = PropertyFinancialSummary.calculate(
    project,
    units,
    initialExpenses,
    initialInstallments
  );

  const handleAddUnit = (e: React.FormEvent) => {
    e.preventDefault();
    const newUnit: UnitSale = {
      id: `unit-${Date.now()}`,
      propertyId: project.id,
      unitNumber,
      unitType,
      floor: Number(floor),
      areaSqm: Number(areaSqm),
      salePrice: Number(salePrice),
      downPayment: Number(downPayment),
      customerName,
      customerPhone,
      status: customerName ? UnitStatus.Sold : UnitStatus.Available,
      contractDate: customerName ? new Date().toISOString().split('T')[0] : '',
    };

    setUnits([newUnit, ...units]);
    setShowAddUnitModal(false);
    setUnitNumber('');
    setCustomerName('');
    setCustomerPhone('');
  };

  return (
    <AppShell
      title={`مشروع: ${project.name}`}
      subtitle={`${project.location} | إجمالي الوحدات: ${project.apartmentCount}`}
      actions={
        <div className="flex items-center gap-2">
          <Link
            href="/properties"
            className="px-3.5 py-2 rounded-xl bg-[#F4F4F2] hover:bg-[#EAE8E2] text-[#242424] border border-[#E2DFD8] text-xs font-bold transition flex items-center gap-1.5"
          >
            <ArrowRight className="w-4 h-4" />
            <span>العودة للمشروعات</span>
          </Link>
          <button
            onClick={() => setShowAddUnitModal(true)}
            className="px-4 py-2 rounded-xl bg-[#242424] hover:bg-[#1A1A1A] text-white font-bold text-xs flex items-center gap-2 shadow-sm transition"
          >
            <Plus className="w-4 h-4 text-[#A89F91]" />
            <span>إضافة وحدة</span>
          </button>
        </div>
      }
    >
      <div className="space-y-8">
        {/* Metric Cards Row */}
        <section className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <MetricCard
            label="الوحدات المباعة"
            value={`${summary.totalSoldUnits} من ${project.apartmentCount}`}
            icon={Building2}
            color="editorial"
            subtext={`متبقي ${summary.remainingUnits} وحدة متاحة`}
          />

          <MetricCard
            label="إجمالي المبيعات المحققة"
            value={`${(summary.totalSalesValue / 1000000).toFixed(2)}M ج.م`}
            icon={TrendingUp}
            color="editorial"
            subtext={`نسبة التحصيل: ${summary.collectionPercentage}%`}
          />

          <MetricCard
            label="التحصيلات النقدية"
            value={`${(summary.totalCollections / 1000000).toFixed(2)}M ج.م`}
            icon={DollarSign}
            color="editorial"
            subtext="مقدمات وأقساط مسددة"
          />

          <MetricCard
            label="صافي التدفق المالي"
            value={`${(summary.netProfit / 1000000).toFixed(2)}M ج.م`}
            icon={Receipt}
            color="editorial"
            subtext="بعد خصم المصروفات المنفذة"
          />
        </section>

        {/* Units Table Section */}
        <section className="rounded-2xl bg-white border border-[#E2DFD8] p-6 shadow-sm space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-base font-bold text-[#242424]">جدول الوحدات العقارية بالمشروع</h3>
              <p className="text-xs text-[#777777]">سجل الوحدات، العملاء، ومواصفات الشقق والأسعار</p>
            </div>
            <span className="text-xs font-semibold px-3 py-1 rounded-full bg-[#F4F4F2] border border-[#E2DFD8] text-[#242424]">
              {units.length} وحدة مسجلة
            </span>
          </div>

          <div className="overflow-x-auto rounded-xl border border-[#E2DFD8]">
            <table className="w-full text-right text-xs">
              <thead className="bg-[#F4F4F2] text-[#777777] font-bold border-b border-[#E2DFD8]">
                <tr>
                  <th className="p-3.5">رقم الوحدة</th>
                  <th className="p-3.5">النوع</th>
                  <th className="p-3.5">الدور</th>
                  <th className="p-3.5">المساحة</th>
                  <th className="p-3.5">سعر الوحدة</th>
                  <th className="p-3.5">المقدم</th>
                  <th className="p-3.5">اسم المشتري / العميل</th>
                  <th className="p-3.5">الحالة</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#E2DFD8] text-[#242424]">
                {units.map(unit => (
                  <tr key={unit.id} className="hover:bg-[#F9F9F8] transition">
                    <td className="p-3.5 font-bold font-mono text-[#242424]">{unit.unitNumber}</td>
                    <td className="p-3.5">{UnitTypeLabels[unit.unitType]}</td>
                    <td className="p-3.5 font-mono">{unit.floor}</td>
                    <td className="p-3.5 font-mono">{unit.areaSqm} م²</td>
                    <td className="p-3.5 font-mono font-bold text-[#242424]">
                      {unit.salePrice.toLocaleString()} ج.م
                    </td>
                    <td className="p-3.5 font-mono text-[#777777]">
                      {unit.downPayment.toLocaleString()} ج.م
                    </td>
                    <td className="p-3.5">
                      {unit.customerName ? (
                        <div>
                          <p className="font-bold text-[#242424]">{unit.customerName}</p>
                          <p className="text-[10px] text-[#777777] font-mono">{unit.customerPhone}</p>
                        </div>
                      ) : (
                        <span className="text-[#A89F91] italic">غير محجوز</span>
                      )}
                    </td>
                    <td className="p-3.5">
                      <StatusBadge status={unit.status} type="unit" />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>

        {/* Add Unit Modal */}
        {showAddUnitModal && (
          <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
            <div className="w-full max-w-lg rounded-2xl bg-white border border-[#E2DFD8] p-6 space-y-4 shadow-xl">
              <div className="flex items-center justify-between pb-3 border-b border-[#E2DFD8]">
                <h3 className="text-base font-bold text-[#242424] flex items-center gap-2">
                  <Building2 className="w-5 h-5 text-[#A89F91]" />
                  إضافة وحدة جديدة للمشروع
                </h3>
                <button onClick={() => setShowAddUnitModal(false)} className="text-[#777777] hover:text-[#242424]">
                  <X className="w-5 h-5" />
                </button>
              </div>

              <form onSubmit={handleAddUnit} className="space-y-4 text-xs">
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-[#242424] font-bold mb-1">رقم الوحدة</label>
                    <input
                      type="text"
                      required
                      placeholder="مثال: A-301"
                      value={unitNumber}
                      onChange={e => setUnitNumber(e.target.value)}
                      className="w-full px-3 py-2 rounded-xl bg-[#F4F4F2] border border-[#E2DFD8] text-[#242424] focus:outline-none focus:border-[#242424] font-mono"
                    />
                  </div>
                  <div>
                    <label className="block text-[#242424] font-bold mb-1">نوع الوحدة</label>
                    <select
                      value={unitType}
                      onChange={e => setUnitType(e.target.value as UnitType)}
                      className="w-full px-3 py-2 rounded-xl bg-[#F4F4F2] border border-[#E2DFD8] text-[#242424] focus:outline-none focus:border-[#242424]"
                    >
                      <option value={UnitType.Apartment}>شقة</option>
                      <option value={UnitType.Penthouse}>بنتهاوس</option>
                      <option value={UnitType.Office}>مكتب إداري</option>
                      <option value={UnitType.Retail}>محل تجاري</option>
                    </select>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-[#242424] font-bold mb-1">الدور</label>
                    <input
                      type="number"
                      required
                      value={floor}
                      onChange={e => setFloor(Number(e.target.value))}
                      className="w-full px-3 py-2 rounded-xl bg-[#F4F4F2] border border-[#E2DFD8] text-[#242424] focus:outline-none focus:border-[#242424]"
                    />
                  </div>
                  <div>
                    <label className="block text-[#242424] font-bold mb-1">المساحة (م²)</label>
                    <input
                      type="number"
                      required
                      value={areaSqm}
                      onChange={e => setAreaSqm(Number(e.target.value))}
                      className="w-full px-3 py-2 rounded-xl bg-[#F4F4F2] border border-[#E2DFD8] text-[#242424] focus:outline-none focus:border-[#242424]"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-[#242424] font-bold mb-1">سعر البيع الإجمالي</label>
                    <input
                      type="number"
                      required
                      value={salePrice}
                      onChange={e => setSalePrice(Number(e.target.value))}
                      className="w-full px-3 py-2 rounded-xl bg-[#F4F4F2] border border-[#E2DFD8] text-[#242424] focus:outline-none focus:border-[#242424] font-mono"
                    />
                  </div>
                  <div>
                    <label className="block text-[#242424] font-bold mb-1">مقدم التعاقد</label>
                    <input
                      type="number"
                      value={downPayment}
                      onChange={e => setDownPayment(Number(e.target.value))}
                      className="w-full px-3 py-2 rounded-xl bg-[#F4F4F2] border border-[#E2DFD8] text-[#242424] focus:outline-none focus:border-[#242424] font-mono"
                    />
                  </div>
                </div>

                <div className="pt-2 border-t border-[#E2DFD8]">
                  <p className="text-[11px] text-[#777777] font-bold mb-2">بيانات العميل (اختياري - في حالة الحجز):</p>
                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="block text-[#242424] font-bold mb-1">اسم العميل</label>
                      <input
                        type="text"
                        placeholder="اسم المشتري"
                        value={customerName}
                        onChange={e => setCustomerName(e.target.value)}
                        className="w-full px-3 py-2 rounded-xl bg-[#F4F4F2] border border-[#E2DFD8] text-[#242424] focus:outline-none focus:border-[#242424]"
                      />
                    </div>
                    <div>
                      <label className="block text-[#242424] font-bold mb-1">رقم الهاتف</label>
                      <input
                        type="text"
                        placeholder="010..."
                        value={customerPhone}
                        onChange={e => setCustomerPhone(e.target.value)}
                        className="w-full px-3 py-2 rounded-xl bg-[#F4F4F2] border border-[#E2DFD8] text-[#242424] focus:outline-none focus:border-[#242424] font-mono"
                      />
                    </div>
                  </div>
                </div>

                <div className="flex items-center justify-end gap-3 pt-3 border-t border-[#E2DFD8]">
                  <button
                    type="button"
                    onClick={() => setShowAddUnitModal(false)}
                    className="px-4 py-2 rounded-xl text-[#777777] hover:text-[#242424]"
                  >
                    إلغاء
                  </button>
                  <button
                    type="submit"
                    className="px-5 py-2 rounded-xl bg-[#242424] hover:bg-[#1A1A1A] text-white font-bold transition shadow-sm"
                  >
                    حفظ الوحدة
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
