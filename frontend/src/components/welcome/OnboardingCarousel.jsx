import React, { useState } from 'react';
import { ArrowRight, Check } from 'lucide-react';
import {
  LiveTrackingIllustration,
  InstantUpdatesIllustration,
  SmartOperationsIllustration
} from '../../assets/illustrations';

export const OnboardingCarousel = ({ onComplete, onSkip }) => {
  const [currentIndex, setCurrentIndex] = useState(0);

  const screens = [
    {
      title: 'Live Tracking',
      description: 'Track every delivery in real-time and stay updated at every step.',
      illustration: LiveTrackingIllustration,
      accentColor: 'from-brand-blue to-brand-cyan'
    },
    {
      title: 'Instant Updates',
      description: 'Get notified instantly about assignments, status changes, failures and escalations.',
      illustration: InstantUpdatesIllustration,
      accentColor: 'from-brand-cyan to-teal-600'
    },
    {
      title: 'Smart Operations',
      description: 'Monitor delivery performance, manage escalations and make better operational decisions.',
      illustration: SmartOperationsIllustration,
      accentColor: 'from-brand-purple to-indigo-600'
    }
  ];

  const handleNext = () => {
    if (currentIndex < screens.length - 1) {
      setCurrentIndex(currentIndex + 1);
    } else {
      onComplete();
    }
  };

  const current = screens[currentIndex];
  const Illustration = current.illustration;

  return (
    <div className="min-h-full flex flex-col justify-between p-6 bg-white select-none">
      {/* Top Bar with Skip */}
      <div className="flex items-center justify-between pt-2">
        <span className="text-xs font-mono font-bold text-slate-400">
          0{currentIndex + 1} / 0{screens.length}
        </span>
        <button
          onClick={onSkip}
          className="text-xs font-bold text-slate-500 hover:text-brand-blue px-3 py-1 rounded-lg hover:bg-slate-100 transition-all"
        >
          Skip
        </button>
      </div>

      {/* Center Slide */}
      <div className="my-auto text-center space-y-6 animate-fade-in py-4">
        <Illustration />

        <div className="space-y-2 max-w-xs mx-auto">
          <h2 className="text-2xl font-black text-brand-navy tracking-tight">
            {current.title}
          </h2>
          <p className="text-xs text-slate-600 font-medium leading-relaxed px-3">
            {current.description}
          </p>
        </div>
      </div>

      {/* Footer Indicators & Next */}
      <div className="space-y-6 pb-2">
        {/* Dots */}
        <div className="flex items-center justify-center gap-2">
          {screens.map((_, idx) => (
            <button
              key={idx}
              onClick={() => setCurrentIndex(idx)}
              className={`h-2 rounded-full transition-all duration-300 ${
                idx === currentIndex
                  ? 'w-8 bg-gradient-to-r ' + current.accentColor
                  : 'w-2 bg-slate-200'
              }`}
              aria-label={`Go to slide ${idx + 1}`}
            />
          ))}
        </div>

        {/* Primary Action Button */}
        <button
          onClick={handleNext}
          className="w-full py-3.5 px-6 rounded-2xl bg-gradient-to-r from-brand-blue to-brand-blueDark text-white font-extrabold text-sm shadow-lg shadow-brand-blue/30 hover:shadow-xl transition-all active:scale-[0.98] flex items-center justify-center gap-2"
        >
          <span>{currentIndex === screens.length - 1 ? 'Get Started' : 'Next'}</span>
          {currentIndex === screens.length - 1 ? <Check size={18} /> : <ArrowRight size={18} />}
        </button>
      </div>
    </div>
  );
};
