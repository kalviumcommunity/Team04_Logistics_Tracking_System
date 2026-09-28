import React, { useState } from 'react';
import { Mail, Lock, ArrowRight, AlertCircle, ShieldCheck } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

export const LoginForm = ({ onSwitchToRegister, onSwitchToForgot, defaultRole }) => {
  const { login } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!email || !password) {
      setError('Please fill in both email and password.');
      return;
    }
    setError('');
    setLoading(true);

    try {
      await login(email, password);
    } catch (err) {
      setError(err.response?.data?.message || 'Login failed. Please check credentials.');
    } finally {
      setLoading(false);
    }
  };

  // Quick Demo Auto-fill helpers
  const handleFillDemo = (role) => {
    if (role === 'DISPATCHER') {
      setEmail('dispatcher@deliversync.com');
      setPassword('password123');
    } else if (role === 'DELIVERY_EXECUTIVE') {
      setEmail('executive@deliversync.com');
      setPassword('password123');
    } else if (role === 'OPERATIONS') {
      setEmail('ops@deliversync.com');
      setPassword('password123');
    }
  };

  return (
    <div className="min-h-full flex flex-col justify-between p-6 bg-white select-none">
      <div className="pt-2 space-y-2">
        <h2 className="text-2xl font-black text-brand-navy tracking-tight">Welcome Back</h2>
        <p className="text-xs text-slate-500 font-medium">Log in to manage real-time logistics & deliveries.</p>
      </div>

      {/* Demo Credentials Quick Fill Buttons */}
      <div className="my-2 p-3 bg-slate-50 rounded-2xl border border-slate-200/80">
        <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block mb-2">
          ⚡ Quick Demo Account Login
        </span>
        <div className="grid grid-cols-3 gap-1.5">
          <button
            type="button"
            onClick={() => handleFillDemo('DISPATCHER')}
            className="py-1.5 px-2 bg-blue-100/70 hover:bg-blue-100 text-brand-blue text-[10px] font-extrabold rounded-xl border border-blue-200"
          >
            Dispatcher
          </button>
          <button
            type="button"
            onClick={() => handleFillDemo('DELIVERY_EXECUTIVE')}
            className="py-1.5 px-2 bg-teal-100/70 hover:bg-teal-100 text-teal-700 text-[10px] font-extrabold rounded-xl border border-teal-200"
          >
            Executive
          </button>
          <button
            type="button"
            onClick={() => handleFillDemo('OPERATIONS')}
            className="py-1.5 px-2 bg-purple-100/70 hover:bg-purple-100 text-brand-purple text-[10px] font-extrabold rounded-xl border border-purple-200"
          >
            Operations
          </button>
        </div>
      </div>

      {error && (
        <div className="p-3 bg-rose-50 border border-rose-200 rounded-xl flex items-center gap-2 text-rose-700 text-xs font-semibold">
          <AlertCircle size={16} className="shrink-0" />
          <span>{error}</span>
        </div>
      )}

      {/* Form */}
      <form onSubmit={handleSubmit} className="space-y-4 my-auto">
        <div className="space-y-1.5">
          <label className="text-xs font-bold text-slate-700">Email Address</label>
          <div className="relative">
            <Mail size={18} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="name@deliversync.com"
              className="w-full pl-10 pr-4 py-3 bg-slate-50 border border-slate-200 rounded-xl text-sm font-medium text-slate-900 focus:outline-none focus:ring-2 focus:ring-brand-blue/30 focus:border-brand-blue transition-all"
            />
          </div>
        </div>

        <div className="space-y-1.5">
          <div className="flex items-center justify-between">
            <label className="text-xs font-bold text-slate-700">Password</label>
            <button
              type="button"
              onClick={onSwitchToForgot}
              className="text-xs font-semibold text-brand-blue hover:underline"
            >
              Forgot Password?
            </button>
          </div>
          <div className="relative">
            <Lock size={18} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              className="w-full pl-10 pr-4 py-3 bg-slate-50 border border-slate-200 rounded-xl text-sm font-medium text-slate-900 focus:outline-none focus:ring-2 focus:ring-brand-blue/30 focus:border-brand-blue transition-all"
            />
          </div>
        </div>

        <button
          type="submit"
          disabled={loading}
          className="w-full py-3.5 px-6 rounded-2xl bg-gradient-to-r from-brand-blue to-brand-blueDark text-white font-extrabold text-sm shadow-lg shadow-brand-blue/30 hover:shadow-xl transition-all active:scale-[0.98] flex items-center justify-center gap-2 disabled:opacity-75"
        >
          {loading ? (
            <span className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
          ) : (
            <>
              <span>Log In</span>
              <ArrowRight size={18} />
            </>
          )}
        </button>
      </form>

      {/* Switch to Register */}
      <div className="text-center pt-4 pb-2 border-t border-slate-100">
        <p className="text-xs text-slate-500 font-medium">
          Don't have an account?{' '}
          <button
            type="button"
            onClick={onSwitchToRegister}
            className="font-extrabold text-brand-blue hover:underline"
          >
            Create an Account
          </button>
        </p>
      </div>
    </div>
  );
};
