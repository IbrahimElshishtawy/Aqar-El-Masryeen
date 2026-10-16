'use client';

import React from 'react';
import { LucideIcon } from 'lucide-react';

export interface MetricCardProps {
  label: string;
  value: string;
  icon: LucideIcon;
  subtext?: string;
  color?: 'blue' | 'emerald' | 'amber' | 'purple' | 'rose';
  trend?: string;
  className?: string;
}

export function MetricCard({
  label,
  value,
  icon: Icon,
  subtext,
  color = 'blue',
  trend,
  className = '',
}: MetricCardProps) {
  const colorStyles = {
    blue: {
      border: 'border-blue-500/20 hover:border-blue-500/40',
      gradient: 'from-blue-600/10 to-transparent',
      iconBg: 'bg-blue-600/15 text-blue-400',
      dot: 'bg-blue-500 ring-blue-500/20',
    },
    emerald: {
      border: 'border-emerald-500/20 hover:border-emerald-500/40',
      gradient: 'from-emerald-600/10 to-transparent',
      iconBg: 'bg-emerald-600/15 text-emerald-400',
      dot: 'bg-emerald-500 ring-emerald-500/20',
    },
    amber: {
      border: 'border-amber-500/20 hover:border-amber-500/40',
      gradient: 'from-amber-600/10 to-transparent',
      iconBg: 'bg-amber-600/15 text-amber-400',
      dot: 'bg-amber-500 ring-amber-500/20',
    },
    purple: {
      border: 'border-purple-500/20 hover:border-purple-500/40',
      gradient: 'from-purple-600/10 to-transparent',
      iconBg: 'bg-purple-600/15 text-purple-400',
      dot: 'bg-purple-500 ring-purple-500/20',
    },
    rose: {
      border: 'border-rose-500/20 hover:border-rose-500/40',
      gradient: 'from-rose-600/10 to-transparent',
      iconBg: 'bg-rose-600/15 text-rose-400',
      dot: 'bg-rose-500 ring-rose-500/20',
    },
  };

  const style = colorStyles[color];

  return (
    <div
      className={`relative overflow-hidden rounded-3xl p-5 border bg-slate-900/80 backdrop-blur-sm bg-gradient-to-br ${style.gradient} ${style.border} shadow-lg shadow-black/20 hover:shadow-xl transition-all duration-300 flex flex-col justify-between group ${className}`}
      dir="rtl"
    >
      <div className="flex items-center justify-between mb-4">
        <div className={`w-11 h-11 rounded-2xl ${style.iconBg} flex items-center justify-center font-bold shadow-inner transition group-hover:scale-105 duration-300`}>
          <Icon className="w-5 h-5" />
        </div>
        <div className={`w-2.5 h-2.5 rounded-full ${style.dot} ring-4 animate-pulse`} />
      </div>

      <div className="space-y-1.5">
        <p className="text-xs font-bold text-slate-400 tracking-wide line-clamp-1">{label}</p>
        <h3 className="text-2xl md:text-3xl font-black text-white tracking-tight font-mono">{value}</h3>
        {subtext && <p className="text-[11px] text-slate-400 font-medium">{subtext}</p>}
        {trend && <p className="text-[11px] text-emerald-400 font-bold">{trend}</p>}
      </div>
    </div>
  );
}

export default MetricCard;
