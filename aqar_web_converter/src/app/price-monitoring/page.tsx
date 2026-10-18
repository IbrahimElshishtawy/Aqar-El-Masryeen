'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import {
  TrendingUp,
  TrendingDown,
  Building2,
  Search,
  Filter,
  DollarSign,
  History,
  Calendar,
  Layers,
  ArrowRight,
  Plus,
  Edit3,
  X,
  CheckCircle2,
  AlertCircle,
  Clock,
  ShieldCheck,
  User,
} from 'lucide-react';
import AppShell from '@/components/layout/AppShell';
import MetricCard from '@/components/ui/MetricCard';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { PriceMetric } from '@/lib/price-monitoring/engine';
import { PriceHistoryRecord, PropertyProject } from '@/types';

export default function PriceMonitoringPage() {
  const [metrics, setMetrics] = useState<PriceMetric[]>([]);
  const [history, setHistory] = useState<PriceHistoryRecord[]>([]);
  const [projects, setProjects] = useState<PropertyProject[]>([]);
  const [loading, setLoading] = useState(true);
  const [userRole, setUserRole] = useState<string>('admin');

  // Filters
  const [propertyFilter, setPropertyFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');
  const [search, setSearch] = useState('');

  // Price Edit Modal State
  const [selectedUnit, setSelectedUnit] = useState<PriceMetric | null>(null);
  const [newPrice, setNewPrice] = useState<number>(0);
  const [changeReason, setChangeReason] = useState<string>('');
  const [modalSubmitting, setModalSubmitting] = useState(false);
  const [modalError, setModalError] = useState('');
  const [successMessage, setSuccessMessage] = useState('');

  const loadData = async () => {
    try {
      setLoading(true);
      const res = await fetch('/api/price-monitoring');
      if (!res.ok) throw new Error('فشل جلب بيانات رصد الأسعار');
      const json = await res.json();
      setMetrics(json.data.metrics || []);
      setHistory(json.data.history || []);

      // Also get project names
      const dataRes = await fetch('/api/accounting/data');
      if (dataRes.ok) {
        const dataJson = await dataRes.json();
        setProjects(dataJson.data.projects || []);
        setUserRole(dataJson.user.role || 'admin');
      }
    } catch (err: any) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleOpenEditModal = (metric: PriceMetric) => {
    setSelectedUnit(metric);
    setNewPrice(metric.currentAskingPrice);
    setChangeReason('');
    setModalError('');
  };

  const handleUpdatePrice = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedUnit) return;
    setModalError('');
    setModalSubmitting(true);

    try {
      const res = await fetch('/api/price-monitoring', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          unitId: selectedUnit.unitId,
          newPrice: Number(newPrice),
          reason: changeReason,
        }),
      });

      const json = await res.json();
      if (!res.ok) {
        throw new Error(json.error || 'فشل تحديث السعر');
      }

      setSuccessMessage('تم تحديث سعر الوحدة بنجاح وتوثيق التغيير في سجل الأسعار التاريخي.');
      setSelectedUnit(null);
      await loadData();
      setTimeout(() => setSuccessMessage(''), 4000);
    } catch (err: any) {
      setModalError(err.message || 'حدث خطأ أثناء حفظ السعر الجديد');
    } finally {
      setModalSubmitting(false);
    }
  };

  const filteredMetrics = metrics.filter(m => {
    const matchProp = propertyFilter === 'all' || m.propertyId === propertyFilter;
    const matchStatus = statusFilter === 'all' || m.status === statusFilter;
    const matchSearch =
      m.unitNumber.includes(search) ||
      m.propertyName.includes(search) ||
      m.unitType.includes(search);
    return matchProp && matchStatus && matchSearch;
  });

  const totalAskingValue = metrics.reduce((sum, m) => sum + m.currentAskingPrice, 0);
  const avgMeterPrice =
    metrics.length > 0
      ? Math.round(metrics.reduce((sum, m) => sum + m.pricePerMeter, 0) / metrics.length)
      : 0;
  const recentChangesCount = history.length;

  return (
    <AppShell
      title="منظومة رصد أسعار العقارات والوحدات"
      subtitle="متابعة الأسعار المعروضة، تاريخ التغيرات السعرية، الفارق المئوي، ومقارنة متوسط سعر المتر"
      actions={
        <div className="flex items-center gap-2">
          <button
            onClick={() => loadData()}
            className="px-3.5 py-2 rounded-xl bg-[#FFFFFF] border border-[#E2DFD8] text-xs font-bold text-[#242424] hover:bg-[#F4F4F2] transition flex items-center gap-1.5"
          >
            <Clock className="w-4 h-4 text-[#777777]" />
            <span>تحديث البيانات</span>
          </button>
        </div>
      }
    >
      <div className="space-y-8">
        {/* Success Alert */}
        {successMessage && (
          <div className="p-4 rounded-2xl bg-emerald-50 border border-emerald-300 text-emerald-900 text-xs font-bold flex items-center gap-2 animate-in fade-in">
            <CheckCircle2 className="w-5 h-5 text-emerald-600" />
            <span>{successMessage}</span>
          </div>
        )}

        {/* Note banner distinguishing Asking Price from Realized Sales */}
        <div className="p-4 rounded-2xl bg-[#EBE8E1] border border-[#D5D0C6] text-[#242424] text-xs flex items-start gap-3">
          <ShieldCheck className="w-5 h-5 text-[#A89F91] shrink-0 mt-0.5" />
          <div className="leading-relaxed">
            <span className="font-bold">قاعدة محاسبية صارمة: </span>
            تُعامل الأسعار المرصودة في هذا القسم كأسعار طلب استرشادية (Asking Prices). لا تُعتبر أي زيادة أو تخفيض في سعر الوحدة المعروضة إيراداً أو ربحاً محققاً للشركة أو الشركاء إلا عند إتمام التعاقد الفعلي وتحصيل الدفعات رسمياً.
          </div>
        </div>

        {/* Metrics Row */}
        <section className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <MetricCard
            label="إجمالي القيمة السوقية المعروضة"
            value={`${(totalAskingValue / 1000000).toFixed(2)}M ج.م`}
            icon={TrendingUp}
            subtext="إجمالي أسعار كافة الوحدات المسجلة"
          />

          <MetricCard
            label="متوسط سعر المتر الاسترشادي"
            value={`${avgMeterPrice.toLocaleString()} ج.م / م²`}
            icon={DollarSign}
            subtext="محتسب بناءً على المساحات الفعلية"
          />

          <MetricCard
            label="حركات تعديل الأسعار الموثقة"
            value={`${recentChangesCount} تعديلات`}
            icon={History}
            subtext="تخضع للرقابة والتدقيق الأمني"
          />
        </section>

        {/* Filters & Search Bar */}
        <section className="p-5 rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] shadow-sm flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="relative w-full sm:w-80">
            <Search className="w-4 h-4 text-[#777777] absolute right-3.5 top-3.5" />
            <input
              type="text"
              placeholder="بحث برقم الوحدة، المشروع، أو النوع..."
              value={search}
              onChange={e => setSearch(e.target.value)}
              className="w-full pr-10 pl-4 py-2.5 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] placeholder-[#777777] focus:outline-none focus:border-[#242424]"
            />
          </div>

          <div className="flex flex-wrap items-center gap-3 w-full sm:w-auto">
            {/* Property Filter */}
            <select
              value={propertyFilter}
              onChange={e => setPropertyFilter(e.target.value)}
              className="px-3 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs font-semibold text-[#242424] focus:outline-none"
            >
              <option value="all">كافة المشروعات</option>
              {projects.map(p => (
                <option key={p.id} value={p.id}>
                  {p.name}
                </option>
              ))}
            </select>

            {/* Status Filter */}
            <select
              value={statusFilter}
              onChange={e => setStatusFilter(e.target.value)}
              className="px-3 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs font-semibold text-[#242424] focus:outline-none"
            >
              <option value="all">كافة حالات الوحدات</option>
              <option value="available">متاحة للبيع</option>
              <option value="reserved">محجوزة</option>
              <option value="sold">مباعة</option>
            </select>
          </div>
        </section>

        {/* Live Units Price Table */}
        <section className="rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] p-6 shadow-sm space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="font-editorial text-base font-bold text-[#242424] flex items-center gap-2">
              <Building2 className="w-5 h-5 text-[#A89F91]" />
              <span>جدول رصد الأسعار الحالية والمقارنة التاريخية للوحدات</span>
            </h3>
            <span className="text-xs text-[#777777]">{filteredMetrics.length} وحدة مطابقة</span>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-right text-xs">
              <thead className="bg-[#F4F4F2] text-[#777777] border-b border-[#E2DFD8]">
                <tr>
                  <th className="py-3 px-4 font-bold">الوحدة والمشروع</th>
                  <th className="py-3 px-4 font-bold">المساحة</th>
                  <th className="py-3 px-4 font-bold">السعر المعروض الحالي</th>
                  <th className="py-3 px-4 font-bold">سعر المتر</th>
                  <th className="py-3 px-4 font-bold">السعر السابق</th>
                  <th className="py-3 px-4 font-bold">نسبة التغير</th>
                  <th className="py-3 px-4 font-bold">الحالة</th>
                  <th className="py-3 px-4 font-bold">إجراءات</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#E2DFD8]">
                {filteredMetrics.map(metric => {
                  const hasChanged = metric.absoluteChange !== 0;
                  const isUp = metric.absoluteChange > 0;

                  return (
                    <tr key={metric.unitId} className="hover:bg-[#FAF9F6] transition">
                      <td className="py-3.5 px-4">
                        <span className="font-bold text-[#242424] block">وحدة {metric.unitNumber}</span>
                        <span className="text-[10px] text-[#777777]">{metric.propertyName}</span>
                      </td>

                      <td className="py-3.5 px-4 font-medium text-[#242424]">
                        {metric.areaSqm} م²
                      </td>

                      <td className="py-3.5 px-4 font-black text-[#242424]">
                        {metric.currentAskingPrice.toLocaleString()} ج.م
                      </td>

                      <td className="py-3.5 px-4 text-[#777777]">
                        {metric.pricePerMeter.toLocaleString()} ج.م
                      </td>

                      <td className="py-3.5 px-4 text-[#777777]">
                        {metric.previousPrice.toLocaleString()} ج.م
                      </td>

                      <td className="py-3.5 px-4">
                        {hasChanged ? (
                          <span
                            className={`inline-flex items-center gap-1 font-bold px-2 py-0.5 rounded-full text-[10px] ${
                              isUp
                                ? 'bg-emerald-100 text-emerald-800'
                                : 'bg-rose-100 text-rose-800'
                            }`}
                          >
                            {isUp ? <TrendingUp className="w-3 h-3" /> : <TrendingDown className="w-3 h-3" />}
                            <span>{Math.abs(metric.percentageChange)}%</span>
                          </span>
                        ) : (
                          <span className="text-[#999999] text-[11px]">- لا تغيير -</span>
                        )}
                      </td>

                      <td className="py-3.5 px-4">
                        <StatusBadge status={metric.status} />
                      </td>

                      <td className="py-3.5 px-4">
                        {userRole === 'admin' || userRole === 'accountant' ? (
                          <button
                            onClick={() => handleOpenEditModal(metric)}
                            className="px-3 py-1.5 rounded-xl bg-[#242424] hover:bg-[#1A1A1A] text-white font-bold text-[11px] transition flex items-center gap-1 shadow-sm"
                          >
                            <Edit3 className="w-3 h-3 text-[#A89F91]" />
                            <span>تعديل السعر</span>
                          </button>
                        ) : (
                          <span className="text-[10px] text-[#999999]">للمشاهدة فقط</span>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </section>

        {/* Historical Price Audit Log */}
        <section className="rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] p-6 shadow-sm space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="font-editorial text-base font-bold text-[#242424] flex items-center gap-2">
              <History className="w-5 h-5 text-[#A89F91]" />
              <span>سجل التدقيق التاريخي لحركات تعديل الأسعار (Audit Trail)</span>
            </h3>
            <span className="text-xs text-[#777777]">{history.length} سجلات موثقة</span>
          </div>

          <div className="space-y-3">
            {history.map(record => (
              <div
                key={record.id}
                className="p-4 rounded-2xl bg-[#F4F4F2] border border-[#E2DFD8] flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs"
              >
                <div>
                  <div className="flex items-center gap-2 mb-1">
                    <span className="font-bold text-[#242424]">وحدة {record.unitNumber} - {record.propertyName}</span>
                    <span
                      className={`font-bold px-2 py-0.5 rounded-full text-[10px] ${
                        record.absoluteChange >= 0
                          ? 'bg-emerald-100 text-emerald-800'
                          : 'bg-rose-100 text-rose-800'
                      }`}
                    >
                      {record.absoluteChange >= 0 ? `+${record.percentageChange}%` : `${record.percentageChange}%`}
                    </span>
                  </div>
                  <p className="text-[11px] text-[#555555]">
                    السبب: {record.reason || 'تحديث دوري لأسعار السوق'}
                  </p>
                </div>

                <div className="text-left sm:text-left text-[#777777] text-[11px] space-y-1">
                  <div>
                    <span>السابق: {record.previousPrice.toLocaleString()} ج.م</span>
                    <span className="mx-2">←</span>
                    <span className="font-bold text-[#242424]">الجديد: {record.newPrice.toLocaleString()} ج.م</span>
                  </div>
                  <div className="flex items-center gap-2 text-[10px]">
                    <span className="flex items-center gap-1">
                      <User className="w-3 h-3 text-[#A89F91]" />
                      <span>المسؤول: {record.changedByName}</span>
                    </span>
                    <span>•</span>
                    <span>التاريخ: {new Date(record.timestamp).toLocaleDateString('ar-EG')}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </section>
      </div>

      {/* Edit Price Modal */}
      {selectedUnit && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-[#FFFFFF] border border-[#E2DFD8] rounded-3xl max-w-lg w-full p-6 shadow-2xl relative animate-in zoom-in-95 duration-200">
            <button
              onClick={() => setSelectedUnit(null)}
              className="absolute left-6 top-6 p-1.5 rounded-xl text-[#777777] hover:bg-[#F4F4F2] transition"
            >
              <X className="w-5 h-5" />
            </button>

            <div className="mb-4">
              <h3 className="font-editorial text-lg font-bold text-[#242424]">تعديل سعر الوحدة وتوثيق التغيير</h3>
              <p className="text-xs text-[#777777] mt-0.5">
                وحدة {selectedUnit.unitNumber} | {selectedUnit.propertyName}
              </p>
            </div>

            {modalError && (
              <div className="mb-4 p-3 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-xs flex items-center gap-2">
                <AlertCircle className="w-4 h-4 shrink-0" />
                <span>{modalError}</span>
              </div>
            )}

            <form onSubmit={handleUpdatePrice} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-[#242424] mb-1">السعر الحالي</label>
                <div className="p-3 bg-[#F4F4F2] rounded-xl text-xs font-bold text-[#777777]">
                  {selectedUnit.currentAskingPrice.toLocaleString()} ج.م ({selectedUnit.pricePerMeter.toLocaleString()} ج.م/م²)
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-[#242424] mb-1">السعر الجديد المطلوب (ج.م)</label>
                <input
                  type="number"
                  required
                  min={100000}
                  step={10000}
                  value={newPrice}
                  onChange={e => setNewPrice(Number(e.target.value))}
                  className="w-full px-4 py-2.5 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs font-bold text-[#242424] focus:outline-none focus:border-[#242424]"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-[#242424] mb-1">سبب التعديل (إلزامي للتدقيق المالي)</label>
                <textarea
                  required
                  rows={2}
                  placeholder="مثال: زيادة أسعار الحديد والأسمنت، أو ترقية باقة التشطيب، أو تحديث تسعير السوق..."
                  value={changeReason}
                  onChange={e => setChangeReason(e.target.value)}
                  className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] placeholder-[#777777] focus:outline-none focus:border-[#242424]"
                />
              </div>

              {/* Price Difference Preview */}
              <div className="p-3 rounded-xl bg-[#FAF9F6] border border-[#E2DFD8] text-xs space-y-1">
                <div className="flex justify-between text-[#777777]">
                  <span>الفارق المالي المطلق:</span>
                  <span className="font-bold text-[#242424]">
                    {(newPrice - selectedUnit.currentAskingPrice).toLocaleString()} ج.م
                  </span>
                </div>
                <div className="flex justify-between text-[#777777]">
                  <span>نسبة التغير:</span>
                  <span className="font-bold text-[#242424]">
                    {selectedUnit.currentAskingPrice > 0
                      ? (((newPrice - selectedUnit.currentAskingPrice) / selectedUnit.currentAskingPrice) * 100).toFixed(2)
                      : 0}
                    %
                  </span>
                </div>
              </div>

              <div className="pt-2 flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setSelectedUnit(null)}
                  className="px-4 py-2 rounded-xl text-xs font-bold text-[#777777] hover:bg-[#F4F4F2] transition"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  disabled={modalSubmitting || newPrice <= 0}
                  className="px-5 py-2.5 rounded-xl bg-[#242424] hover:bg-[#1A1A1A] text-white font-bold text-xs transition disabled:opacity-50"
                >
                  {modalSubmitting ? 'جاري الحفظ والتوثيق...' : 'اعتماد وتوثيق التغيير'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </AppShell>
  );
}
