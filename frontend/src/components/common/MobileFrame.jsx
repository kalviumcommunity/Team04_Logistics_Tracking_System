import React, { useState, useEffect } from 'react';
import { Smartphone, Monitor, Wifi, Battery, Signal } from 'lucide-react';

export const MobileFrame = ({ children, activeTab, user }) => {
  const [isFrameEnabled, setIsFrameEnabled] = useState(true);
  const [time, setTime] = useState('');

  useEffect(() => {
    const updateTime = () => {
      const now = new Date();
      setTime(now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: false }));
    };
    updateTime();
    const interval = setInterval(updateTime, 30000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="min-h-screen bg-slate-950 flex flex-col items-center justify-center p-0 md:p-6 transition-all duration-300 font-sans selection:bg-brand-blue selection:text-white">
      {/* Top Switcher Bar (Desktop preview helper) */}
      <div className="hidden md:flex items-center justify-between w-full max-w-5xl mb-4 px-4 py-2 bg-slate-900/80 backdrop-blur border border-slate-800 rounded-xl text-slate-300 text-xs">
        <div className="flex items-center gap-2">
          <span className="w-2.5 h-2.5 rounded-full bg-brand-cyan animate-pulse"></span>
          <span className="font-semibold text-slate-200">DeliverSync Mobile Viewport</span>
          <span className="bg-brand-blue/20 text-brand-blue border border-brand-blue/30 px-2 py-0.5 rounded-full font-mono text-[10px]">
            Mobile-First Architecture
          </span>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={() => setIsFrameEnabled(!isFrameEnabled)}
            className={`flex items-center gap-1.5 px-3 py-1 rounded-lg font-medium transition-all ${
              isFrameEnabled ? 'bg-brand-blue text-white shadow-lg shadow-brand-blue/30' : 'bg-slate-800 text-slate-400 hover:text-white'
            }`}
          >
            {isFrameEnabled ? <Smartphone size={14} /> : <Monitor size={14} />}
            {isFrameEnabled ? 'Mobile Device Frame' : 'Full Mobile Canvas'}
          </button>
        </div>
      </div>

      {/* Device Outer Container */}
      <div
        className={`w-full transition-all duration-300 ${
          isFrameEnabled
            ? 'max-w-[420px] h-[860px] max-h-[92vh] bg-slate-900 rounded-[48px] border-[10px] border-slate-800 shadow-frame relative flex flex-col overflow-hidden ring-1 ring-slate-700/50'
            : 'max-w-md min-h-screen bg-brand-bg relative flex flex-col shadow-2xl'
        }`}
      >
        {/* Mobile Device Hardware Top Notch / Dynamic Island */}
        {isFrameEnabled && (
          <div className="sticky top-0 z-50 bg-slate-950 text-white px-7 pt-3 pb-2 flex items-center justify-between select-none">
            {/* Left Time */}
            <span className="text-xs font-semibold tracking-tight">{time || '09:41'}</span>
            
            {/* Dynamic Island Capsule */}
            <div className="w-24 h-4 bg-black rounded-full flex items-center justify-center gap-2 border border-slate-800">
              <span className="w-2 h-2 rounded-full bg-slate-800"></span>
              <span className="w-1.5 h-1.5 rounded-full bg-brand-cyan/60 animate-ping"></span>
            </div>

            {/* Status Icons */}
            <div className="flex items-center gap-1.5 text-slate-300">
              <Signal size={12} />
              <Wifi size={12} />
              <div className="flex items-center">
                <Battery size={14} className="text-slate-200" />
              </div>
            </div>
          </div>
        )}

        {/* Main Scrollable App Container */}
        <div className="flex-1 flex flex-col bg-brand-bg overflow-y-auto overflow-x-hidden relative scrollbar-none">
          {children}
        </div>

        {/* Mobile Bottom Home Indicator Line */}
        {isFrameEnabled && (
          <div className="bg-slate-950 py-2 flex items-center justify-center border-t border-slate-900">
            <div className="w-32 h-1 bg-slate-600 rounded-full"></div>
          </div>
        )}
      </div>
    </div>
  );
};
