import React, { useState } from 'react';
import { Mail, ArrowRight, ArrowLeft, CheckCircle2 } from 'lucide-react';

export const ForgotPasswordForm = ({ onBackToLogin }) => {
  const [email, setEmail] = useState('');
  const [submitted, setSubmitted] = useState(false);

  const handleSubmit = (e) => {
    e.preventDefault();
    if (email) {
      setSubmitted(true);
    }
  };

  return (
    <div className="min-h-full flex flex-col justify-between p-6 bg-white select-none">
      <button
        onClick={onBackToLogin}
        className="self-start text-xs font-bold text-slate-500 hover:text-brand-blue flex items-center gap-1 py-1"
      >
        <ArrowLeft size={16} /> Back to Login
      </button>

      <div className="my-auto space-y-4 text-center max-w-xs mx-auto py-6">
        {!submitted ? (
          <>
            <div className="w-14 h-14 bg-brand-blue/10 text-brand-blue rounded-2xl flex items-center justify-center mx-auto">
              <Mail size={28} />
            </div>
            <div className="space-y-1">
              <h2 className="text-xl font-black text-brand-navy">Reset Password</h2>
              <p className="text-xs text-slate-500 font-medium">
                Enter your registered email address and we'll send password reset instructions.
              </p>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4 pt-2">
              <div className="relative text-left">
                <Mail size={18} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="name@deliversync.com"
                  required
                  className="w-full pl-10 pr-4 py-3 bg-slate-50 border border-slate-200 rounded-xl text-sm font-medium text-slate-900 focus:outline-none focus:ring-2 focus:ring-brand-blue/30"
                />
              </div>

              <button
                type="submit"
                className="w-full py-3.5 px-6 rounded-2xl bg-gradient-to-r from-brand-blue to-brand-blueDark text-white font-extrabold text-sm shadow-lg shadow-brand-blue/30 hover:shadow-xl transition-all active:scale-[0.98] flex items-center justify-center gap-2"
              >
                <span>Send Reset Link</span>
                <ArrowRight size={18} />
              </button>
            </form>
          </>
        ) : (
          <div className="space-y-3 animate-fade-in">
            <div className="w-14 h-14 bg-emerald-100 text-brand-success rounded-2xl flex items-center justify-center mx-auto">
              <CheckCircle2 size={32} />
            </div>
            <h2 className="text-xl font-black text-brand-navy">Reset Link Sent!</h2>
            <p className="text-xs text-slate-600 font-medium">
              We have dispatched a password recovery token to <strong className="text-slate-900">{email}</strong>.
            </p>
            <button
              onClick={onBackToLogin}
              className="w-full py-3 px-6 rounded-xl bg-brand-navy text-white font-bold text-xs shadow-md mt-4"
            >
              Return to Login
            </button>
          </div>
        )}
      </div>

      <div className="text-center text-xs text-slate-400">
        DeliverSync Security System
      </div>
    </div>
  );
};
