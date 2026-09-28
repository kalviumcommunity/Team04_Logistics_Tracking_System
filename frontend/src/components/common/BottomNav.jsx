import React from 'react';
import { Home, Package, Users, AlertTriangle, BarChart3, Bell, User } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { useNotifications } from '../../context/NotificationContext';

export const BottomNav = ({ activeTab, setActiveTab }) => {
  const { user } = useAuth();
  const { unreadCount } = useNotifications();

  if (!user) return null;

  const role = user.role;

  // Define tabs based on user role
  const getTabs = () => {
    switch (role) {
      case 'DISPATCHER':
        return [
          { id: 'home', label: 'Home', icon: Home },
          { id: 'deliveries', label: 'Deliveries', icon: Package },
          { id: 'executives', label: 'Executives', icon: Users },
          { id: 'notifications', label: 'Alerts', icon: Bell, badge: unreadCount },
          { id: 'profile', label: 'Profile', icon: User }
        ];
      case 'DELIVERY_EXECUTIVE':
        return [
          { id: 'home', label: 'Home', icon: Home },
          { id: 'deliveries', label: 'Deliveries', icon: Package },
          { id: 'escalations', label: 'Escalations', icon: AlertTriangle },
          { id: 'notifications', label: 'Alerts', icon: Bell, badge: unreadCount },
          { id: 'profile', label: 'Profile', icon: User }
        ];
      case 'OPERATIONS':
        return [
          { id: 'home', label: 'Home', icon: Home },
          { id: 'deliveries', label: 'Deliveries', icon: Package },
          { id: 'escalations', label: 'Escalations', icon: AlertTriangle },
          { id: 'analytics', label: 'Analytics', icon: BarChart3 },
          { id: 'profile', label: 'Profile', icon: User }
        ];
      default:
        return [
          { id: 'home', label: 'Home', icon: Home },
          { id: 'deliveries', label: 'Deliveries', icon: Package },
          { id: 'profile', label: 'Profile', icon: User }
        ];
    }
  };

  const tabs = getTabs();

  return (
    <nav className="sticky bottom-0 z-40 bg-white/95 backdrop-blur-md border-t border-slate-100 px-2 py-1.5 flex items-center justify-around shadow-lg">
      {tabs.map((tab) => {
        const Icon = tab.icon;
        const isActive = activeTab === tab.id;

        return (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`relative flex-1 flex flex-col items-center justify-center py-1.5 px-1 rounded-xl transition-all duration-200 ${
              isActive
                ? 'text-brand-blue font-bold'
                : 'text-slate-400 hover:text-slate-600 font-medium'
            }`}
          >
            {/* Active Pill Indicator */}
            {isActive && (
              <span className="absolute -top-1.5 w-8 h-1 bg-gradient-to-r from-brand-blue to-brand-cyan rounded-full shadow-sm shadow-brand-blue/40 animate-fade-in" />
            )}

            <div className="relative">
              <Icon size={20} className={isActive ? 'stroke-[2.5px] scale-110 transition-transform' : 'stroke-[1.8px]'} />
              {tab.badge > 0 && (
                <span className="absolute -top-1 -right-2 min-w-[16px] h-4 bg-brand-error text-white text-[9px] font-black rounded-full flex items-center justify-center px-1 border-2 border-white">
                  {tab.badge > 9 ? '9+' : tab.badge}
                </span>
              )}
            </div>

            <span className={`text-[10px] mt-1 tracking-tight ${isActive ? 'text-brand-blue' : 'text-slate-500'}`}>
              {tab.label}
            </span>
          </button>
        );
      })}
    </nav>
  );
};
