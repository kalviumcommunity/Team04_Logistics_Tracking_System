import React, { useState, useEffect } from 'react';
import { BarChart3, AlertTriangle, ShieldCheck, RefreshCw, CheckCircle2, TrendingUp, Users } from 'lucide-react';
import api from '../../services/api';
import { MetricCard } from '../common/MetricCard';
import { StatusBadge } from '../common/StatusBadge';

export const OperationsDashboard = ({ onOpenEscalation, onOpenAnalytics, onOpenMonitoring }) => {
  const [metrics, setMetrics] = useState(null);
  const [escalations, setEscalations] = useState([]);
  const [loading, setLoading] = useState(true);

  const fetchOpsData = async () => {
    try {
      setLoading(true);
      const [anaRes, escRes] = await Promise.all([
        api.get('/analytics/overview'),
        api.get('/escalations?status=OPEN')
      ]);
      setMetrics(anaRes.data.metrics || null);
      setEscalations(escRes.data.escalations || []);
    } catch (err) {
      console.error('Failed to load ops data', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOpsData();
  }, []);

  return (
    <div className="p-4 space-y-4 pb-20 animate-fade-in">
      {/* Operations Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-lg font-black text-brand-navy">Operations Control</h2>
          <p className="text-xs text-slate-500 font-medium">Monitor performance, escalations & logistics health.</p>
        </div>

        <button
          onClick={fetchOpsData}
          className="p-2 rounded-xl bg-white border border-slate-200 text-slate-600 hover:text-brand-purple shadow-xs"
        >
          <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
        </button>
      </div>

      {/* Metric Cards Grid */}
      <div className="grid grid-cols-2 gap-2.5">
        <MetricCard
          title="Success Rate"
          value={metrics?.successRate || '0%'}
          icon={TrendingUp}
          color="green"
        />
        <MetricCard
          title="Failure Rate"
          value={metrics?.failureRate || '0%'}
          icon={AlertTriangle}
          color="red"
        />
        <MetricCard
          title="Open Escalations"
          value={metrics?.openEscalations ?? 0}
          icon={AlertTriangle}
          color="amber"
          onClick={onOpenEscalation}
        />
        <MetricCard
          title="Resolved"
          value={metrics?.resolvedEscalations ?? 0}
          icon={CheckCircle2}
          color="purple"
        />
      </div>

      {/* Operations Quick Action Banners */}
      <div className="grid grid-cols-2 gap-2">
        <button
          onClick={onOpenAnalytics}
          className="p-3.5 bg-gradient-to-br from-brand-purple to-indigo-700 text-white rounded-2xl shadow-md flex items-center justify-between text-left active:scale-95 transition-all"
        >
          <div>
            <span className="text-[10px] font-mono uppercase tracking-wider text-purple-200">Deep Analytics</span>
            <p className="text-xs font-black mt-0.5">Visual Charts →</p>
          </div>
          <BarChart3 size={24} className="opacity-80 shrink-0" />
        </button>

        <button
          onClick={onOpenMonitoring}
          className="p-3.5 bg-gradient-to-br from-brand-navy to-slate-900 text-white rounded-2xl shadow-md flex items-center justify-between text-left active:scale-95 transition-all"
        >
          <div>
            <span className="text-[10px] font-mono uppercase tracking-wider text-slate-300">Logistics Feed</span>
            <p className="text-xs font-black mt-0.5">All Deliveries →</p>
          </div>
          <ShieldCheck size={24} className="opacity-80 shrink-0 text-brand-cyan" />
        </button>
      </div>

      {/* Active Open Escalations List */}
      <div className="space-y-2.5 pt-1">
        <div className="flex items-center justify-between">
          <h3 className="text-xs font-black text-brand-navy uppercase tracking-wider flex items-center gap-1.5">
            <AlertTriangle size={14} className="text-brand-error" /> Urgent Open Escalations ({escalations.length})
          </h3>
          <button onClick={onOpenEscalation} className="text-xs font-bold text-brand-purple hover:underline">
            View Escalation Center →
          </button>
        </div>

        {loading ? (
          <div className="py-8 text-center text-slate-400 text-xs">
            <RefreshCw size={20} className="mx-auto mb-2 animate-spin text-brand-purple" />
            Loading escalations...
          </div>
        ) : escalations.length === 0 ? (
          <div className="py-8 px-4 text-center bg-white rounded-2xl border border-slate-100 text-slate-400">
            <CheckCircle2 size={32} className="mx-auto mb-1 text-emerald-500 opacity-80" />
            <p className="text-xs font-bold text-slate-700">Zero Open Escalations</p>
            <p className="text-[11px] text-slate-400">All delivery issues have been resolved.</p>
          </div>
        ) : (
          escalations.slice(0, 3).map((esc) => (
            <div
              key={esc.id}
              onClick={onOpenEscalation}
              className="p-3.5 bg-white rounded-2xl border border-rose-100 hover:border-rose-300 shadow-xs transition-all cursor-pointer space-y-2"
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span className="font-mono text-xs font-extrabold text-brand-navy bg-slate-100 px-2 py-0.5 rounded">
                    {esc.delivery?.trackingNumber}
                  </span>
                  <span className="text-[10px] font-black px-2 py-0.5 rounded bg-rose-100 text-rose-800 uppercase">
                    {esc.priority} Priority
                  </span>
                </div>
                <StatusBadge status={esc.status} />
              </div>

              <div>
                <p className="text-xs font-extrabold text-slate-900">
                  {esc.delivery?.customerName} • {esc.failureReport?.reason?.replace('_', ' ')}
                </p>
                <p className="text-[11px] text-slate-600 truncate mt-0.5">"{esc.failureReport?.remarks}"</p>
              </div>

              <div className="pt-1 text-[10px] font-medium text-slate-400 flex items-center justify-between border-t border-slate-100">
                <span>Reporter: {esc.failureReport?.executive?.fullName}</span>
                <span>Logged {new Date(esc.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};
