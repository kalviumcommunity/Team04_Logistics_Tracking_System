import React from 'react';

// Landing Screen Logistics Illustration
export const HeroLogisticsIllustration = () => (
  <div className="relative w-full aspect-[4/3] max-w-sm mx-auto flex items-center justify-center">
    <svg viewBox="0 0 400 300" fill="none" xmlns="http://www.w3.org/2000/svg" className="w-full h-full drop-shadow-xl">
      <defs>
        <linearGradient id="bgGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#14213D" stopOpacity="0.04" />
          <stop offset="100%" stopColor="#1769E8" stopOpacity="0.12" />
        </linearGradient>
        <linearGradient id="truckGrad" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" stopColor="#1769E8" />
          <stop offset="100%" stopColor="#2454D6" />
        </linearGradient>
        <linearGradient id="cyanGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#12C7C5" />
          <stop offset="100%" stopColor="#1769E8" />
        </linearGradient>
        <linearGradient id="purpleGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#7B2FF7" />
          <stop offset="100%" stopColor="#2454D6" />
        </linearGradient>
      </defs>

      {/* Background City Skyline Silhouette */}
      <path d="M 40 220 L 40 160 L 70 160 L 70 180 L 100 180 L 100 140 L 140 140 L 140 220 L 180 220 L 180 120 L 230 120 L 230 220 L 280 220 L 280 150 L 320 150 L 320 220 L 360 220" fill="url(#bgGrad)" stroke="#1769E8" strokeWidth="1" strokeOpacity="0.2" />

      {/* Road Path */}
      <path d="M 20 250 Q 150 210 380 250" stroke="#14213D" strokeWidth="24" strokeLinecap="round" opacity="0.9" />
      <path d="M 20 250 Q 150 210 380 250" stroke="#12C7C5" strokeWidth="3" strokeDasharray="8 8" strokeLinecap="round" />

      {/* Curved Route Path Accent */}
      <path d="M 70 190 Q 200 90 330 170" stroke="url(#purpleGrad)" strokeWidth="4" strokeDasharray="6 6" fill="none" />

      {/* Delivery Truck */}
      <g transform="translate(140, 175)">
        {/* Cargo Body */}
        <rect x="0" y="0" width="110" height="55" rx="8" fill="url(#truckGrad)" />
        <rect x="5" y="5" width="100" height="45" rx="5" fill="none" stroke="#12C7C5" strokeWidth="1.5" strokeDasharray="4 4" opacity="0.6" />
        {/* Cabin */}
        <path d="M 110 20 L 135 20 C 142 20 146 25 146 32 L 146 55 L 110 55 Z" fill="#14213D" />
        {/* Windshield */}
        <path d="M 115 25 L 132 25 L 138 35 L 115 35 Z" fill="#12C7C5" opacity="0.8" />
        {/* Wheels */}
        <circle cx="30" cy="55" r="14" fill="#14213D" stroke="#FFFFFF" strokeWidth="3" />
        <circle cx="30" cy="55" r="5" fill="#12C7C5" />
        <circle cx="115" cy="55" r="14" fill="#14213D" stroke="#FFFFFF" strokeWidth="3" />
        <circle cx="115" cy="55" r="5" fill="#12C7C5" />
        {/* Logo on Truck */}
        <circle cx="55" cy="27" r="12" fill="#FFFFFF" opacity="0.2" />
        <text x="35" y="31" fill="#FFFFFF" fontFamily="sans-serif" fontWeight="bold" fontSize="11" letterSpacing="0.5">DS-SYNC</text>
      </g>

      {/* Delivery Executive Character */}
      <g transform="translate(60, 160)">
        {/* Cap */}
        <path d="M 12 18 C 12 10 28 10 28 18 Z" fill="#1769E8" />
        <path d="M 22 18 L 34 18" stroke="#1769E8" strokeWidth="3" strokeLinecap="round" />
        {/* Head */}
        <circle cx="20" cy="24" r="8" fill="#F87171" />
        {/* Body / Uniform */}
        <path d="M 8 34 C 8 32 12 32 20 32 C 28 32 32 32 32 34 L 30 65 L 10 65 Z" fill="#14213D" />
        {/* Parcel in Hands */}
        <rect x="22" y="38" width="22" height="18" rx="3" fill="#F59E0B" stroke="#B45309" strokeWidth="1.5" />
        <line x1="33" y1="38" x2="33" y2="56" stroke="#B45309" strokeWidth="1.5" />
      </g>

      {/* Location Pin Pulsing */}
      <g transform="translate(320, 110)">
        <circle cx="15" cy="15" r="22" fill="#12C7C5" opacity="0.2" />
        <path d="M 15 0 C 6.7 0 0 6.7 0 15 C 0 26.25 15 40 15 40 C 15 40 30 26.25 30 15 C 30 6.7 23.3 0 15 0 Z" fill="url(#cyanGrad)" />
        <circle cx="15" cy="15" r="6" fill="#FFFFFF" />
      </g>
    </svg>
  </div>
);

