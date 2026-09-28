import React from 'react';
import { X, CheckCheck, Bell, AlertTriangle, Package, Info } from 'lucide-react';
import { useNotifications } from '../../context/NotificationContext';

export const NotificationCenter = ({ isOpen, onClose }) => {
  const { notifications, unreadCount, markAsRead, markAllAsRead } = useNotifications();

  if (!isOpen) return null;

  const getIcon = (type) => {
    switch (type) {
      case 'ESCALATION':
      case 'ESCALATION_RESOLVED':
        return <AlertTriangle size={16} className="text-brand-error" />;
      case 'ASSIGNMENT':
      case 'STATUS_CHANGE':
        return <Package size={16} className="text-brand-blue" />;
      default:
        return <Info size={16} className="text-brand-cyan" />;
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4 animate-fade-in">
      <div className="w-full max-w-md bg-white rounded-t-3xl sm:rounded-3xl shadow-2xl overflow-hidden flex flex-col max-h-[85vh] animate-slide-up">
        {/* Header */}
        <div className="px-5 py-4 bg-brand-navy text-white flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="p-2 bg-brand-blue/20 rounded-xl border border-brand-blue/30 text-brand-cyan">
              <Bell size={18} />
            </div>
            <div>
              <h2 className="text-base font-bold">Notifications</h2>
              <p className="text-xs text-slate-300">
                {unreadCount > 0 ? `${unreadCount} unread alert${unreadCount > 1 ? 's' : ''}` : 'All caught up!'}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            {unreadCount > 0 && (
              <button
                onClick={markAllAsRead}
                className="text-[11px] font-semibold text-brand-cyan hover:underline flex items-center gap-1 bg-white/10 px-2.5 py-1 rounded-lg"
              >
                <CheckCheck size={14} /> Mark all read
              </button>
            )}
            <button
              onClick={onClose}
              className="p-1.5 rounded-full hover:bg-white/10 text-slate-300 hover:text-white"
            >
              <X size={18} />
            </button>
          </div>
        </div>

        {/* Notifications List */}
        <div className="flex-1 overflow-y-auto p-4 space-y-2.5 bg-brand-bg">
          {notifications.length === 0 ? (
            <div className="text-center py-12 px-4 text-slate-400">
              <Bell size={36} className="mx-auto mb-2 opacity-30 stroke-1" />
              <p className="text-sm font-medium">No notifications yet</p>
              <p className="text-xs text-slate-400 mt-1">Status changes and assignments will appear here.</p>
            </div>
          ) : (
            notifications.map((n) => (
              <div
                key={n.id}
                onClick={() => !n.isRead && markAsRead(n.id)}
                className={`p-3.5 rounded-2xl border transition-all duration-200 cursor-pointer ${
                  n.isRead
                    ? 'bg-white border-slate-100 text-slate-600 opacity-80'
                    : 'bg-blue-50/70 border-blue-200/80 text-slate-900 shadow-sm'
                }`}
              >
                <div className="flex items-start gap-3">
                  <div className={`p-2 rounded-xl mt-0.5 ${n.isRead ? 'bg-slate-100' : 'bg-white shadow-xs'}`}>
                    {getIcon(n.type)}
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center justify-between gap-1">
                      <h4 className={`text-xs font-bold ${n.isRead ? 'text-slate-700' : 'text-slate-900'}`}>
                        {n.title}
                      </h4>
                      <span className="text-[10px] font-mono text-slate-400 whitespace-nowrap">
                        {new Date(n.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </span>
                    </div>
                    <p className="text-xs text-slate-600 mt-0.5 leading-relaxed">{n.message}</p>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
};
