import React, { useState } from 'react';
import { useAuth } from './context/AuthContext';
import { MobileFrame } from './components/common/MobileFrame';
import { Header } from './components/common/Header';
import { BottomNav } from './components/common/BottomNav';
import { NotificationCenter } from './components/common/NotificationCenter';

// Welcome & Auth
import { WelcomeScreen } from './components/welcome/WelcomeScreen';
import { OnboardingCarousel } from './components/welcome/OnboardingCarousel';
import { RoleIntroduction } from './components/welcome/RoleIntroduction';
import { LoginForm } from './components/auth/LoginForm';
import { RegisterForm } from './components/auth/RegisterForm';
import { ForgotPasswordForm } from './components/auth/ForgotPasswordForm';

// Dispatcher
import { DispatcherDashboard } from './components/dispatcher/DispatcherDashboard';
import { CreateDeliveryModal } from './components/dispatcher/CreateDeliveryModal';
import { DeliveryDetailModal } from './components/dispatcher/DeliveryDetailModal';

// Executive
import { ExecutiveDashboard } from './components/executive/ExecutiveDashboard';
import { FieldDeliveryDetail } from './components/executive/FieldDeliveryDetail';
import { FailureReportModal } from './components/executive/FailureReportModal';

// Operations
import { OperationsDashboard } from './components/operations/OperationsDashboard';
import { EscalationCenter } from './components/operations/EscalationCenter';
import { AnalyticsView } from './components/operations/AnalyticsView';

// Profile
import { UserProfile } from './components/profile/UserProfile';

