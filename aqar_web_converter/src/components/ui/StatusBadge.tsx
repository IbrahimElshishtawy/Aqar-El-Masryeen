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
  let color = 'bg-[#F4F4F2] text-[#777777] border-[#E2DFD8]';

  if (status === InstallmentStatus.Paid || status === UnitStatus.Sold || status === PropertyStatus.Delivered) {
    color = 'bg-[#242424] text-white border-[#242424]';
  } else if (status === InstallmentStatus.Overdue || status === UnitStatus.Cancelled) {
    color = 'bg-rose-50 text-rose-800 border-rose-200';
  } else if (status === InstallmentStatus.Pending || status === UnitStatus.Reserved || status === PropertyStatus.Planning) {
    color = 'bg-[#EBE8E1] text-[#242424] border-[#DCD8D0]';
  } else if (status === PropertyStatus.Active || status === UnitStatus.Available) {
    color = 'bg-[#A89F91]/25 text-[#242424] border-[#A89F91]/50';
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

