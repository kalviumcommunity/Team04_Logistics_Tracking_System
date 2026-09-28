import React, { useState, useEffect } from 'react';
import { Package, Truck, CheckCircle2, AlertTriangle, RefreshCw, MapPin, Phone, ArrowRight } from 'lucide-react';
import api from '../../services/api';
import { MetricCard } from '../common/MetricCard';
import { StatusBadge } from '../common/StatusBadge';

export const ExecutiveDashboard = ({ onOpenDelivery }) => {
  const [deliveries, setDeliveries] = useState([]);
  const [loading, setLoading] = useState(true);

  const fetchDeliveries = async () => {
    try {
      setLoading(true);
      const res = await api.get('/deliveries');
      setDeliveries(res.data.deliveries || []);
    } catch (err) {
      console.error('Failed to load executive deliveries:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDeliveries();
  }, []);

  const assignedCount = deliveries.filter(d => d.status === 'ASSIGNED').length;
  const inTransitCount = deliveries.filter(d => d.status === 'IN_TRANSIT').length;
  const completedCount = deliveries.filter(d => d.status === 'DELIVERED').length;
  const failedCount = deliveries.filter(d => d.status === 'FAILED').length;

  return (
    <div className="p-4 space-y-4 pb-20 animate-fade-in">
      {/* Executive Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-lg font-black text-brand-navy">Field Dashboard</h2>
          <p className="text-xs text-slate-500 font-medium">Manage assigned deliveries in real-time.</p>
        </div>
        <button
          onClick={fetchDeliveries}
          className="p-2 rounded-xl bg-white border border-slate-200 text-slate-600 hover:text-brand-blue shadow-xs"
        >
          <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
        </button>
      </div>

      {/* Metric Cards Grid */}
      <div className="grid grid-cols-2 gap-2.5">
        <MetricCard title="Assigned" value={assignedCount} icon={Package} color="blue" />
        <MetricCard title="In Transit" value={inTransitCount} icon={Truck} color="cyan" />
        <MetricCard title="Completed" value={completedCount} icon={CheckCircle2} color="green" />
        <MetricCard title="Failed" value={failedCount} icon={AlertTriangle} color="red" />
      </div>

      {/* Today's Deliveries Section */}
      <div className="space-y-3 pt-1">
        <div className="flex items-center justify-between">
          <h3 className="text-xs font-black text-brand-navy uppercase tracking-wider">
            Today's Deliveries ({deliveries.length})
          </h3>
        </div>

        {loading ? (
          <div className="py-12 text-center text-slate-400 text-xs">
            <RefreshCw size={24} className="mx-auto mb-2 animate-spin text-brand-cyan" />
            Loading assigned tasks...
          </div>
        ) : deliveries.length === 0 ? (
          <div className="py-10 px-4 text-center bg-white rounded-2xl border border-slate-100 text-slate-400">
            <Package size={32} className="mx-auto mb-2 opacity-30" />
            <p className="text-xs font-bold text-slate-600">No active deliveries assigned</p>
            <p className="text-[11px] text-slate-400 mt-0.5">Check back soon for new dispatch tasks.</p>
          </div>
        ) : (
          deliveries.map((del) => (
            <div
              key={del.id}
              onClick={() => onOpenDelivery(del)}
              className="p-4 bg-white rounded-2xl border border-slate-100 hover:border-brand-cyan/40 shadow-xs hover:shadow-md transition-all duration-200 cursor-pointer space-y-3"
            >
              <div className="flex items-center justify-between">
                <span className="font-mono text-xs font-black text-brand-navy bg-slate-100 px-2 py-0.5 rounded border border-slate-200">
                  {del.trackingNumber}
                </span>
                <StatusBadge status={del.status} />
              </div>

              <div>
                <h4 className="text-sm font-extrabold text-slate-900">{del.customerName}</h4>
                <p className="text-xs text-slate-600 mt-0.5 flex items-center gap-1">
                  <MapPin size={13} className="text-brand-cyan shrink-0" />
                  <span className="truncate">{del.deliveryAddress}, {del.city}</span>
                </p>
              </div>

              <div className="pt-2 border-t border-slate-100 flex items-center justify-between">
                <span className="text-[11px] font-semibold text-slate-500">ETA: {del.eta || '30 mins'}</span>
                <span className="text-xs font-extrabold text-brand-blue flex items-center gap-1 hover:translate-x-0.5 transition-transform">
                  Manage Task <ArrowRight size={14} />
                </span>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};