// Onboarding 1: Live Tracking
export const LiveTrackingIllustration = () => (
  <div className="w-full aspect-square max-w-[240px] mx-auto flex items-center justify-center">
    <svg viewBox="0 0 200 200" fill="none" className="w-full h-full drop-shadow-md">
      {/* Phone Body */}
      <rect x="45" y="15" width="110" height="170" rx="20" fill="#14213D" stroke="#1769E8" strokeWidth="3" />
      <rect x="52" y="25" width="96" height="150" rx="14" fill="#F7F9FC" />
      
      {/* Map Visual inside phone */}
      <rect x="52" y="25" width="96" height="150" rx="14" fill="#E2E8F0" opacity="0.6" />
      <path d="M 60 70 Q 100 90 120 60 T 140 140" stroke="#1769E8" strokeWidth="4" fill="none" strokeDasharray="4 4" />
      <circle cx="60" cy="70" r="6" fill="#16B364" />
      <circle cx="140" cy="140" r="7" fill="#EF4444" />
      
      {/* Mini Truck Icon on Map */}
      <g transform="translate(95, 65)">
        <rect x="0" y="0" width="22" height="14" rx="3" fill="#1769E8" />
        <circle cx="5" cy="14" r="3" fill="#14213D" />
        <circle cx="17" cy="14" r="3" fill="#14213D" />
      </g>
    </svg>
  </div>
);

// Onboarding 2: Instant Updates
export const InstantUpdatesIllustration = () => (
  <div className="w-full aspect-square max-w-[240px] mx-auto flex items-center justify-center">
    <svg viewBox="0 0 200 200" fill="none" className="w-full h-full drop-shadow-md">
      {/* Phone outline */}
      <rect x="50" y="20" width="100" height="160" rx="18" fill="#14213D" />
      <rect x="56" y="28" width="88" height="144" rx="12" fill="#F7F9FC" />
      
      {/* Notification bell popping out */}
      <circle cx="100" cy="85" r="35" fill="#12C7C5" opacity="0.15" />
      <circle cx="100" cy="85" r="25" fill="#12C7C5" />
      {/* Bell icon */}
      <path d="M 100 70 C 93 70 88 75 88 82 V 90 L 84 94 V 96 H 116 V 94 L 112 90 V 82 C 112 75 107 70 100 70 Z" fill="#FFFFFF" />
      <path d="M 97 99 C 97 100.6 98.3 102 100 102 C 101.6 102 103 100.6 103 99 Z" fill="#FFFFFF" />

      {/* Notification Toast Cards */}
      <rect x="64" y="120" width="72" height="20" rx="6" fill="#FFFFFF" stroke="#1769E8" strokeWidth="1.5" />
      <circle cx="72" cy="130" r="4" fill="#16B364" />
      <rect x="80" y="127" width="48" height="6" rx="3" fill="#14213D" opacity="0.6" />
    </svg>
  </div>
);

// Onboarding 3: Smart Operations
export const SmartOperationsIllustration = () => (
  <div className="w-full aspect-square max-w-[240px] mx-auto flex items-center justify-center">
    <svg viewBox="0 0 200 200" fill="none" className="w-full h-full drop-shadow-md">
      {/* Dashboard window */}
      <rect x="25" y="35" width="150" height="130" rx="16" fill="#14213D" />
      <rect x="33" y="45" width="134" height="110" rx="10" fill="#FFFFFF" />

      {/* Bar charts */}
      <rect x="45" y="105" width="14" height="35" rx="3" fill="#1769E8" />
      <rect x="67" y="85" width="14" height="55" rx="3" fill="#12C7C5" />
      <rect x="89" y="70" width="14" height="70" rx="3" fill="#7B2FF7" />
      <rect x="111" y="95" width="14" height="45" rx="3" fill="#16B364" />
      <rect x="133" y="120" width="14" height="20" rx="3" fill="#EF4444" />

      {/* Trending Line */}
      <path d="M 45 100 L 67 75 L 89 55 L 111 85 L 133 60" stroke="#7B2FF7" strokeWidth="3" fill="none" strokeLinecap="round" strokeLinejoin="round" />
      <circle cx="133" cy="60" r="4" fill="#7B2FF7" />
    </svg>
  </div>
);
