import React from 'react';
import { User, Mail, Phone, ShieldCheck, LogOut, Lock, Bell, ChevronRight, Smartphone } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

export const UserProfile = ({ onLogout }) => {
  const { user } = useAuth();

  if (!user) return null;

  const getRoleStyle = (role) => {
    switch (role) {
      case 'DISPATCHER': return 'bg-blue-100 text-brand-blue border-blue-200';
      case 'DELIVERY_EXECUTIVE': return 'bg-teal-100 text-teal-800 border-teal-200';
      case 'OPERATIONS': return 'bg-purple-100 text-brand-purple border-purple-200';
      default: return 'bg-slate-100 text-slate-700';
    }
  };

  return (
    <div className="p-4 space-y-4 pb-20 animate-fade-in">
      <div className="text-center pt-2">
        <h2 className="text-lg font-black text-brand-navy">Account & Profile</h2>
        <p className="text-xs text-slate-500 font-medium">DeliverSync User Settings</p>
      </div>

      {/* User Card */}
      <div className="p-5 bg-white rounded-3xl border border-slate-100 shadow-sm text-center space-y-3 relative overflow-hidden">
        <div className="w-20 h-20 rounded-2xl bg-brand-navy mx-auto overflow-hidden border-4 border-white shadow-md ring-2 ring-slate-100 flex items-center justify-center text-white text-2xl font-black">
          {user.avatarUrl ? (
            <img src={user.avatarUrl} alt={user.fullName} className="w-full h-full object-cover" />
          ) : (
            <span>{user.fullName.charAt(0)}</span>
          )}
        </div>

        <div>
          <h3 className="text-base font-extrabold text-slate-900">{user.fullName}</h3>
          <span className={`inline-block mt-1 text-[11px] font-extrabold px-3 py-0.5 rounded-full border uppercase tracking-wider ${getRoleStyle(user.role)}`}>
            {user.role.replace('_', ' ')}
          </span>
        </div>

        <div className="pt-3 border-t border-slate-100 grid grid-cols-2 gap-2 text-left text-xs">
          <div className="p-2.5 bg-slate-50 rounded-xl">
            <span className="text-[10px] font-bold text-slate-400 uppercase block">Email Address</span>
            <span className="font-semibold text-slate-800 truncate block mt-0.5">{user.email}</span>
          </div>
          <div className="p-2.5 bg-slate-50 rounded-xl">
            <span className="text-[10px] font-bold text-slate-400 uppercase block">Phone Number</span>
            <span className="font-semibold text-slate-800 truncate block mt-0.5">{user.phone}</span>
          </div>
        </div>
      </div>

      {/* Settings Options */}
      <div className="bg-white rounded-2xl border border-slate-100 shadow-xs divide-y divide-slate-100 text-xs font-semibold text-slate-700">
        <div className="p-3.5 flex items-center justify-between hover:bg-slate-50 cursor-pointer">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-blue-50 text-brand-blue rounded-xl">
              <ShieldCheck size={16} />
            </div>
            <span>Security & Role Permissions</span>
          </div>
          <ChevronRight size={16} className="text-slate-400" />
        </div>

        <div className="p-3.5 flex items-center justify-between hover:bg-slate-50 cursor-pointer">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-teal-50 text-teal-700 rounded-xl">
              <Bell size={16} />
            </div>
            <span>Push & SMS Notifications</span>
          </div>
          <ChevronRight size={16} className="text-slate-400" />
        </div>

        <div className="p-3.5 flex items-center justify-between hover:bg-slate-50 cursor-pointer">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-purple-50 text-brand-purple rounded-xl">
              <Smartphone size={16} />
            </div>
            <span>Mobile Device Optimization</span>
          </div>
          <ChevronRight size={16} className="text-slate-400" />
        </div>
      </div>

      {/* Logout Button */}
      <button
        onClick={onLogout}
        className="w-full py-3.5 px-4 rounded-2xl bg-rose-50 hover:bg-rose-100 text-rose-700 font-extrabold text-xs border border-rose-200 shadow-xs transition-all active:scale-[0.98] flex items-center justify-center gap-2"
      >
        <LogOut size={16} />
        <span>Log Out of DeliverSync</span>
      </button>
    </div>
  );
};
