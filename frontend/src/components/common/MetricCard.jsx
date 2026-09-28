import React from 'react';

export const MetricCard = ({ title, value, icon: Icon, color = 'blue', subtitle, onClick }) => {
  const getColorStyles = (c) => {
    switch (c) {
      case 'blue':
        return {
          bg: 'bg-blue-50/60 hover:bg-blue-50',
          border: 'border-blue-100',
          text: 'text-brand-blue',
          iconBg: 'bg-brand-blue text-white shadow-blue-500/20'
        };
      case 'cyan':
        return {
          bg: 'bg-teal-50/60 hover:bg-teal-50',
          border: 'border-teal-100',
          text: 'text-teal-700',
          iconBg: 'bg-brand-cyan text-white shadow-teal-500/20'
        };
      case 'purple':
        return {
          bg: 'bg-purple-50/60 hover:bg-purple-50',
          border: 'border-purple-100',
          text: 'text-brand-purple',
          iconBg: 'bg-brand-purple text-white shadow-purple-500/20'
        };
      case 'green':
        return {
          bg: 'bg-emerald-50/60 hover:bg-emerald-50',
          border: 'border-emerald-100',
          text: 'text-brand-success',
          iconBg: 'bg-brand-success text-white shadow-emerald-500/20'
        };
      case 'amber':
        return {
          bg: 'bg-amber-50/60 hover:bg-amber-50',
          border: 'border-amber-100',
          text: 'text-amber-700',
          iconBg: 'bg-brand-warning text-white shadow-amber-500/20'
        };
      case 'red':
        return {
          bg: 'bg-rose-50/60 hover:bg-rose-50',
          border: 'border-rose-100',
          text: 'text-brand-error',
          iconBg: 'bg-brand-error text-white shadow-rose-500/20'
        };
      default:
        return {
          bg: 'bg-slate-50 hover:bg-slate-100',
          border: 'border-slate-200',
          text: 'text-slate-800',
          iconBg: 'bg-slate-800 text-white'
        };
    }
  };

  const theme = getColorStyles(color);

  return (
    <div
      onClick={onClick}
      className={`p-3.5 rounded-2xl border ${theme.border} ${theme.bg} transition-all duration-200 shadow-sm flex flex-col justify-between ${onClick ? 'cursor-pointer active:scale-95' : ''}`}
    >
      <div className="flex items-center justify-between gap-2">
        <span className="text-[11px] font-bold text-slate-500 uppercase tracking-wide truncate">{title}</span>
        {Icon && (
          <div className={`w-7 h-7 rounded-xl flex items-center justify-center shadow-md ${theme.iconBg}`}>
            <Icon size={15} />
          </div>
        )}
      </div>

      <div className="mt-2 flex items-baseline justify-between">
        <span className={`text-2xl font-black ${theme.text} tracking-tight`}>{value}</span>
        {subtitle && <span className="text-[10px] font-semibold text-slate-500">{subtitle}</span>}
      </div>
    </div>
  );
};
