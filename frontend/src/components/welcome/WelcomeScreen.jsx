import React from 'react';
import { ArrowRight, ShieldCheck, ChevronRight } from 'lucide-react';
import { HeroLogisticsIllustration } from '../../assets/illustrations';

export const WelcomeScreen = ({ onGetStarted, onLogin, onCreateAccount }) => {
  return (
    <div className="min-h-full flex flex-col justify-between p-6 bg-gradient-to-b from-brand-bg via-white to-blue-50/40 select-none">
      {/* Top Brand Header */}
      <div className="pt-2 text-center flex flex-col items-center">
        {/* Official DeliverSync SVG Logo */}
        <div className="w-48 h-12 mb-1 flex items-center justify-center">
          <svg viewBox="0 0 240 60" fill="none" className="w-full h-full">
            <defs>
              <linearGradient id="welcomeBlueCyan" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor="#1769E8" />
                <stop offset="100%" stopColor="#12C7C5" />
              </linearGradient>
              <linearGradient id="welcomeBluePurple" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor="#2454D6" />
                <stop offset="100%" stopColor="#7B2FF7" />
              </linearGradient>
            </defs>
            <g transform="translate(6, 6)">
              <rect x="0" y="0" width="48" height="48" rx="14" fill="#14213D" />
              <rect x="1" y="1" width="46" height="46" rx="13" fill="none" stroke="url(#welcomeBlueCyan)" strokeWidth="2.5" />
              <path d="M 14 20 C 14 16 18 14 24 14 H 31 M 28 10 L 33 14 L 28 18" stroke="url(#welcomeBlueCyan)" strokeWidth="3.5" strokeLinecap="round" />
              <path d="M 34 28 C 34 32 30 34 24 34 H 17 M 20 38 L 15 34 L 20 30" stroke="url(#welcomeBluePurple)" strokeWidth="3.5" strokeLinecap="round" />
              <circle cx="24" cy="24" r="3.5" fill="#FFFFFF" />
            </g>
            <text x="64" y="35" fontFamily="'Plus Jakarta Sans', sans-serif" fontWeight="800" fontSize="24" fill="#14213D">
              Deliver<tspan fill="#1769E8">Sync</tspan>
            </text>
          </svg>
        </div>

        <p className="text-xs font-semibold text-brand-cyan tracking-wide uppercase flex items-center gap-1">
          <ShieldCheck size={14} className="text-brand-cyan" />
          "Delivering trust, every mile."
        </p>
      </div>

      {/* Hero Content & Logistics Illustration */}
      <div className="my-auto text-center py-4 space-y-4">
        <HeroLogisticsIllustration />

        <div className="space-y-2 max-w-xs mx-auto">
          <h1 className="text-2xl font-black text-brand-navy leading-tight tracking-tight">
            Smarter Deliveries.<br />
            <span className="bg-gradient-to-r from-brand-blue via-brand-cyan to-brand-purple bg-clip-text text-transparent">
              Better Connections.
            </span>
          </h1>

          <p className="text-xs text-slate-600 font-medium leading-relaxed px-2">
            Real-time tracking, smart updates and seamless coordination for every delivery.
          </p>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="space-y-3 pb-2 w-full max-w-xs mx-auto">
        <button
          onClick={onGetStarted}
          className="w-full py-3.5 px-6 rounded-2xl bg-gradient-to-r from-brand-blue to-brand-blueDark text-white font-extrabold text-sm shadow-lg shadow-brand-blue/30 hover:shadow-xl transition-all active:scale-[0.98] flex items-center justify-center gap-2 group"
        >
          <span>Get Started</span>
          <ArrowRight size={18} className="group-hover:translate-x-1 transition-transform" />
        </button>

        <button
          onClick={onLogin}
          className="w-full py-3 px-6 rounded-2xl bg-white text-slate-800 font-bold text-sm border border-slate-200 hover:bg-slate-50 transition-all active:scale-[0.98] flex items-center justify-center gap-1 shadow-xs"
        >
          Login
        </button>

        <div className="pt-1 text-center">
          <button
            onClick={onCreateAccount}
            className="text-xs font-semibold text-brand-blue hover:underline inline-flex items-center gap-0.5"
          >
            <span>New here? Create an account</span>
            <ChevronRight size={14} />
          </button>
        </div>
      </div>
    </div>
  );
};
