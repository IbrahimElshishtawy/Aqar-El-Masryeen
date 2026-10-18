'use client';

import React, { useState, useMemo } from 'react';
import { Calendar, DollarSign, ChevronDown } from 'lucide-react';

export function InstallmentCalculatorSection() {
  const [calcPrice, setCalcPrice] = useState<number>(3000000);
  const [calcDownPaymentPercent, setCalcDownPaymentPercent] = useState<number>(20);
  const [calcYears, setCalcYears] = useState<number>(3);
  const [calcFrequency, setCalcFrequency] = useState<'monthly' | 'quarterly'>('quarterly');

  const downPaymentAmount = useMemo(() => {
    return (calcPrice * calcDownPaymentPercent) / 100;
  }, [calcPrice, calcDownPaymentPercent]);

  const remainingAmount = useMemo(() => {
    return Math.max(0, calcPrice - downPaymentAmount);
  }, [calcPrice, downPaymentAmount]);

  const totalInstallmentsCount = useMemo(() => {
    return calcFrequency === 'monthly' ? calcYears * 12 : calcYears * 4;
  }, [calcFrequency, calcYears]);

  const installmentValue = useMemo(() => {
    if (totalInstallmentsCount === 0) return 0;
    return Math.round(remainingAmount / totalInstallmentsCount);
  }, [remainingAmount, totalInstallmentsCount]);

  return (
    <section id="calculator" className="py-16 sm:py-24 bg-[#EBE8E1]/60 border-y border-[#E2DFD8]">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="max-w-3xl mx-auto text-center mb-10 sm:mb-14">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#FFFFFF] text-[#777777] text-xs font-bold mb-3 border border-[#E2DFD8]">
            <Calendar className="w-3.5 h-3.5 text-[#A89F91]" />
            <span>حاسبة السداد المرن</span>
          </div>
          <h2 className="font-editorial text-2xl sm:text-4xl font-black text-[#242424]">
            خطط لسداد وحدتك بشفافية تامة
          </h2>
          <p className="text-xs sm:text-sm text-[#777777] mt-2">
            احسب دفعة المقدم، الأقساط الشهرية أو الربع سنوية بدقة لتحديد الخطة المالية الأنسب لميزانيتك.
          </p>
        </div>

        {/* Responsive Grid: Desktop side-by-side / Mobile stacked */}
        <div className="max-w-4xl mx-auto rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] p-5 sm:p-10 shadow-sm grid grid-cols-1 lg:grid-cols-12 gap-8">
          {/* Controls */}
          <div className="lg:col-span-7 space-y-6">
            <div>
              <div className="flex justify-between text-xs font-bold mb-2">
                <span className="text-[#242424]">سعر الوحدة الإجمالي</span>
                <span className="text-[#A89F91] font-mono">{calcPrice.toLocaleString()} ج.م</span>
              </div>
              <input
                type="range"
                min={1000000}
                max={15000000}
                step={250000}
                value={calcPrice}
                onChange={e => setCalcPrice(Number(e.target.value))}
                className="w-full h-2 bg-[#EBE8E1] rounded-lg appearance-none cursor-pointer accent-[#242424]"
              />
            </div>

            <div>
              <div className="flex justify-between text-xs font-bold mb-2">
                <span className="text-[#242424]">نسبة المقدم ({calcDownPaymentPercent}%)</span>
                <span className="text-[#A89F91] font-mono">{downPaymentAmount.toLocaleString()} ج.م</span>
              </div>
              <input
                type="range"
                min={10}
                max={50}
                step={5}
                value={calcDownPaymentPercent}
                onChange={e => setCalcDownPaymentPercent(Number(e.target.value))}
                className="w-full h-2 bg-[#EBE8E1] rounded-lg appearance-none cursor-pointer accent-[#242424]"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-xs font-bold text-[#242424] block mb-2">مدة التقسيط</label>
                <div className="relative">
                  <select
                    value={calcYears}
                    onChange={e => setCalcYears(Number(e.target.value))}
                    className="w-full p-3 rounded-xl bg-[#F4F4F2] border border-[#E2DFD8] text-xs font-bold text-[#242424] appearance-none"
                  >
                    <option value={1}>سنة واحدة</option>
                    <option value={2}>سنتان</option>
                    <option value={3}>3 سنوات</option>
                    <option value={5}>5 سنوات</option>
                    <option value={7}>7 سنوات</option>
                  </select>
                  <ChevronDown className="w-4 h-4 text-[#777777] absolute left-3 top-3.5 pointer-events-none" />
                </div>
              </div>

              <div>
                <label className="text-xs font-bold text-[#242424] block mb-2">دورية السداد</label>
                <div className="flex p-1 bg-[#F4F4F2] rounded-xl border border-[#E2DFD8]">
                  <button
                    type="button"
                    onClick={() => setCalcFrequency('quarterly')}
                    className={`flex-1 py-2 rounded-lg text-xs font-bold transition ${
                      calcFrequency === 'quarterly'
                        ? 'bg-[#242424] text-white shadow-sm'
                        : 'text-[#777777] hover:text-[#242424]'
                    }`}
                  >
                    ربع سنوي
                  </button>
                  <button
                    type="button"
                    onClick={() => setCalcFrequency('monthly')}
                    className={`flex-1 py-2 rounded-lg text-xs font-bold transition ${
                      calcFrequency === 'monthly'
                        ? 'bg-[#242424] text-white shadow-sm'
                        : 'text-[#777777] hover:text-[#242424]'
                    }`}
                  >
                    شهري
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* Results Summary Card */}
          <div className="lg:col-span-5 rounded-2xl bg-[#242424] text-white p-6 flex flex-col justify-between">
            <div>
              <span className="text-[10px] tracking-widest text-[#A89F91] uppercase font-bold block">
                ملخص خطة السداد المقترحة
              </span>
              <div className="mt-4 pt-4 border-t border-[#333333] space-y-3">
                <div className="flex justify-between items-center text-xs">
                  <span className="text-[#A89F91]">دفعة المقدم المطلوبة:</span>
                  <span className="font-bold font-mono">{downPaymentAmount.toLocaleString()} ج.م</span>
                </div>
                <div className="flex justify-between items-center text-xs">
                  <span className="text-[#A89F91]">المبلغ المتبقي للتقسيط:</span>
                  <span className="font-bold font-mono">{remainingAmount.toLocaleString()} ج.م</span>
                </div>
                <div className="flex justify-between items-center text-xs">
                  <span className="text-[#A89F91]">عدد الأقساط:</span>
                  <span className="font-bold font-mono">{totalInstallmentsCount} قسط</span>
                </div>
              </div>
            </div>

            <div className="mt-6 pt-5 border-t border-[#333333]">
              <span className="text-xs text-[#A89F91] block mb-1">
                قيمة القسط {calcFrequency === 'monthly' ? 'الشهري' : 'الربع سنوي'}:
              </span>
              <div className="text-2xl sm:text-3xl font-black font-mono text-[#F4F4F2]">
                {installmentValue.toLocaleString()}{' '}
                <span className="text-xs text-[#A89F91] font-sans font-normal">ج.م / قسط</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
