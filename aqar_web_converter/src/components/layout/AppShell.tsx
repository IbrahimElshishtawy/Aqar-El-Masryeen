'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  Building2,
  LayoutDashboard,
  Calendar,
  Receipt,
  Users,
  BarChart3,
  Bell,
  Search,
  Plus,
  ArrowRightLeft,
  ChevronDown,
  Menu,
  X,
  ShieldCheck,
  CheckCircle2,
  DollarSign
} from 'lucide-react';

interface AppShellProps {
  title: string;
  subtitle?: string;
  children: React.ReactNode;
  actions?: React.ReactNode;
}

export function AppShell({ title, subtitle, children, actions }: AppShellProps) {
  const pathname = usePathname();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const navigation = [
    { name: 'الرئيسية (Dashboard)', href: '/dashboard', icon: LayoutDashboard },
    { name: 'المشروعات والعقارات', href: '/properties', icon: Building2 },
    { name: 'الأقساط والتحصيل', href: '/installments', icon: Calendar },
    { name: 'المصروفات والتشوينات', href: '/expenses', icon: Receipt },
    { name: 'الشركاء والتسويات', href: '/partners', icon: Users },
    { name: 'التقارير المالية', href: '/reports', icon: BarChart3 },
    { name: 'استوديو التحويل (Flutter)', href: '/converter', icon: ArrowRightLeft, badge: 'أداة التحويل' },
  ];

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col md:flex-row font-sans" dir="rtl">
      {/* Sidebar Desktop */}
      <aside className="hidden md:flex w-72 flex-col bg-slate-900/90 border-l border-slate-800/80 p-5 shrink-0 sticky top-0 h-screen overflow-y-auto">
        {/* Brand Header */}
        <div className="flex items-center gap-3 pb-6 border-b border-slate-800">
          <div className="w-11 h-11 rounded-2xl bg-gradient-to-tr from-blue-600 via-indigo-600 to-sky-400 flex items-center justify-center text-white shadow-lg shadow-blue-500/25">
            <Building2 className="w-6 h-6" />
          </div>
          <div>
            <h2 className="text-lg font-black tracking-tight text-white">عقار المصريين</h2>
            <p className="text-[11px] text-blue-400 font-semibold">إدارة العقارات والأقساط الذكية</p>
          </div>
        </div>

        {/* Workspace Tag */}
        <div className="my-4 p-3 rounded-2xl bg-slate-800/60 border border-slate-700/50 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse" />
            <div className="text-right">
              <p className="text-xs font-bold text-white">مساحة عمل: الإدارة العامة</p>
              <p className="text-[10px] text-slate-400">مزامنة سحابية نشطة</p>
            </div>
          </div>
          <ShieldCheck className="w-4 h-4 text-emerald-400" />
        </div>

        {/* Nav Links */}
        <nav className="flex-1 space-y-1.5 my-2">
          {navigation.map(item => {
            const isActive = pathname === item.href || (item.href !== '/dashboard' && pathname.startsWith(item.href));
            const Icon = item.icon;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`flex items-center justify-between px-3.5 py-2.5 rounded-2xl text-xs font-bold transition duration-200 ${
                  isActive
                    ? 'bg-blue-600 text-white shadow-lg shadow-blue-600/25'
                    : 'text-slate-300 hover:bg-slate-800/80 hover:text-white'
                }`}
              >
                <div className="flex items-center gap-3">
                  <Icon className={`w-4 h-4 ${isActive ? 'text-white' : 'text-slate-400'}`} />
                  <span>{item.name}</span>
                </div>
                {item.badge && (
                  <span className="text-[10px] px-2 py-0.5 rounded-full bg-indigo-500/20 text-indigo-300 border border-indigo-500/30 font-semibold">
                    {item.badge}
                  </span>
                )}
              </Link>
            );
          })}
        </nav>

        {/* User Card */}
        <div className="pt-4 border-t border-slate-800 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-blue-600/20 text-blue-400 flex items-center justify-center font-bold text-xs border border-blue-500/30">
              م
            </div>
            <div>
              <p className="text-xs font-bold text-white">المدير العام</p>
              <p className="text-[10px] text-slate-400">admin@elmasryeen.com</p>
            </div>
          </div>
        </div>
      </aside>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0">
        {/* Top Navbar */}
        <header className="h-18 border-b border-slate-800 bg-slate-900/60 backdrop-blur-md px-6 flex items-center justify-between sticky top-0 z-40">
          <div className="flex items-center gap-4">
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="md:hidden p-2 rounded-xl bg-slate-800 text-slate-300"
            >
              {mobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </button>

            <div>
              <h1 className="text-lg md:text-xl font-extrabold text-white tracking-tight">{title}</h1>
              {subtitle && <p className="text-xs text-slate-400 mt-0.5">{subtitle}</p>}
            </div>
          </div>

          <div className="flex items-center gap-3">
            {actions}

            <Link
              href="/notifications"
              className="p-2.5 rounded-xl border border-slate-800 bg-slate-900/80 text-slate-300 hover:text-white hover:bg-slate-800 transition relative"
              title="التنبيهات"
            >
              <Bell className="w-4 h-4" />
              <span className="w-2 h-2 rounded-full bg-blue-500 absolute top-2 right-2 ring-2 ring-slate-900" />
            </Link>

            <Link
              href="/converter"
              className="hidden sm:inline-flex items-center gap-1.5 px-3 py-2 rounded-xl bg-slate-800 border border-slate-700 text-slate-200 text-xs font-semibold hover:bg-slate-700 transition"
            >
              <ArrowRightLeft className="w-3.5 h-3.5 text-blue-400" />
              <span>استوديو التحويل</span>
            </Link>
          </div>
        </header>

        {/* Mobile Navigation Drawer */}
        {mobileMenuOpen && (
          <div className="md:hidden bg-slate-900 border-b border-slate-800 p-4 space-y-2">
            {navigation.map(item => {
              const isActive = pathname === item.href;
              const Icon = item.icon;
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  onClick={() => setMobileMenuOpen(false)}
                  className={`flex items-center justify-between p-3 rounded-xl text-xs font-bold ${
                    isActive ? 'bg-blue-600 text-white' : 'text-slate-300 hover:bg-slate-800'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <Icon className="w-4 h-4" />
                    <span>{item.name}</span>
                  </div>
                  {item.badge && <span className="text-[10px] text-indigo-300">{item.badge}</span>}
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
