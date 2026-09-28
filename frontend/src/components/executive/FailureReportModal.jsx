import React, { useState } from 'react';
import { X, AlertTriangle, Camera, Send, AlertCircle } from 'lucide-react';
import api from '../../services/api';

export const FailureReportModal = ({ delivery, isOpen, onClose, onSuccess }) => {
  const [reason, setReason] = useState('CUSTOMER_UNAVAILABLE');
  const [remarks, setRemarks] = useState('');
  const [photoSelected, setPhotoSelected] = useState(true);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  if (!isOpen || !delivery) return null;

  const failureReasons = [
    { value: 'CUSTOMER_UNAVAILABLE', label: 'Customer Unavailable' },
    { value: 'WRONG_ADDRESS', label: 'Wrong Address' },
    { value: 'CUSTOMER_REJECTED', label: 'Customer Rejected Delivery' },
    { value: 'VEHICLE_ISSUE', label: 'Vehicle Issue / Breakdown' },
    { value: 'ADDRESS_INACCESSIBLE', label: 'Address Inaccessible' },
    { value: 'WEATHER_DELAY', label: 'Severe Weather Delay' },
    { value: 'OTHER', label: 'Other Reason' }
  ];

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!remarks.trim()) {
      setError('Please provide detailed remarks for the delivery failure.');
      return;
    }

    setError('');
    setLoading(true);

    try {
      await api.post(`/deliveries/${delivery.id}/failure`, {
        reason,
        remarks,
        evidenceUrl: 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=400&q=80'
      });
      onSuccess();
      onClose();
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to submit failure report.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4 animate-fade-in">
      <div className="w-full max-w-md bg-white rounded-t-3xl sm:rounded-3xl shadow-2xl overflow-hidden flex flex-col max-h-[90vh] animate-slide-up">
        {/* Header */}
        <div className="px-5 py-4 bg-brand-error text-white flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="p-2 bg-white/20 rounded-xl">
              <AlertTriangle size={18} />
            </div>
            <div>
              <h2 className="text-base font-extrabold">Report Delivery Failure</h2>
              <p className="text-xs text-rose-100 font-medium">{delivery.trackingNumber} • {delivery.customerName}</p>
            </div>
          </div>
          <button onClick={onClose} className="p-1.5 rounded-full hover:bg-white/10 text-rose-100 hover:text-white">
            <X size={18} />
          </button>
        </div>

        {/* Form Body */}
        <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto p-5 space-y-4 bg-brand-bg">
          {error && (
            <div className="p-3 bg-rose-50 border border-rose-200 rounded-xl flex items-center gap-2 text-rose-700 text-xs font-semibold">
              <AlertCircle size={16} className="shrink-0" />
              <span>{error}</span>
            </div>
          )}

          {/* Failure Reason */}
          <div className="space-y-1.5">
            <label className="text-xs font-bold text-slate-800">Failure Reason *</label>
            <select
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              className="w-full p-3 bg-white border border-slate-200 rounded-xl text-xs font-bold text-slate-900 focus:outline-none focus:ring-2 focus:ring-rose-500/30"
            >
              {failureReasons.map((r) => (
                <option key={r.value} value={r.value}>
                  {r.label}
                </option>
              ))}
            </select>
          </div>

          {/* Remarks */}
          <div className="space-y-1.5">
            <label className="text-xs font-bold text-slate-800">Detailed Remarks *</label>
            <textarea
              rows={3}
              value={remarks}
              onChange={(e) => setRemarks(e.target.value)}
              placeholder="Provide exact details (e.g. Call attempted 3 times, door locked)..."
              required
              className="w-full p-3 bg-white border border-slate-200 rounded-xl text-xs font-medium text-slate-900 focus:outline-none focus:ring-2 focus:ring-rose-500/30"
            />
          </div>

          {/* Photo Evidence Upload Mock */}
          <div className="space-y-1.5">
            <label className="text-xs font-bold text-slate-800">Evidence Photo (Optional)</label>
            <div className="p-3 bg-white border-2 border-dashed border-slate-200 rounded-2xl flex items-center justify-between">
              <div className="flex items-center gap-2.5">
                <div className="w-10 h-10 rounded-xl bg-slate-100 flex items-center justify-center text-slate-500">
                  <Camera size={20} />
                </div>
                <div>
                  <p className="text-xs font-bold text-slate-800">
                    {photoSelected ? 'location_evidence_photo.jpg' : 'Attach Photo Evidence'}
                  </p>
                  <p className="text-[10px] text-slate-400">Doorbell/location photo automatically geotagged</p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setPhotoSelected(!photoSelected)}
                className={`px-3 py-1.5 rounded-xl text-xs font-extrabold transition-all ${
                  photoSelected ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' : 'bg-slate-100 text-slate-700'
                }`}
              >
                {photoSelected ? 'Attached ✓' : 'Add Photo'}
              </button>
            </div>
          </div>

          <div className="p-3 bg-rose-50/70 rounded-xl border border-rose-200/80 text-[11px] text-rose-800 font-medium leading-relaxed">
            🚨 <strong>Escalation Notice:</strong> Submitting this failure report will automatically open an active escalation for the <strong>Operations Control Team</strong>.
          </div>

          {/* Submit */}
          <button
            type="submit"
            disabled={loading}
            className="w-full py-3.5 px-4 rounded-2xl bg-brand-error text-white font-extrabold text-xs shadow-lg shadow-rose-500/20 hover:bg-rose-700 transition-all active:scale-[0.98] flex items-center justify-center gap-2 disabled:opacity-75"
          >
            {loading ? (
              <span className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
            ) : (
              <>
                <Send size={16} />
                <span>Submit Failure & Log Escalation</span>
              </>
            )}
          </button>
        </form>
      </div>
    </div>
  );
};
