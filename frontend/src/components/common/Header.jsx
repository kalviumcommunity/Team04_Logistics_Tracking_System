import React from 'react';
import { Bell, User, ShieldCheck } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { useNotifications } from '../../context/NotificationContext';

export const Header = ({ title, subtitle, onOpenNotifications, onOpenProfile }) => {
  const { user } = useAuth();
  const { unreadCount } = useNotifications();

  const getRoleBadgeStyle = (role) => {
    switch (role) {
      case 'DISPATCHER':
        return 'bg-brand-blue/10 text-brand-blue border-brand-blue/20';
      case 'DELIVERY_EXECUTIVE':
        return 'bg-brand-cyan/10 text-teal-700 border-brand-cyan/30';
      case 'OPERATIONS':
        return 'bg-brand-purple/10 text-brand-purple border-brand-purple/20';
      default:
        return 'bg-slate-100 text-slate-700 border-slate-200';
    }
  };

  const getRoleLabel = (role) => {
    switch (role) {
      case 'DISPATCHER': return 'Dispatcher App';
      case 'DELIVERY_EXECUTIVE': return 'Executive Field App';
      case 'OPERATIONS': return 'Ops Control App';
      default: return 'DeliverSync';
    }
  };

  return (
    <header className="sticky top-0 z-40 bg-white/90 backdrop-blur-md border-b border-slate-100 px-4 py-3 flex items-center justify-between shadow-sm">
      <div className="flex items-center gap-3">
        {/* Brand Logo Mini */}
        <div className="w-10 h-10 rounded-xl bg-brand-navy flex items-center justify-center p-1.5 shadow-md shadow-brand-navy/20 ring-2 ring-brand-blue/20">
          <svg viewBox="0 0 48 48" fill="none" className="w-full h-full">
            <rect width="48" height="48" rx="12" fill="#14213D" />
            <path d="M 14 20 C 14 16 18 14 24 14 H 31 M 28 10 L 33 14 L 28 18" stroke="#12C7C5" strokeWidth="3.5" strokeLinecap="round" />
            <path d="M 34 28 C 34 32 30 34 24 34 H 17 M 20 38 L 15 34 L 20 30" stroke="#7B2FF7" strokeWidth="3.5" strokeLinecap="round" />
            <circle cx="24" cy="24" r="3.5" fill="#FFFFFF" />
          </svg>
        </div>

        <div>
          <div className="flex items-center gap-1.5">
            <h1 className="text-base font-extrabold text-brand-navy leading-none tracking-tight">
              Deliver<span className="text-brand-blue">Sync</span>
            </h1>
            {user?.role && (
              <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border uppercase ${getRoleBadgeStyle(user.role)}`}>
                {getRoleLabel(user.role)}
              </span>
            )}
          </div>
          {subtitle && (
            <p className="text-[11px] font-medium text-slate-500 mt-0.5 truncate max-w-[180px]">
              {subtitle}
            </p>
          )}
        </div>
      </div>

      {/* Right Actions */}
      <div className="flex items-center gap-2">
        {/* Notification Bell */}
        <button
          onClick={onOpenNotifications}
          className="relative p-2.5 rounded-xl bg-slate-50 hover:bg-slate-100 text-slate-700 transition-all active:scale-95 border border-slate-200/60"
          aria-label="Notifications"
        >
          <Bell size={18} />
          {unreadCount > 0 && (
            <span className="absolute -top-1 -right-1 w-5 h-5 bg-brand-error text-white text-[10px] font-black rounded-full flex items-center justify-center border-2 border-white animate-pulse shadow-sm">
              {unreadCount > 9 ? '9+' : unreadCount}
            </span>
          )}
        </button>

        {/* Profile Avatar */}
        <button
          onClick={onOpenProfile}
          className="relative w-9 h-9 rounded-xl bg-slate-200 overflow-hidden border-2 border-white shadow-sm ring-2 ring-slate-100 hover:ring-brand-blue/30 transition-all active:scale-95 flex items-center justify-center text-slate-600 font-bold"
        >
          {user?.avatarUrl ? (
            <img src={user.avatarUrl} alt={user.fullName} className="w-full h-full object-cover" />
          ) : (
            <User size={18} />
          )}
        </button>
      </div>
    </header>
  );
};
