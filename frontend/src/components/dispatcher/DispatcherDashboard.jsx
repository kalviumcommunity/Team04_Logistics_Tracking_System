import React, { useState, useEffect } from 'react';
import { Plus, Search, Filter, RefreshCw, Package, Truck, UserCheck, CheckCircle2, AlertTriangle, Clock } from 'lucide-react';
import api from '../../services/api';
import { MetricCard } from '../common/MetricCard';
import { StatusBadge } from '../common/StatusBadge';

export const DispatcherDashboard = ({ onCreateDelivery, onViewDelivery, onAssignDelivery }) => {
  const [deliveries, setDeliveries] = useState([]);
  const [analytics, setAnalytics] = useState(null);
  const [loading, setLoading] = useState(true);
  const [filterStatus, setFilterStatus] = useState('ALL');
  const [searchQuery, setSearchQuery] = useState('');

  const fetchData = async () => {
    try {
      setLoading(true);
      const [delRes, anaRes] = await Promise.all([
        api.get('/deliveries'),
        api.get('/analytics/overview')
      ]);
      setDeliveries(delRes.data.deliveries || []);
      setAnalytics(anaRes.data.metrics || null);
    } catch (err) {
      console.error('Error loading dispatcher data:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const filteredDeliveries = deliveries.filter(d => {
    const matchesStatus = filterStatus === 'ALL' || d.status === filterStatus;
    const matchesSearch =
      d.trackingNumber.toLowerCase().includes(searchQuery.toLowerCase()) ||
      d.customerName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      d.deliveryAddress.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesStatus && matchesSearch;
  });

  return (
    <div className="p-4 space-y-4 pb-20 animate-fade-in">
      {/* Top Banner Action */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-lg font-black text-brand-navy">Dispatcher Hub</h2>
          <p className="text-xs text-slate-500 font-medium">Create, assign and monitor active shipments.</p>
        </div>

        <button
          onClick={onCreateDelivery}
          className="py-2.5 px-3.5 rounded-xl bg-gradient-to-r from-brand-blue to-brand-blueDark text-white font-extrabold text-xs shadow-md shadow-brand-blue/20 hover:shadow-lg transition-all active:scale-95 flex items-center gap-1.5"
        >
          <Plus size={16} />
          <span>New Order</span>
        </button>
      </div>

      {/* Metric Cards Grid */}
      <div className="grid grid-cols-2 gap-2.5">
        <MetricCard
          title="Total Orders"
          value={analytics?.totalDeliveries ?? 0}
          icon={Package}
          color="blue"
          onClick={() => setFilterStatus('ALL')}
        />
        <MetricCard
          title="Active Transit"
          value={analytics?.activeDeliveries ?? 0}
          icon={Truck}
          color="cyan"
          onClick={() => setFilterStatus('IN_TRANSIT')}
        />
        <MetricCard
          title="Assigned"
          value={analytics?.assignedCount ?? 0}
          icon={UserCheck}
          color="amber"
          onClick={() => setFilterStatus('ASSIGNED')}
        />
        <MetricCard
          title="Delivered"
          value={analytics?.deliveredCount ?? 0}
          icon={CheckCircle2}
          color="green"
          onClick={() => setFilterStatus('DELIVERED')}
        />
        <MetricCard
          title="Failed"
          value={analytics?.failedCount ?? 0}
          icon={AlertTriangle}
          color="red"
          onClick={() => setFilterStatus('FAILED')}
        />
        <MetricCard
          title="Open Escalations"
          value={analytics?.openEscalations ?? 0}
          icon={AlertTriangle}
          color="purple"
        />
      </div>

      {/* Deliveries Section Header & Controls */}
      <div className="space-y-2.5 pt-2">
        <div className="flex items-center justify-between">
          <h3 className="text-xs font-black text-brand-navy uppercase tracking-wider">
            Live Deliveries ({filteredDeliveries.length})
          </h3>
          <button
            onClick={fetchData}
            className="text-xs text-brand-blue font-bold flex items-center gap-1 hover:underline"
          >
            <RefreshCw size={12} className={loading ? 'animate-spin' : ''} /> Refresh
          </button>
        </div>

        {/* Search Bar */}
        <div className="relative">
          <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search tracking ID, customer, address..."
            className="w-full pl-9 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-medium text-slate-900 focus:outline-none focus:ring-2 focus:ring-brand-blue/20"
          />
        </div>

        {/* Filter Pills */}
        <div className="flex items-center gap-1.5 overflow-x-auto pb-1 scrollbar-none">
          {['ALL', 'PENDING', 'ASSIGNED', 'IN_TRANSIT', 'DELIVERED', 'FAILED'].map((st) => (
            <button
              key={st}
              onClick={() => setFilterStatus(st)}
              className={`px-3 py-1.5 rounded-xl text-[11px] font-bold whitespace-nowrap transition-all ${
                filterStatus === st
                  ? 'bg-brand-navy text-white shadow-xs'
                  : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-50'
              }`}
            >
              {st.replace('_', ' ')}
            </button>
          ))}
        </div>
      </div>

      {/* Deliveries List Cards */}
      <div className="space-y-3">
        {loading ? (
          <div className="py-12 text-center text-slate-400 text-xs font-medium">
            <RefreshCw size={24} className="mx-auto mb-2 animate-spin text-brand-blue" />
            Loading deliveries...
          </div>
        ) : filteredDeliveries.length === 0 ? (
          <div className="py-10 px-4 text-center bg-white rounded-2xl border border-slate-100 text-slate-400">
            <Package size={32} className="mx-auto mb-2 opacity-30" />
            <p className="text-xs font-bold text-slate-600">No deliveries found</p>
            <p className="text-[11px] text-slate-400 mt-0.5">Try adjusting search or status filter.</p>
          </div>
        ) : (
          filteredDeliveries.map((del) => (
            <div
              key={del.id}
              onClick={() => onViewDelivery(del)}
              className="p-3.5 bg-white rounded-2xl border border-slate-100 hover:border-slate-200 shadow-xs hover:shadow-sm transition-all duration-200 cursor-pointer space-y-2.5"
            >
              {/* Card Top */}
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span className="font-mono text-xs font-extrabold text-brand-navy bg-slate-100 px-2 py-0.5 rounded-lg border border-slate-200">
                    {del.trackingNumber}
                  </span>
                  <StatusBadge status={del.status} />
                </div>
                <span className="text-[11px] font-bold text-slate-500 flex items-center gap-1">
                  <Clock size={12} /> {del.eta || 'ETA Pending'}
                </span>
              </div>

              {/* Customer & Location */}
              <div>
                <h4 className="text-xs font-bold text-slate-900">{del.customerName}</h4>
                <p className="text-[11px] text-slate-500 truncate mt-0.5">
                  📍 {del.deliveryAddress}, {del.city}
                </p>
              </div>

              {/* Executive & Quick Actions */}
              <div className="pt-2 border-t border-slate-100 flex items-center justify-between text-xs">
                <div className="flex items-center gap-1.5 text-slate-600">
                  <span className="text-[10px] font-semibold text-slate-400">Exec:</span>
                  {del.assignedExecutive ? (
                    <span className="font-bold text-slate-800">{del.assignedExecutive.fullName}</span>
                  ) : (
                    <span className="text-amber-600 font-bold bg-amber-50 px-1.5 py-0.5 rounded text-[10px]">Unassigned</span>
                  )}
                </div>

                {!del.assignedExecutive && (
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      onAssignDelivery(del);
                    }}
                    className="px-2.5 py-1 rounded-lg bg-brand-blue text-white text-[10px] font-extrabold shadow-xs hover:bg-blue-700"
                  >
                    Assign Now
                  </button>
                )}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};
