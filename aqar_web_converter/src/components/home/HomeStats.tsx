import React from 'react';

export function HomeStats() {
  const stats = [
    { value: '156M+', label: 'إجمالي مبيعات المشروعات' },
    { value: '76', label: 'وحدة عقارية راقية' },
    { value: '98.6%', label: 'نسبة الالتزام والتحصيل' },
    { value: '100%', label: 'دقة محاسبية مشددة' },
  ];

  return (
    <div className="max-w-5xl mx-auto px-4 -mt-8 relative z-20">
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4">
        {stats.map((stat, i) => (
          <div
            key={i}
            className="p-4 sm:p-5 rounded-2xl bg-[#FFFFFF] border border-[#E2DFD8] text-center shadow-sm"
          >
            <span className="font-editorial text-2xl sm:text-3xl font-black text-[#242424] block font-mono">
              {stat.value}
            </span>
            <span className="text-[11px] sm:text-xs font-semibold text-[#777777] mt-1 block">
              {stat.label}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}
