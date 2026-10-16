'use client';

import React from 'react';
import {
  PropertyStatus,
  PropertyStatusLabels,
  UnitStatus,
  UnitStatusLabels,
  InstallmentStatus,
  InstallmentStatusLabels,
} from '@/types';

interface StatusBadgeProps {
  status: PropertyStatus | UnitStatus | InstallmentStatus | string;
  type?: 'property' | 'unit' | 'installment';
}

export function StatusBadge({ status, type = 'installment' }: StatusBadgeProps) {
  let label = status;
  let color = 'bg-slate-800 text-slate-300 border-slate-700';

  if (status === InstallmentStatus.Paid || status === UnitStatus.Sold || status === PropertyStatus.Delivered) {
    color = 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30';
  } else if (status === InstallmentStatus.Overdue || status === UnitStatus.Cancelled) {
    color = 'bg-rose-500/15 text-rose-400 border-rose-500/30';
  } else if (status === InstallmentStatus.Pending || status === UnitStatus.Reserved || status === PropertyStatus.Planning) {
    color = 'bg-amber-500/15 text-amber-400 border-amber-500/30';
  } else if (status === PropertyStatus.Active || status === UnitStatus.Available) {
    color = 'bg-blue-500/15 text-blue-400 border-blue-500/30';
  }

  // Label resolving
  if (type === 'property' && PropertyStatusLabels[status as PropertyStatus]) {
    label = PropertyStatusLabels[status as PropertyStatus];
  } else if (type === 'unit' && UnitStatusLabels[status as UnitStatus]) {
    label = UnitStatusLabels[status as UnitStatus];
  } else if (type === 'installment' && InstallmentStatusLabels[status as InstallmentStatus]) {
    label = InstallmentStatusLabels[status as InstallmentStatus];
  }

  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold border ${color}`}>
      {label}
    </span>
  );
}
