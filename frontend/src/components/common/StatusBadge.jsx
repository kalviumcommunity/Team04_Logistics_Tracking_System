import React from 'react';
import { Clock, UserCheck, Truck, CheckCircle2, AlertTriangle, XCircle } from 'lucide-react';

export const StatusBadge = ({ status }) => {
  const getBadgeConfig = (st) => {
    switch (st) {
      case 'PENDING':
        return { label: 'Pending', icon: Clock, style: 'bg-amber-50 text-amber-700 border-amber-200/80' };
      case 'ASSIGNED':
        return { label: 'Assigned', icon: UserCheck, style: 'bg-blue-50 text-blue-700 border-blue-200/80' };
      case 'IN_TRANSIT':
        return { label: 'In Transit', icon: Truck, style: 'bg-teal-50 text-teal-700 border-teal-200/80' };
      case 'DELIVERED':
        return { label: 'Delivered', icon: CheckCircle2, style: 'bg-emerald-50 text-emerald-700 border-emerald-200/80' };
      case 'FAILED':
        return { label: 'Failed', icon: AlertTriangle, style: 'bg-rose-50 text-rose-700 border-rose-200/80' };
      case 'CANCELLED':
        return { label: 'Cancelled', icon: XCircle, style: 'bg-slate-100 text-slate-600 border-slate-200' };
      case 'OPEN':
        return { label: 'Open', icon: AlertTriangle, style: 'bg-rose-100 text-rose-800 border-rose-300 font-bold' };
      case 'IN_PROGRESS':
        return { label: 'In Progress', icon: Clock, style: 'bg-indigo-50 text-indigo-700 border-indigo-200' };
      case 'RESOLVED':
        return { label: 'Resolved', icon: CheckCircle2, style: 'bg-emerald-100 text-emerald-800 border-emerald-300' };
      default:
        return { label: st || 'Unknown', icon: Clock, style: 'bg-slate-50 text-slate-600 border-slate-200' };
    }
  };

  const config = getBadgeConfig(status);
  const Icon = config.icon;

  return (
    <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-semibold border ${config.style} shadow-xs`}>
      <Icon size={12} className="stroke-[2.2px]" />
      <span>{config.label}</span>
    </span>
  );
};
