'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import {
  Building2,
  LayoutDashboard,
  Calendar,
  Receipt,
  Users,
  BarChart3,
  Bell,
  ArrowRightLeft,
  Menu,
  X,
  ShieldCheck,
  Globe,
  Lock,
  ChevronLeft,
  TrendingUp,
  LogOut,
  UserCheck,
} from 'lucide-react';
import { AuthUserSession } from '@/types';

interface AppShellProps {
  title: string;
  subtitle?: string;
  children: React.ReactNode;
  actions?: React.ReactNode;
}

export function AppShell({ title, subtitle, children, actions }: AppShellProps) {
  const pathname = usePathname();
  const router = useRouter();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [currentUser, setCurrentUser] = useState<AuthUserSession | null>(null);

  useEffect(() => {
    fetch('/api/auth/me')
      .then(res => (res.ok ? res.json() : null))
      .then(data => {
        if (data?.authenticated && data?.user) {
          setCurrentUser(data.user);
        }
      })
      .catch(() => {});
  }, []);

  const handleLogout = async () => {
    try {
      await fetch('/api/auth/logout', { method: 'POST' });
      router.push('/accounting/login');
      router.refresh();
    } catch (e) {
      router.push('/accounting/login');
    }
  };

  const navigation = [
    { name: 'لوحة المؤشرات العامة', href: '/dashboard', icon: LayoutDashboard },
    { name: 'المشروعات والوحدات', href: '/properties', icon: Building2 },
    { name: 'رصد وتحديث أسعار العقارات', href: '/price-monitoring', icon: TrendingUp, badge: 'رصد الأسعار' },
    { name: 'برنامج الأقساط والتحصيل', href: '/installments', icon: Calendar },
    { name: 'دفتر المصروفات والتشوينات', href: '/expenses', icon: Receipt },
    { name: 'تسويات وحصص الشركاء', href: '/partners', icon: Users },
    { name: 'التقارير المحاسبية والمالية', href: '/reports', icon: BarChart3 },
    { name: 'استوديو التحويل (Flutter)', href: '/converter', icon: ArrowRightLeft, badge: 'أداة التحويل' },
  ];

  const getRoleBadge = (role?: string) => {
    switch (role) {
      case 'admin':
        return { label: 'مدير المنظومة (Admin)', color: 'bg-amber-500/20 text-amber-300 border-amber-500/30' };
      case 'accountant':
        return { label: 'رئيس حسابات (Accountant)', color: 'bg-blue-500/20 text-blue-300 border-blue-500/30' };
      case 'partner':
        return { label: 'شريك استثماري (Partner)', color: 'bg-emerald-500/20 text-emerald-300 border-emerald-500/30' };
      case 'viewer':
        return { label: 'مراقب عام (Viewer)', color: 'bg-purple-500/20 text-purple-300 border-purple-500/30' };
      default:
        return { label: 'مستخدم معتمد', color: 'bg-[#A89F91]/20 text-[#A89F91] border-[#A89F91]/30' };
    }
  };

  const roleInfo = getRoleBadge(currentUser?.role);

  return (
    <div className="min-h-screen bg-[#F4F4F2] text-[#242424] flex flex-col md:flex-row font-sans selection:bg-[#A89F91] selection:text-white" dir="rtl">
      {/* Sidebar Desktop: Architectural Prestige Dark */}
      <aside className="hidden md:flex w-72 flex-col bg-[#242424] border-l border-[#333333] p-5 shrink-0 sticky top-0 h-screen overflow-y-auto text-[#F4F4F2]">
        {/* Brand Header */}
        <div className="flex items-center gap-3 pb-6 border-b border-[#333333]">
          <div className="w-11 h-11 rounded-xl bg-[#1A1A1A] border border-[#A89F91]/40 flex items-center justify-center text-white shadow-md">
            <Building2 className="w-6 h-6 text-[#A89F91]" />
          </div>
          <div>
            <h2 className="font-editorial text-lg font-bold tracking-tight text-white">عقار المصريين</h2>
            <div className="flex items-center gap-1.5 mt-0.5">
              <span className="w-1.5 h-1.5 rounded-full bg-[#A89F91]" />
              <p className="text-[10px] text-[#A89F91] font-bold tracking-wider uppercase">بوابة الإدارة والمحاسبة</p>
            </div>
          </div>
        </div>

        {/* Quick Link to Public Home Page */}
        <div className="my-3">
          <Link
            href="/"
            className="w-full p-2.5 rounded-2xl bg-[#1A1A1A] hover:bg-[#111111] border border-[#333333] flex items-center justify-between transition group text-xs font-semibold text-[#A89F91] hover:text-white"
          >
            <div className="flex items-center gap-2">
              <Globe className="w-4 h-4 text-[#A89F91]" />
              <span>الواجهة الرئيسية للموقع</span>
            </div>
            <ChevronLeft className="w-4 h-4 text-[#777777] group-hover:text-white transition" />
          </Link>
        </div>

        {/* Active Role Tag */}
        <div className="mb-3 p-3 rounded-2xl bg-[#1E1E1E] border border-[#333333] flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
            <div className="text-right">
              <p className="text-xs font-bold text-white truncate max-w-[150px]">
                {currentUser?.fullName || 'جلسة محاسبية نشطة'}
              </p>
              <span className={`inline-block text-[9px] px-1.5 py-0.5 rounded-full border mt-0.5 font-bold ${roleInfo.color}`}>
                {roleInfo.label}
              </span>
            </div>
          </div>
          <ShieldCheck className="w-4 h-4 text-[#A89F91]" />
        </div>

        {/* Nav Links */}
        <nav className="flex-1 space-y-1 my-1">
          {navigation.map(item => {
            const isActive = pathname === item.href || (item.href !== '/dashboard' && pathname.startsWith(item.href));
            const Icon = item.icon;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`flex items-center justify-between px-3.5 py-2.5 rounded-2xl text-xs font-bold transition duration-200 ${
                  isActive
                    ? 'bg-[#A89F91] text-[#242424] shadow-md'
                    : 'text-[#E2DFD8] hover:bg-[#1E1E1E] hover:text-white'
                }`}
              >
                <div className="flex items-center gap-3">
                  <Icon className={`w-4 h-4 ${isActive ? 'text-[#242424]' : 'text-[#A89F91]'}`} />
                  <span>{item.name}</span>
                </div>
                {item.badge && (
                  <span className={`text-[10px] px-2 py-0.5 rounded-full border font-semibold ${
                    isActive
                      ? 'bg-[#242424] text-white border-[#242424]'
                      : 'bg-[#1A1A1A] text-[#A89F91] border-[#333333]'
                  }`}>
                    {item.badge}
                  </span>
                )}
              </Link>
            );
          })}
        </nav>

        {/* User Card with Logout */}
        <div className="pt-3 border-t border-[#333333] flex items-center justify-between">
          <div className="flex items-center gap-2.5 truncate">
            <div className="w-8 h-8 rounded-xl bg-[#A89F91]/20 text-[#A89F91] flex items-center justify-center font-bold text-xs border border-[#A89F91]/30 shrink-0">
              <UserCheck className="w-4 h-4" />
            </div>
            <div className="truncate text-right">
              <p className="text-[11px] font-bold text-white truncate">{currentUser?.email || 'admin@elmasryeen.com'}</p>
              <p className="text-[9px] text-[#777777]">تسجيل خروج آمن</p>
            </div>
          </div>
          <button
            onClick={handleLogout}
            title="تسجيل الخروج"
            className="p-2 rounded-xl bg-[#1A1A1A] hover:bg-rose-950 text-rose-300 border border-[#333333] hover:border-rose-800 transition"
          >
            <LogOut className="w-3.5 h-3.5" />
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0 bg-[#F4F4F2]">
        {/* Top Navbar */}
        <header className="h-18 border-b border-[#E2DFD8] bg-[#FFFFFF]/90 backdrop-blur-md px-6 flex items-center justify-between sticky top-0 z-40">
          <div className="flex items-center gap-4">
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="md:hidden p-2 rounded-xl bg-[#EBE8E1] text-[#242424]"
            >
              {mobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </button>

            <div>
              <h1 className="font-editorial text-lg md:text-xl font-black text-[#242424] tracking-tight">{title}</h1>
              {subtitle && <p className="text-xs text-[#777777] mt-0.5">{subtitle}</p>}
            </div>
          </div>

          <div className="flex items-center gap-3">
            {actions}

            <Link
              href="/"
              className="hidden sm:inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-[#EBE8E1] hover:bg-[#E2DFD8] border border-[#E2DFD8] text-[#242424] text-xs font-bold transition"
            >
              <Globe className="w-3.5 h-3.5 text-[#777777]" />
              <span>الموقع العام</span>
            </Link>

            <button
              onClick={handleLogout}
              className="p-2.5 rounded-xl border border-[#E2DFD8] bg-[#F4F4F2] text-rose-600 hover:bg-rose-50 transition"
              title="تسجيل الخروج"
            >
              <LogOut className="w-4 h-4" />
            </button>
          </div>
        </header>

        {/* Mobile Navigation Drawer */}
        {mobileMenuOpen && (
          <div className="md:hidden bg-[#242424] text-[#F4F4F2] border-b border-[#333333] p-4 space-y-2">
            <div className="p-3 rounded-xl bg-[#1E1E1E] border border-[#333333] flex items-center justify-between text-xs mb-2">
              <div>
                <span className="font-bold text-white block">{currentUser?.fullName}</span>
                <span className="text-[10px] text-[#A89F91]">{roleInfo.label}</span>
              </div>
              <button
                onClick={handleLogout}
                className="px-2.5 py-1.5 bg-rose-950 text-rose-200 rounded-lg text-xs font-bold flex items-center gap-1"
              >
                <LogOut className="w-3 h-3" />
                <span>خروج</span>
              </button>
            </div>

            <Link
              href="/"
              onClick={() => setMobileMenuOpen(false)}
              className="flex items-center justify-between p-3 rounded-xl bg-[#1A1A1A] text-[#A89F91] text-xs font-bold mb-2"
            >
              <div className="flex items-center gap-2">
                <Globe className="w-4 h-4" />
                <span>العودة للواجهة الرئيسية</span>
              </div>
            </Link>

            {navigation.map(item => {
              const isActive = pathname === item.href;
              const Icon = item.icon;
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  onClick={() => setMobileMenuOpen(false)}
                  className={`flex items-center justify-between p-3 rounded-xl text-xs font-bold ${
                    isActive ? 'bg-[#A89F91] text-[#242424]' : 'text-[#E2DFD8] hover:bg-[#1E1E1E]'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <Icon className="w-4 h-4" />
                    <span>{item.name}</span>
                  </div>
                  {item.badge && <span className="text-[10px] text-[#A89F91]">{item.badge}</span>}
                </Link>
              );
            })}
          </div>
        )}

        {/* Page Content Body */}
        <main className="flex-1 p-6 md:p-8 overflow-y-auto">
          {children}
        </main>
      </div>
    </div>
  );
}

export default AppShell;
