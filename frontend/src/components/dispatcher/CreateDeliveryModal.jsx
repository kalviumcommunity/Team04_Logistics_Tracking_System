import React, { useState, useEffect } from 'react';
import { X, Package, User, Phone, MapPin, Calendar, Clock, AlertCircle } from 'lucide-react';
import api from '../../services/api';

export const CreateDeliveryModal = ({ isOpen, onClose, onSuccess }) => {
  const [customerName, setCustomerName] = useState('');
  const [customerPhone, setCustomerPhone] = useState('');
  const [pickupAddress, setPickupAddress] = useState('Central Warehouse, Bay 4');
  const [deliveryAddress, setDeliveryAddress] = useState('');
  const [city, setCity] = useState('Metropolis');
  const [deliveryDate, setDeliveryDate] = useState(new Date().toISOString().split('T')[0]);
  const [deliveryTime, setDeliveryTime] = useState('14:00');
  const [assignedExecutiveId, setAssignedExecutiveId] = useState('');
  const [remarks, setRemarks] = useState('');

  const [executives, setExecutives] = useState([]);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (isOpen) {
      api.get('/executives')
        .then(res => setExecutives(res.data.executives || []))
        .catch(err => console.error('Failed to load executives', err));
    }
  }, [isOpen]);

  if (!isOpen) return null;

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!customerName || !customerPhone || !pickupAddress || !deliveryAddress || !city || !deliveryDate || !deliveryTime) {
      setError('Please fill in all required fields.');
      return;
    }

    setError('');
    setLoading(true);

    try {
      await api.post('/deliveries', {
        customerName,
        customerPhone,
        pickupAddress,
        deliveryAddress,
        city,
        deliveryDate,
        deliveryTime,
        assignedExecutiveId: assignedExecutiveId || null,
        remarks
      });
      onSuccess();
      onClose();
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to create delivery.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4 animate-fade-in">
      <div className="w-full max-w-md bg-white rounded-t-3xl sm:rounded-3xl shadow-2xl overflow-hidden flex flex-col max-h-[90vh] animate-slide-up">
        {/* Header */}
        <div className="px-5 py-4 bg-brand-navy text-white flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="p-2 bg-brand-blue/20 rounded-xl border border-brand-blue/30 text-brand-cyan">
              <Package size={18} />
            </div>
            <div>
              <h2 className="text-base font-bold">Create New Delivery</h2>
              <p className="text-xs text-slate-300">Dispatch a new package in DeliverSync.</p>
            </div>
          </div>
          <button onClick={onClose} className="p-1.5 rounded-full hover:bg-white/10 text-slate-300 hover:text-white">
            <X size={18} />
          </button>
        </div>

        {/* Form Body */}
        <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto p-5 space-y-3.5 bg-brand-bg">
          {error && (
            <div className="p-3 bg-rose-50 border border-rose-200 rounded-xl flex items-center gap-2 text-rose-700 text-xs font-semibold">
              <AlertCircle size={16} className="shrink-0" />
              <span>{error}</span>
            </div>
          )}

          {/* Customer Name & Phone */}
          <div className="grid grid-cols-2 gap-2">
            <div className="space-y-1">
              <label className="text-[11px] font-bold text-slate-700">Customer Name *</label>
              <div className="relative">
                <User size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                <input
                  type="text"
                  value={customerName}
                  onChange={(e) => setCustomerName(e.target.value)}
                  placeholder="Elena Rostova"
                  required
                  className="w-full pl-8 pr-2 py-2 bg-white border border-slate-200 rounded-xl text-xs font-medium text-slate-900 focus:outline-none focus:ring-2 focus:ring-brand-blue/20"
                />
              </div>
            </div>

            <div className="space-y-1">
              <label className="text-[11px] font-bold text-slate-700">Customer Phone *</label>
              <div className="relative">
                <Phone size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                <input
                  type="tel"
                  value={customerPhone}
                  onChange={(e) => setCustomerPhone(e.target.value)}
                  placeholder="+1 (555) 0199"
                  required
                  className="w-full pl-8 pr-2 py-2 bg-white border border-slate-200 rounded-xl text-xs font-medium text-slate-900 focus:outline-none focus:ring-2 focus:ring-brand-blue/20"
                />
              </div>
            </div>
          </div>

          {/* Pickup Address */}
          <div className="space-y-1">
            <label className="text-[11px] font-bold text-slate-700">Pickup Address *</label>
            <div className="relative">
              <MapPin size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
              <input
                type="text"
                value={pickupAddress}
                onChange={(e) => setPickupAddress(e.target.value)}
                placeholder="Warehouse A, Tech Hub"
                required
                className="w-full pl-8 pr-2 py-2 bg-white border border-slate-200 rounded-xl text-xs font-medium text-slate-900 focus:outline-none focus:ring-2 focus:ring-brand-blue/20"
              />
            </div>
          </div>

          {/* Delivery Address & City */}
          <div className="grid grid-cols-3 gap-2">
            <div className="col-span-2 space-y-1">
              <label className="text-[11px] font-bold text-slate-700">Delivery Address *</label>
              <input
                type="text"
                value={deliveryAddress}
                onChange={(e) => setDeliveryAddress(e.target.value)}
                placeholder="742 Evergreen Terrace"
                required
                className="w-full px-3 py-2 bg-white border border-slate-200 rounded-xl text-xs font-medium text-slate-900 focus:outline-none focus:ring-2 focus:ring-brand-blue/20"
              />
            </div>
            <div className="space-y-1">
              <label className="text-[11px] font-bold text-slate-700">City *</label>
              <input
                type="text"
                value={city}
                onChange={(e) => setCity(e.target.value)}
                placeholder="Metropolis"
                required
                className="w-full px-3 py-2 bg-white border border-slate-200 rounded-xl text-xs font-medium text-slate-900 focus:outline-none focus:ring-2 focus:ring-brand-blue/20"
              />
            </div>
          </div>

          {/* Date & Time */}
          <div className="grid grid-cols-2 gap-2">
            <div className="space-y-1">
              <label className="text-[11px] font-bold text-slate-700">Delivery Date *</label>
              <div className="relative">
                <Calendar size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                <input
                  type="date"
                  value={deliveryDate}
                  onChange={(e) => setDeliveryDate(e.target.value)}
                  required
                  className="w-full pl-8 pr-2 py-2 bg-white border border-slate-200 rounded-xl text-xs font-medium text-slate-900 focus:outline-none focus:ring-2 focus:ring-brand-blue/20"
                />
              </div>
            </div>

            <div className="space-y-1">
              <label className="text-[11px] font-bold text-slate-700">Preferred Time *</label>
              <div className="relative">
                <Clock size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                <input
                  type="time"
                  value={deliveryTime}
                  onChange={(e) => setDeliveryTime(e.target.value)}
                  required
                  className="w-full pl-8 pr-2 py-2 bg-white border border-slate-200 rounded-xl text-xs font-medium text-slate-900 focus:outline-none focus:ring-2 focus:ring-brand-blue/20"
                />
              </div>
            </div>
          </div>

          {/* Assigned Executive */}
          <div className="space-y-1">
            <label className="text-[11px] font-bold text-slate-700">Assign Executive (Optional)</label>
            <select
              value={assignedExecutiveId}
              onChange={(e) => setAssignedExecutiveId(e.target.value)}
              className="w-full px-3 py-2 bg-white border border-slate-200 rounded-xl text-xs font-medium text-slate-900 focus:outline-none focus:ring-2 focus:ring-brand-blue/20"
            >
              <option value="">-- Assign Later (Pending) --</option>
              {executives.map(exec => (
                <option key={exec.id} value={exec.id}>
                  {exec.fullName} ({exec.status === 'AVAILABLE' ? '🟢 Available' : '🟡 On Duty'})
                </option>
              ))}
            </select>
          </div>

          {/* Remarks */}
          <div className="space-y-1">
            <label className="text-[11px] font-bold text-slate-700">Delivery Remarks</label>
            <textarea
              rows={2}
              value={remarks}
              onChange={(e) => setRemarks(e.target.value)}
              placeholder="e.g. Fragile package, call before arrival..."
              className="w-full p-2.5 bg-white border border-slate-200 rounded-xl text-xs font-medium text-slate-900 focus:outline-none focus:ring-2 focus:ring-brand-blue/20"
            />
          </div>

          {/* Submit */}
          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 px-4 rounded-xl bg-gradient-to-r from-brand-blue to-brand-blueDark text-white font-extrabold text-xs shadow-md hover:shadow-lg transition-all active:scale-95 disabled:opacity-75"
          >
            {loading ? 'Creating Order...' : 'Dispatch Delivery Order'}
          </button>
        </form>
      </div>
    </div>
  );
};
