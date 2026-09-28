import React, { useState } from 'react';
import { Truck, ShieldCheck, BarChart3, CheckCircle2, ArrowRight } from 'lucide-react';

export const RoleIntroduction = ({ onSelectRole }) => {
  const [selectedRole, setSelectedRole] = useState('DISPATCHER');

  const roles = [
    {
      id: 'DISPATCHER',
      title: 'Dispatcher',
      tagline: 'Create, assign and monitor deliveries with ease.',
      color: 'blue',
      border: 'border-brand-blue/30',
      badge: 'bg-brand-blue/10 text-brand-blue',
      btnGrad: 'from-brand-blue to-brand-blueDark',
      icon: Truck,
      features: [
        'Create deliveries',
        'Assign executives',
        'Reassign deliveries',
        'Monitor delivery status'
      ]
    },
    {
      id: 'DELIVERY_EXECUTIVE',
      title: 'Delivery Executive',
      tagline: 'Manage deliveries and update status directly from the field.',
      color: 'cyan',
      border: 'border-brand-cyan/40',
      badge: 'bg-brand-cyan/15 text-teal-700',
      btnGrad: 'from-brand-cyan to-teal-600',
      icon: ShieldCheck,
      features: [
        'View assigned deliveries',
        'Start delivery',
        'Mark delivered',
        'Mark failed',
        'Add remarks',
        'Create escalation'
      ]
    },
    {
      id: 'OPERATIONS',
      title: 'Operations Team',
      tagline: 'Monitor performance, manage escalations and improve operations.',
      color: 'purple',
      border: 'border-brand-purple/30',
      badge: 'bg-brand-purple/10 text-brand-purple',
      btnGrad: 'from-brand-purple to-indigo-600',
      icon: BarChart3,
      features: [
        'Monitor all deliveries',
        'View failures',
        'Manage escalations',
        'View analytics',
        'Monitor executive performance'
      ]
    }
  ];

  return (
    <div className="min-h-full flex flex-col justify-between p-5 bg-brand-bg select-none">
      <div className="pt-2 text-center">
        <h2 className="text-xl font-black text-brand-navy tracking-tight">Select Your Role</h2>
        <p className="text-xs text-slate-500 mt-1">DeliverSync is optimized for 3 specialized workflows.</p>
      </div>

      {/* Role Cards */}
      <div className="my-auto space-y-3 py-3">
        {roles.map((r) => {
          const Icon = r.icon;
          const isSelected = selectedRole === r.id;

          return (
            <div
              key={r.id}
              onClick={() => setSelectedRole(r.id)}
              className={`p-4 rounded-2xl bg-white border-2 transition-all duration-200 cursor-pointer shadow-xs ${
                isSelected
                  ? `${r.border} ring-2 ring-brand-blue/20 shadow-md`
                  : 'border-slate-100 hover:border-slate-200'
              }`}
            >
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-3">
                  <div className={`p-2.5 rounded-xl font-bold ${r.badge}`}>
                    <Icon size={20} />
                  </div>
                  <div>
                    <h3 className="text-sm font-bold text-brand-navy">{r.title}</h3>
                    <span className={`text-[10px] font-extrabold px-2 py-0.5 rounded-full ${r.badge}`}>
                      {r.id.replace('_', ' ')}
                    </span>
                  </div>
                </div>

                <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${
                  isSelected ? 'border-brand-blue bg-brand-blue text-white' : 'border-slate-300'
                }`}>
                  {isSelected && <CheckCircle2 size={14} className="stroke-[3px]" />}
                </div>
              </div>

              <p className="text-xs text-slate-600 mt-2 font-medium leading-relaxed">
                "{r.tagline}"
              </p>

              {/* Feature Pills */}
              <div className="mt-3 flex flex-wrap gap-1.5 pt-2 border-t border-slate-100">
                {r.features.map((feat, idx) => (
                  <span key={idx} className="text-[10px] font-medium text-slate-600 bg-slate-100 px-2 py-0.5 rounded-md flex items-center gap-1">
                    <span className="w-1 h-1 rounded-full bg-slate-400"></span>
                    {feat}
                  </span>
                ))}
              </div>
            </div>
          );
        })}
      </div>

      {/* Action Button */}
      <button
        onClick={() => onSelectRole(selectedRole)}
        className="w-full py-3.5 px-6 rounded-2xl bg-brand-navy text-white font-extrabold text-sm shadow-lg shadow-brand-navy/20 hover:bg-slate-900 transition-all active:scale-[0.98] flex items-center justify-center gap-2"
      >
        <span>Continue to Login / Register</span>
        <ArrowRight size={18} />
      </button>
    </div>
  );
};
