import React from 'react';
import { X, Phone, MapPin, Navigation, Play, CheckCircle2, AlertTriangle, Clock, History } from 'lucide-react';
import { StatusBadge } from '../common/StatusBadge';

export const FieldDeliveryDetail = ({ delivery, isOpen, onClose, onStartDelivery, onMarkDelivered, onMarkFailed }) => {
  if (!isOpen || !delivery) return null;

  return (
    <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4 animate-fade-in">
      <div className="w-full max-w-md bg-white rounded-t-3xl sm:rounded-3xl shadow-2xl overflow-hidden flex flex-col max-h-[92vh] animate-slide-up">
        {/* Header */}
        <div className="px-5 py-4 bg-brand-navy text-white flex items-center justify-between">
          <div>
            <div className="flex items-center gap-2">
              <span className="font-mono text-xs font-black bg-brand-cyan/20 text-brand-cyan px-2 py-0.5 rounded border border-brand-cyan/30">
                {delivery.trackingNumber}
              </span>
              <StatusBadge status={delivery.status} />
            </div>
            <p className="text-[11px] text-slate-300 mt-1">Field Logistics Action View</p>
          </div>
          <button onClick={onClose} className="p-1.5 rounded-full hover:bg-white/10 text-slate-300 hover:text-white">
            <X size={18} />
          </button>
        </div>

        {/* Scrollable Content */}
        <div className="flex-1 overflow-y-auto p-4 space-y-4 bg-brand-bg">
          {/* Interactive Map Mock Graphic */}
          <div className="w-full h-36 bg-slate-200 rounded-2xl overflow-hidden relative border border-slate-300 shadow-inner">
            <svg viewBox="0 0 360 140" fill="none" className="w-full h-full object-cover">
              <rect width="360" height="140" fill="#E2E8F0" />
              {/* Road network */}
              <path d="M 0 40 L 360 40 M 0 100 L 360 100 M 100 0 L 100 140 M 260 0 L 260 140" stroke="#CBD5E1" strokeWidth="16" />
              <path d="M 0 40 L 360 40 M 0 100 L 360 100 M 100 0 L 100 140 M 260 0 L 260 140" stroke="#FFFFFF" strokeWidth="10" />
              {/* Active Route */}
              <path d="M 40 40 Q 180 30 260 100" stroke="#1769E8" strokeWidth="5" fill="none" strokeDasharray="6 6" />
              {/* Driver Marker */}
              <circle cx="100" cy="40" r="10" fill="#1769E8" />
              <circle cx="100" cy="40" r="4" fill="#FFFFFF" />
              {/* Destination Marker */}
              <g transform="translate(260, 100)">
                <circle cx="0" cy="0" r="12" fill="#EF4444" opacity="0.3" />
                <circle cx="0" cy="0" r="7" fill="#EF4444" />
              </g>
            </svg>

            {/* Floating Navigation Pill */}
            <div className="absolute bottom-2 right-2 bg-white/95 backdrop-blur px-3 py-1.5 rounded-xl shadow-md border border-slate-200 flex items-center gap-1.5 text-xs font-extrabold text-brand-blue">
              <Navigation size={14} className="fill-brand-blue" />
              <span>Navigate GPS</span>
            </div>
          </div>

          {/* Customer & Call Button */}
          <div className="p-4 bg-white rounded-2xl border border-slate-100 shadow-xs flex items-center justify-between">
            <div>
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Customer Details</span>
              <h4 className="text-sm font-extrabold text-slate-900 mt-0.5">{delivery.customerName}</h4>
              <p className="text-xs text-slate-500">{delivery.customerPhone}</p>
            </div>
            <a
              href={`tel:${delivery.customerPhone}`}
              className="px-4 py-2 rounded-xl bg-teal-500 text-white font-extrabold text-xs shadow-md shadow-teal-500/20 hover:bg-teal-600 flex items-center gap-1.5 active:scale-95 transition-all"
            >
              <Phone size={14} /> Call Customer
            </a>
          </div>

          {/* Location Address */}
          <div className="p-4 bg-white rounded-2xl border border-slate-100 shadow-xs space-y-2">
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Delivery Destination</span>
            <div className="flex items-start gap-2 pt-0.5">
              <MapPin size={18} className="text-brand-cyan shrink-0 mt-0.5" />
              <div>
                <p className="text-xs font-extrabold text-slate-900">{delivery.deliveryAddress}</p>
                <p className="text-xs text-slate-500 font-medium">{delivery.city} • Preferred: {delivery.deliveryTime}</p>
              </div>
            </div>
            {delivery.remarks && (
              <div className="p-2.5 bg-slate-50 rounded-xl text-xs text-slate-600 font-medium italic border border-slate-200/60 mt-2">
                "Remarks: {delivery.remarks}"
              </div>
            )}
          </div>

          {/* Timeline */}
          <div className="p-4 bg-white rounded-2xl border border-slate-100 shadow-xs space-y-2.5">
            <h4 className="text-xs font-black text-brand-navy uppercase tracking-wider flex items-center gap-1.5">
              <History size={14} className="text-brand-blue" /> Delivery Timeline
            </h4>
            <div className="space-y-2 pl-2">
              {(delivery.statusHistory || []).map((h, idx) => (
                <div key={idx} className="flex items-center justify-between text-xs">
                  <span className="font-semibold text-slate-700">{h.status}</span>
                  <span className="text-[10px] text-slate-400 font-mono">
                    {new Date(h.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Executive Quick Actions Toolbar */}
        <div className="p-4 bg-white border-t border-slate-100 space-y-2">
          {delivery.status === 'ASSIGNED' && (
            <button
              onClick={() => onStartDelivery(delivery.id)}
              className="w-full py-3.5 px-4 rounded-2xl bg-gradient-to-r from-brand-blue to-brand-blueDark text-white font-extrabold text-xs shadow-lg shadow-brand-blue/30 hover:shadow-xl transition-all active:scale-[0.98] flex items-center justify-center gap-2"
            >
              <Play size={16} fill="white" />
              <span>Start Delivery (In Transit)</span>
            </button>
          )}

          {delivery.status === 'IN_TRANSIT' && (
            <div className="grid grid-cols-2 gap-2">
              <button
                onClick={() => onMarkDelivered(delivery.id)}
                className="py-3 px-3 rounded-2xl bg-brand-success text-white font-extrabold text-xs shadow-md shadow-emerald-500/20 hover:bg-emerald-700 transition-all active:scale-[0.98] flex items-center justify-center gap-1.5"
              >
                <CheckCircle2 size={16} />
                <span>Mark Delivered</span>
              </button>

              <button
                onClick={() => onMarkFailed(delivery)}
                className="py-3 px-3 rounded-2xl bg-brand-error text-white font-extrabold text-xs shadow-md shadow-rose-500/20 hover:bg-rose-700 transition-all active:scale-[0.98] flex items-center justify-center gap-1.5"
              >
                <AlertTriangle size={16} />
                <span>Mark Failed</span>
              </button>
            </div>
          )}

          {(delivery.status === 'DELIVERED' || delivery.status === 'FAILED') && (
            <div className="py-2.5 px-4 bg-slate-100 text-slate-700 text-xs font-bold text-center rounded-xl border border-slate-200">
              Task finalized as {delivery.status}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
