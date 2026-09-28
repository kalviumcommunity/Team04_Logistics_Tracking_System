import React, { useState, useEffect } from 'react';
import { BarChart, Bar, PieChart, Pie, Cell, XAxis, YAxis, Tooltip, ResponsiveContainer, Legend } from 'recharts';
import { RefreshCw, BarChart3, TrendingUp, Users, AlertTriangle } from 'lucide-react';
import api from '../../services/api';

export const AnalyticsView = () => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  const fetchAnalytics = async () => {
    try {
      setLoading(true);
      const res = await api.get('/analytics/overview');
      setData(res.data);
    } catch (err) {
      console.error('Failed to load analytics data', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAnalytics();
  }, []);

  if (loading || !data) {
    return (
      <div className="py-20 text-center text-slate-400 text-xs font-medium">
        <RefreshCw size={24} className="mx-auto mb-2 animate-spin text-brand-purple" />
        Computing live database analytics...
      </div>
    );
  }

  const { metrics, statusDistribution, failureTrends, executivePerformance } = data;

  const successvsFailureData = [
    { name: 'Delivered', count: metrics.deliveredCount, color: '#16B364' },
    { name: 'Failed', count: metrics.failedCount, color: '#EF4444' }
  ];

  return (
    <div className="p-4 space-y-5 pb-20 animate-fade-in">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-lg font-black text-brand-navy">Visual Analytics</h2>
          <p className="text-xs text-slate-500 font-medium">Real-time database performance telemetry.</p>
        </div>
        <button
          onClick={fetchAnalytics}
          className="p-2 rounded-xl bg-white border border-slate-200 text-slate-600 hover:text-brand-purple shadow-xs"
        >
          <RefreshCw size={16} />
        </button>
      </div>

      {/* Overview Stat Strip */}
      <div className="grid grid-cols-2 gap-2.5">
        <div className="p-3.5 bg-emerald-50 rounded-2xl border border-emerald-100">
          <span className="text-[10px] font-bold text-emerald-800 uppercase">Success Rate</span>
          <p className="text-2xl font-black text-emerald-700 mt-1">{metrics.successRate}</p>
          <p className="text-[10px] text-emerald-600 mt-0.5">{metrics.deliveredCount} orders delivered</p>
        </div>

        <div className="p-3.5 bg-rose-50 rounded-2xl border border-rose-100">
          <span className="text-[10px] font-bold text-rose-800 uppercase">Failure Rate</span>
          <p className="text-2xl font-black text-rose-700 mt-1">{metrics.failureRate}</p>
          <p className="text-[10px] text-rose-600 mt-0.5">{metrics.failedCount} orders failed</p>
        </div>
      </div>

      {/* Chart 1: Status Distribution */}
      <div className="p-4 bg-white rounded-2xl border border-slate-100 shadow-xs space-y-3">
        <h3 className="text-xs font-black text-brand-navy uppercase tracking-wider flex items-center gap-1.5">
          <BarChart3 size={14} className="text-brand-blue" /> Delivery Status Distribution
        </h3>
        <div className="w-full h-52">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={statusDistribution} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
              <XAxis dataKey="name" tick={{ fontSize: 10 }} />
              <YAxis allowDecimals={false} tick={{ fontSize: 10 }} />
              <Tooltip formatter={(value) => [`${value} Deliveries`, 'Volume']} />
              <Bar dataKey="value" radius={[6, 6, 0, 0]}>
                {statusDistribution.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.color} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Chart 2: Success vs Failure Comparison */}
      <div className="p-4 bg-white rounded-2xl border border-slate-100 shadow-xs space-y-3">
        <h3 className="text-xs font-black text-brand-navy uppercase tracking-wider flex items-center gap-1.5">
          <TrendingUp size={14} className="text-brand-success" /> Success vs Failure Breakdown
        </h3>
        <div className="w-full h-48 flex items-center justify-center">
          <ResponsiveContainer width="100%" height="100%">
            <PieChart>
              <Pie
                data={successvsFailureData}
                cx="50%"
                cy="50%"
                innerRadius={45}
                outerRadius={70}
                paddingAngle={4}
                dataKey="count"
              >
                {successvsFailureData.map((entry, index) => (
                  <Cell key={`pie-cell-${index}`} fill={entry.color} />
                ))}
              </Pie>
              <Tooltip />
              <Legend wrapperStyle={{ fontSize: '11px' }} />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Leaderboard: Executive Performance */}
      <div className="p-4 bg-white rounded-2xl border border-slate-100 shadow-xs space-y-3">
        <h3 className="text-xs font-black text-brand-navy uppercase tracking-wider flex items-center gap-1.5">
          <Users size={14} className="text-brand-purple" /> Executive Performance Leaderboard
        </h3>

        <div className="space-y-2.5">
          {executivePerformance.map((exec) => (
            <div key={exec.id} className="p-3 bg-slate-50 rounded-xl border border-slate-100 space-y-1.5">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <img src={exec.avatar} alt={exec.name} className="w-6 h-6 rounded-full bg-slate-200" />
                  <span className="text-xs font-bold text-slate-800">{exec.name}</span>
                </div>
                <span className="text-xs font-black text-brand-blue">{exec.successRate}% Success</span>
              </div>

              <div className="w-full bg-slate-200 h-2 rounded-full overflow-hidden">
                <div
                  className="bg-gradient-to-r from-brand-blue to-brand-cyan h-full rounded-full"
                  style={{ width: `${exec.successRate}%` }}
                />
              </div>

              <div className="flex items-center justify-between text-[10px] text-slate-500 font-medium">
                <span>Total: {exec.total}</span>
                <span>Delivered: {exec.completed}</span>
                <span>Failed: {exec.failed}</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Failure Trends */}
      {failureTrends.length > 0 && (
        <div className="p-4 bg-white rounded-2xl border border-slate-100 shadow-xs space-y-3">
          <h3 className="text-xs font-black text-brand-navy uppercase tracking-wider flex items-center gap-1.5">
            <AlertTriangle size={14} className="text-brand-error" /> Failure Reason Trends
          </h3>
          <div className="space-y-2">
            {failureTrends.map((ft, idx) => (
              <div key={idx} className="flex items-center justify-between text-xs p-2 bg-rose-50/50 rounded-xl border border-rose-100">
                <span className="font-bold text-slate-800">{ft.reason}</span>
                <span className="font-black text-rose-700 bg-rose-100 px-2 py-0.5 rounded">{ft.count} incidents</span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};