export function App() {
  const { user, loading, logout } = useAuth();

  // Landing flow state (for unauthenticated users)
  const [unauthScreen, setUnauthScreen] = useState('welcome'); // welcome | onboarding | roleIntro | login | register | forgot
  const [selectedRole, setSelectedRole] = useState('DISPATCHER');

  // Navigation tab for logged-in user
  const [activeTab, setActiveTab] = useState('home');

  // Modals & Panels
  const [isNotificationsOpen, setIsNotificationsOpen] = useState(false);
  const [isCreateDeliveryOpen, setIsCreateDeliveryOpen] = useState(false);
  const [selectedDelivery, setSelectedDelivery] = useState(null);
  const [isDeliveryDetailOpen, setIsDeliveryDetailOpen] = useState(false);
  const [isFieldDetailOpen, setIsFieldDetailOpen] = useState(false);
  const [isFailureReportOpen, setIsFailureReportOpen] = useState(false);

  if (loading) {
    return (
      <MobileFrame>
        <div className="min-h-full flex flex-col items-center justify-center p-6 bg-brand-navy text-white text-center">
          <div className="w-12 h-12 border-4 border-brand-cyan border-t-transparent rounded-full animate-spin mb-4" />
          <h2 className="text-lg font-black tracking-tight">DeliverSync</h2>
          <p className="text-xs text-brand-cyan mt-1">"Delivering trust, every mile."</p>
        </div>
      </MobileFrame>
    );
  }

  // -------------------------------------------------------------
  // UNAUTHENTICATED FLOWS
  // -------------------------------------------------------------
  if (!user) {
    return (
      <MobileFrame>
        {unauthScreen === 'welcome' && (
          <WelcomeScreen
            onGetStarted={() => setUnauthScreen('onboarding')}
            onLogin={() => setUnauthScreen('login')}
            onCreateAccount={() => setUnauthScreen('register')}
          />
        )}

        {unauthScreen === 'onboarding' && (
          <OnboardingCarousel
            onComplete={() => setUnauthScreen('roleIntro')}
            onSkip={() => setUnauthScreen('roleIntro')}
          />
        )}

        {unauthScreen === 'roleIntro' && (
          <RoleIntroduction
            onSelectRole={(r) => {
              setSelectedRole(r);
              setUnauthScreen('login');
            }}
          />
        )}

        {unauthScreen === 'login' && (
          <LoginForm
            defaultRole={selectedRole}
            onSwitchToRegister={() => setUnauthScreen('register')}
            onSwitchToForgot={() => setUnauthScreen('forgot')}
          />
        )}

        {unauthScreen === 'register' && (
          <RegisterForm
            initialRole={selectedRole}
            onSwitchToLogin={() => setUnauthScreen('login')}
          />
        )}

        {unauthScreen === 'forgot' && (
          <ForgotPasswordForm
            onBackToLogin={() => setUnauthScreen('login')}
          />
        )}
      </MobileFrame>
    );
  }

  // -------------------------------------------------------------
  // AUTHENTICATED USER ROLE-BASED DASHBOARDS
  // -------------------------------------------------------------
  const renderRoleTabContent = () => {
    // 1. DISPATCHER ROLE
    if (user.role === 'DISPATCHER') {
      switch (activeTab) {
        case 'home':
        case 'deliveries':
          return (
            <DispatcherDashboard
              onCreateDelivery={() => setIsCreateDeliveryOpen(true)}
              onViewDelivery={(d) => {
                setSelectedDelivery(d);
                setIsDeliveryDetailOpen(true);
              }}
              onAssignDelivery={(d) => {
                setSelectedDelivery(d);
                setIsDeliveryDetailOpen(true);
              }}
            />
          );
        case 'executives':
        case 'notifications':
          return (
            <div className="p-4 animate-fade-in">
              <NotificationCenter isOpen={true} onClose={() => setActiveTab('home')} />
            </div>
          );
        case 'profile':
          return <UserProfile onLogout={logout} />;
        default:
          return <DispatcherDashboard onCreateDelivery={() => setIsCreateDeliveryOpen(true)} />;
      }
    }

    // 2. DELIVERY EXECUTIVE ROLE
    if (user.role === 'DELIVERY_EXECUTIVE') {
      switch (activeTab) {
        case 'home':
        case 'deliveries':
          return (
            <ExecutiveDashboard
              onOpenDelivery={(d) => {
                setSelectedDelivery(d);
                setIsFieldDetailOpen(true);
              }}
            />
          );
        case 'escalations':
          return <EscalationCenter />;
        case 'notifications':
          return (
            <div className="p-4 animate-fade-in">
              <NotificationCenter isOpen={true} onClose={() => setActiveTab('home')} />
            </div>
          );
        case 'profile':
          return <UserProfile onLogout={logout} />;
        default:
          return <ExecutiveDashboard onOpenDelivery={(d) => setSelectedDelivery(d)} />;
      }
    }

    // 3. OPERATIONS TEAM ROLE
    if (user.role === 'OPERATIONS') {
      switch (activeTab) {
        case 'home':
          return (
            <OperationsDashboard
              onOpenEscalation={() => setActiveTab('escalations')}
              onOpenAnalytics={() => setActiveTab('analytics')}
              onOpenMonitoring={() => setActiveTab('deliveries')}
            />
          );
        case 'deliveries':
          return (
            <DispatcherDashboard
              onCreateDelivery={() => setIsCreateDeliveryOpen(true)}
              onViewDelivery={(d) => {
                setSelectedDelivery(d);
                setIsDeliveryDetailOpen(true);
              }}
            />
          );
        case 'escalations':
          return <EscalationCenter />;
        case 'analytics':
          return <AnalyticsView />;
        case 'profile':
          return <UserProfile onLogout={logout} />;
        default:
          return <OperationsDashboard />;
      }
    }

    return <UserProfile onLogout={logout} />;
  };

  return (
    <MobileFrame user={user} activeTab={activeTab}>
      {/* Mobile Top Header */}
      <Header
        subtitle={`${user.fullName}`}
        onOpenNotifications={() => setIsNotificationsOpen(true)}
        onOpenProfile={() => setActiveTab('profile')}
      />

      {/* Main Tab Content */}
      <main className="flex-1">
        {renderRoleTabContent()}
      </main>

      {/* Mobile Bottom Navigation Bar */}
      <BottomNav activeTab={activeTab} setActiveTab={setActiveTab} />

      {/* Global Modals */}
      <NotificationCenter
        isOpen={isNotificationsOpen}
        onClose={() => setIsNotificationsOpen(false)}
      />

      <CreateDeliveryModal
        isOpen={isCreateDeliveryOpen}
        onClose={() => setIsCreateDeliveryOpen(false)}
        onSuccess={() => {
          setIsCreateDeliveryOpen(false);
        }}
      />

      <DeliveryDetailModal
        delivery={selectedDelivery}
        isOpen={isDeliveryDetailOpen}
        onClose={() => setIsDeliveryDetailOpen(false)}
        onReassign={(d) => {
          setIsDeliveryDetailOpen(false);
          setIsCreateDeliveryOpen(true);
        }}
        onCancel={async (id) => {
          setIsDeliveryDetailOpen(false);
        }}
      />

      <FieldDeliveryDetail
        delivery={selectedDelivery}
        isOpen={isFieldDetailOpen}
        onClose={() => setIsFieldDetailOpen(false)}
        onStartDelivery={async (id) => {
          setIsFieldDetailOpen(false);
        }}
        onMarkDelivered={async (id) => {
          setIsFieldDetailOpen(false);
        }}
        onMarkFailed={(d) => {
          setIsFieldDetailOpen(false);
          setIsFailureReportOpen(true);
        }}
      />

      <FailureReportModal
        delivery={selectedDelivery}
        isOpen={isFailureReportOpen}
        onClose={() => setIsFailureReportOpen(false)}
        onSuccess={() => {
          setIsFailureReportOpen(false);
        }}
      />
    </MobileFrame>
  );
}

export default App;
