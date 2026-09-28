import React, { useState, useEffect } from 'react';
import { AlertTriangle, CheckCircle2, Clock, ShieldCheck, RefreshCw, Send, X } from 'lucide-react';
import api from '../../services/api';
import { StatusBadge } from '../common/StatusBadge';

export const EscalationCenter = () => {
  const [escalations, setEscalations] = useState([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [selectedEscalation, setSelectedEscalation] = useState(null);
  const [resolutionNotes, setResolutionNotes] = useState('');
  const [newStatus, setNewStatus] = useState('RESOLVED');
  const [updating, setUpdating] = useState(false);

  const fetchEscalations = async () => {
    try {
      setLoading(true);
      const res = await api.get('/escalations');
      setEscalations(res.data.escalations || []);
    } catch (err) {
      console.error('Failed to load escalations:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchEscalations();
  }, []);

  const handleUpdateEscalation = async (e) => {
    e.preventDefault();
    if (!selectedEscalation) return;

    setUpdating(true);
    try {
      await api.patch(`/escalations/${selectedEscalation.id}`, {
        status: newStatus,
        resolutionNotes
      });
      setSelectedEscalation(null);
      setResolutionNotes('');
      fetchEscalations();
    } catch (err) {
      console.error('Failed to update escalation:', err);
    } finally {
      setUpdating(false);
    }
  };

  const filtered = escalations.filter(e => statusFilter === 'ALL' || e.status === statusFilter);

  return (
    <div className="p-4 space-y-4 pb-20 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-lg font-black text-brand-navy">Escalation Center</h2>
          <p className="text-xs text-slate-500 font-medium">Resolve delivery failures & operational exceptions.</p>
        </div>

        <button
          onClick={fetchEscalations}
          className="p-2 rounded-xl bg-white border border-slate-200 text-slate-600 hover:text-brand-purple shadow-xs"
        >
          <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
        </button>
      </div>

      {/* Filter Tabs */}
      <div className="flex items-center gap-1.5 overflow-x-auto pb-1 scrollbar-none">
        {['ALL', 'OPEN', 'IN_PROGRESS', 'RESOLVED'].map((st) => (
          <button
            key={st}
            onClick={() => setStatusFilter(st)}
            className={`px-3 py-1.5 rounded-xl text-[11px] font-bold whitespace-nowrap transition-all ${
              statusFilter === st
                ? 'bg-brand-purple text-white shadow-xs'
                : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-50'
            }`}
          >
            {st.replace('_', ' ')}
          </button>
        ))}
      </div>

      {/* Escalation Cards List */}
      <div className="space-y-3">
        {loading ? (
          <div className="py-12 text-center text-slate-400 text-xs">
            <RefreshCw size={24} className="mx-auto mb-2 animate-spin text-brand-purple" />
            Loading escalations...
          </div>
        ) : filtered.length === 0 ? (
          <div className="py-10 px-4 text-center bg-white rounded-2xl border border-slate-100 text-slate-400">
            <CheckCircle2 size={32} className="mx-auto mb-2 text-emerald-500 opacity-80" />
            <p className="text-xs font-bold text-slate-700">No Escalations Found</p>
            <p className="text-[11px] text-slate-400 mt-0.5">Filter returned zero items.</p>
          </div>
        ) : (
          filtered.map((esc) => (
            <div
              key={esc.id}
              className="p-4 bg-white rounded-2xl border border-slate-100 hover:border-brand-purple/30 shadow-xs space-y-3"
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span className="font-mono text-xs font-extrabold text-brand-navy bg-slate-100 px-2 py-0.5 rounded">
                    {esc.delivery?.trackingNumber}
                  </span>
                  <span className={`text-[10px] font-black px-2 py-0.5 rounded uppercase ${
                    esc.priority === 'CRITICAL' ? 'bg-rose-100 text-rose-800' : 'bg-amber-100 text-amber-800'
                  }`}>
                    {esc.priority} Priority
                  </span>
                </div>
                <StatusBadge status={esc.status} />
              </div>

              <div>
                <h4 className="text-xs font-extrabold text-slate-900">
                  Customer: {esc.delivery?.customerName} ({esc.delivery?.customerPhone})
                </h4>
                <p className="text-xs text-rose-700 font-bold mt-1">
                  Failure Reason: {esc.failureReport?.reason?.replace('_', ' ')}
                </p>
                <p className="text-xs text-slate-600 italic mt-0.5 bg-slate-50 p-2 rounded-xl border border-slate-100">
                  "{esc.failureReport?.remarks}"
                </p>
              </div>

              {esc.resolutionNotes && (
                <div className="p-2.5 bg-emerald-50 rounded-xl border border-emerald-200 text-xs text-emerald-900 font-medium">
                  <strong className="block text-[10px] text-emerald-700 uppercase font-extrabold">Resolution Notes:</strong>
                  {esc.resolutionNotes}
                </div>
              )}

              {/* Action Button */}
              {esc.status !== 'RESOLVED' && (
                <div className="pt-2 border-t border-slate-100 flex justify-end">
                  <button
                    onClick={() => {
                      setSelectedEscalation(esc);
                      setNewStatus(esc.status === 'OPEN' ? 'IN_PROGRESS' : 'RESOLVED');
                      setResolutionNotes(esc.resolutionNotes || '');
                    }}
                    className="px-3.5 py-1.5 rounded-xl bg-brand-purple text-white text-xs font-bold shadow-xs hover:bg-purple-800"
                  >
                    Update / Resolve Escalation
                  </button>
                </div>
              )}
            </div>
          ))
        )}
      </div>

      {/* Resolution Modal Popup */}
      {selectedEscalation && (
        <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4">
          <div className="w-full max-w-md bg-white rounded-t-3xl sm:rounded-3xl shadow-2xl p-5 space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-extrabold text-brand-navy">Update Escalation Status</h3>
              <button onClick={() => setSelectedEscalation(null)} className="p-1 text-slate-400 hover:text-slate-700">
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleUpdateEscalation} className="space-y-3">
              <div className="space-y-1">
                <label className="text-xs font-bold text-slate-700">Select Status</label>
                <select
                  value={newStatus}
                  onChange={(e) => setNewStatus(e.target.value)}
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-bold"
                >
                  <option value="IN_PROGRESS">IN_PROGRESS (Under Investigation)</option>
                  <option value="RESOLVED">RESOLVED (Resolution Action Taken)</option>
                </select>
              </div>

              <div className="space-y-1">
                <label className="text-xs font-bold text-slate-700">Resolution Notes *</label>
                <textarea
                  rows={3}
                  value={resolutionNotes}
                  onChange={(e) => setResolutionNotes(e.target.value)}
                  placeholder="Enter resolution notes (e.g. Contacted customer, arranged redelivery for tomorrow)..."
                  required
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium text-slate-900"
                />
              </div>

              <button
                type="submit"
                disabled={updating}
                className="w-full py-3 rounded-xl bg-brand-purple text-white font-bold text-xs shadow-md"
              >
                {updating ? 'Saving...' : 'Submit Escalation Update'}
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
