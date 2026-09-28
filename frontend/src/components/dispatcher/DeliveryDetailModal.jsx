import React from 'react';
import { X, Phone, MapPin, Calendar, Clock, User, ShieldCheck, History, AlertTriangle } from 'lucide-react';
import { StatusBadge } from '../common/StatusBadge';

export const DeliveryDetailModal = ({ delivery, isOpen, onClose, onReassign, onCancel }) => {
  if (!isOpen || !delivery) return null;

  return (
    <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4 animate-fade-in">
      <div className="w-full max-w-md bg-white rounded-t-3xl sm:rounded-3xl shadow-2xl overflow-hidden flex flex-col max-h-[90vh] animate-slide-up">
        {/* Header */}
        <div className="px-5 py-4 bg-brand-navy text-white flex items-center justify-between">
          <div>
            <div className="flex items-center gap-2">
              <span className="font-mono text-xs font-black bg-brand-blue/30 text-brand-cyan px-2 py-0.5 rounded border border-brand-cyan/30">
                {delivery.trackingNumber}
              </span>
              <StatusBadge status={delivery.status} />
            </div>
            <p className="text-[11px] text-slate-300 mt-1">
              Created on {new Date(delivery.createdAt).toLocaleDateString()}
            </p>
          </div>
          <button onClick={onClose} className="p-1.5 rounded-full hover:bg-white/10 text-slate-300 hover:text-white">
            <X size={18} />
          </button>
        </div>

        {/* Content Body */}
        <div className="flex-1 overflow-y-auto p-4 space-y-4 bg-brand-bg">
          {/* Customer Card */}
          <div className="p-3.5 bg-white rounded-2xl border border-slate-100 shadow-xs space-y-2">
            <h4 className="text-xs font-black text-brand-navy uppercase tracking-wider flex items-center gap-1.5">
              <User size={14} className="text-brand-blue" /> Customer Information
            </h4>
            <div className="flex items-center justify-between pt-1">
              <div>
                <p className="text-xs font-bold text-slate-900">{delivery.customerName}</p>
                <p className="text-[11px] text-slate-500">{delivery.customerPhone}</p>
              </div>
              <a
                href={`tel:${delivery.customerPhone}`}
                className="px-3 py-1.5 rounded-xl bg-teal-50 text-teal-700 text-xs font-bold border border-teal-200 hover:bg-teal-100 flex items-center gap-1"
              >
                <Phone size={12} /> Call
              </a>
            </div>
          </div>

          {/* Route & Location */}
          <div className="p-3.5 bg-white rounded-2xl border border-slate-100 shadow-xs space-y-2.5">
            <h4 className="text-xs font-black text-brand-navy uppercase tracking-wider flex items-center gap-1.5">
              <MapPin size={14} className="text-brand-cyan" /> Delivery Route
            </h4>

            <div className="relative pl-6 space-y-3 before:absolute before:left-2 before:top-2 before:bottom-2 before:w-0.5 before:bg-slate-200">
              {/* Pickup */}
              <div className="relative">
                <span className="absolute -left-6 top-1 w-2.5 h-2.5 rounded-full bg-brand-blue ring-4 ring-blue-100" />
                <span className="text-[10px] font-bold text-slate-400 uppercase">Pickup Location</span>
                <p className="text-xs font-medium text-slate-800">{delivery.pickupAddress}</p>
              </div>

              {/* Destination */}
              <div className="relative">
                <span className="absolute -left-6 top-1 w-2.5 h-2.5 rounded-full bg-brand-cyan ring-4 ring-teal-100" />
                <span className="text-[10px] font-bold text-slate-400 uppercase">Destination Address</span>
                <p className="text-xs font-bold text-slate-900">{delivery.deliveryAddress}, {delivery.city}</p>
              </div>
            </div>
          </div>

          {/* Assigned Executive */}
          <div className="p-3.5 bg-white rounded-2xl border border-slate-100 shadow-xs space-y-2">
            <div className="flex items-center justify-between">
              <h4 className="text-xs font-black text-brand-navy uppercase tracking-wider flex items-center gap-1.5">
                <ShieldCheck size={14} className="text-brand-purple" /> Assigned Executive
              </h4>
              {onReassign && (
                <button
                  onClick={() => onReassign(delivery)}
                  className="text-[11px] font-bold text-brand-blue hover:underline"
                >
                  Reassign
                </button>
              )}
            </div>

            {delivery.assignedExecutive ? (
              <div className="flex items-center justify-between pt-1">
                <div>
                  <p className="text-xs font-bold text-slate-900">{delivery.assignedExecutive.fullName}</p>
                  <p className="text-[11px] text-slate-500">{delivery.assignedExecutive.phone}</p>
                </div>
                <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200">
                  Assigned
                </span>
              </div>
            ) : (
              <div className="p-2.5 bg-amber-50 rounded-xl border border-amber-200 text-amber-800 text-xs font-medium text-center">
                No delivery executive assigned yet.
              </div>
            )}
          </div>

          {/* Failure Report Info (if failed) */}
          {delivery.latestFailure && (
            <div className="p-3.5 bg-rose-50 rounded-2xl border border-rose-200 space-y-2">
              <h4 className="text-xs font-black text-rose-800 uppercase tracking-wider flex items-center gap-1.5">
                <AlertTriangle size={14} className="text-rose-600" /> Failure Report Submitted
              </h4>
              <p className="text-xs font-bold text-rose-900">
                Reason: {delivery.latestFailure.reason.replace('_', ' ')}
              </p>
              <p className="text-xs text-rose-700 font-medium">"{delivery.latestFailure.remarks}"</p>
            </div>
          )}

          {/* Status Timeline History */}
          <div className="p-3.5 bg-white rounded-2xl border border-slate-100 shadow-xs space-y-3">
            <h4 className="text-xs font-black text-brand-navy uppercase tracking-wider flex items-center gap-1.5">
              <History size={14} className="text-brand-blue" /> Status History Timeline
            </h4>

            <div className="space-y-2.5 pl-2">
              {(delivery.statusHistory || []).map((h, idx) => (
                <div key={h.id || idx} className="flex items-start gap-2.5 text-xs">
                  <div className="w-2 h-2 rounded-full bg-brand-blue mt-1.5 shrink-0" />
                  <div className="flex-1">
                    <div className="flex items-center justify-between">
                      <span className="font-bold text-slate-800">{h.status}</span>
                      <span className="text-[10px] text-slate-400 font-mono">
                        {new Date(h.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </span>
                    </div>
                    {h.remarks && <p className="text-[11px] text-slate-500 mt-0.5">{h.remarks}</p>}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Footer Actions */}
        {delivery.status !== 'DELIVERED' && delivery.status !== 'CANCELLED' && onCancel && (
          <div className="p-4 bg-white border-t border-slate-100">
            <button
              onClick={() => onCancel(delivery.id)}
              className="w-full py-2.5 px-4 rounded-xl bg-rose-50 text-rose-700 hover:bg-rose-100 text-xs font-extrabold border border-rose-200 transition-all"
            >
              Cancel Delivery Order
            </button>
          </div>
        )}
      </div>
    </div>
  );
};
