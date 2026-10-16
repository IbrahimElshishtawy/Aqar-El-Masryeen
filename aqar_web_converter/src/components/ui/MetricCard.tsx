'use client';

import React from 'react';
import { LucideIcon } from 'lucide-react';

export interface MetricCardProps {
  label: string;
  value: string;
  icon: LucideIcon;
  subtext?: string;
  color?: 'blue' | 'emerald' | 'amber' | 'purple' | 'rose' | 'editorial';
  trend?: string;
  className?: string;
}

export function MetricCard({
  label,
  value,
  icon: Icon,
  subtext,
  color = 'editorial',
  trend,
  className = '',
}: MetricCardProps) {
  return (
    <div
      className={`relative overflow-hidden rounded-3xl p-5 border border-[#E2DFD8] bg-[#FFFFFF] shadow-sm hover:shadow-md transition-all duration-300 flex flex-col justify-between group ${className}`}
      dir="rtl"
    >
      <div className="flex items-center justify-between mb-4">
        <div className="w-11 h-11 rounded-2xl bg-[#F4F4F2] border border-[#E2DFD8] flex items-center justify-center text-[#242424] font-bold shadow-inner transition group-hover:scale-105 duration-300 group-hover:bg-[#242424] group-hover:text-white">
          <Icon className="w-5 h-5" />
        </div>
        <div className="w-2.5 h-2.5 rounded-full bg-[#A89F91] ring-4 ring-[#A89F91]/20 animate-pulse" />
      </div>

      <div className="space-y-1.5">
        <p className="text-xs font-bold text-[#777777] tracking-wide line-clamp-1">{label}</p>
        <h3 className="font-editorial text-2xl md:text-3xl font-black text-[#242424] tracking-tight font-mono">{value}</h3>
        {subtext && <p className="text-[11px] text-[#777777] font-medium">{subtext}</p>}
        {trend && <p className="text-[11px] text-[#242424] font-bold">{trend}</p>}
      </div>
    </div>
  );
}

export default MetricCard;

