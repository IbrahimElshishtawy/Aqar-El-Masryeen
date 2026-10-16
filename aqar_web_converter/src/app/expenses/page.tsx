'use client';

import React, { useState } from 'react';
import {
  Receipt,
  Plus,
  Search,
  Filter,
  DollarSign,
  Building,
  Truck,
  FileText,
  X
} from 'lucide-react';
import AppShell from '@/components/layout/AppShell';
import MetricCard from '@/components/ui/MetricCard';
import { initialExpenses, initialProjects, initialPartners } from '@/services/store';
import { ExpenseRecord, ExpenseCategory, ExpenseCategoryLabels } from '@/types';

export default function ExpensesPage() {
  const [expenses, setExpenses] = useState<ExpenseRecord[]>(initialExpenses);
  const [filter, setFilter] = useState<string>('all');
  const [search, setSearch] = useState('');
  const [showAddModal, setShowAddModal] = useState(false);

  // Form state
  const [title, setTitle] = useState('');
  const [amount, setAmount] = useState(50000);
  const [category, setCategory] = useState<ExpenseCategory>(ExpenseCategory.Materials);
  const [propertyId, setPropertyId] = useState('prop-1');
  const [paidByPartnerId, setPaidByPartnerId] = useState('partner-1');
  const [supplierName, setSupplierName] = useState('');
  const [receiptNumber, setReceiptNumber] = useState('');

  const handleAddExpense = (e: React.FormEvent) => {
    e.preventDefault();
    const newExp: ExpenseRecord = {
      id: `exp-${Date.now()}`,
      propertyId,
      category,
      title,
      amount: Number(amount),
      date: new Date().toISOString().split('T')[0],
      paidByPartnerId,
      supplierName,
      receiptNumber,
    };

    setExpenses([newExp, ...expenses]);
    setShowAddModal(false);
    setTitle('');
    setSupplierName('');
    setReceiptNumber('');
  };

  const filtered = expenses.filter(e => {
    const matchesFilter = filter === 'all' || e.category === filter;
    const matchesSearch = e.title.includes(search) || (e.supplierName || '').includes(search);
    return matchesFilter && matchesSearch;
  });

  const totalAmount = expenses.reduce((sum, item) => sum + item.amount, 0);
  const materialsAmount = expenses.filter(e => e.category === ExpenseCategory.Materials).reduce((sum, item) => sum + item.amount, 0);
  const constructionAmount = expenses.filter(e => e.category === ExpenseCategory.Construction).reduce((sum, item) => sum + item.amount, 0);

  return (
    <AppShell
      title="المصروفات والتشوينات ومواد البناء"
      subtitle="سجل التكاليف التنفيذية وفواتير الموردين ومصروفات المشروعات اليومية"
      actions={
        <button
          onClick={() => setShowAddModal(true)}
          className="px-4 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-500 text-white font-bold text-xs flex items-center gap-2 shadow-lg shadow-blue-600/25 transition active:scale-95"
        >
          <Plus className="w-4 h-4" />
          <span>تسجيل مصروف جديد</span>
        </button>
      }
    >
      <div className="space-y-6">
        {/* Metric Cards Row */}
        <section className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <MetricCard
            label="إجمالي المصروفات المنفذة"
            value={`${(totalAmount / 1000).toLocaleString()} ألف ج.م`}
            icon={Receipt}
            color="amber"
            subtext="كل بنود الإنفاق المسجلة"
          />

          <MetricCard
            label="تكلفة مواد البناء (تشوينات)"
            value={`${(materialsAmount / 1000).toLocaleString()} ألف ج.م`}
            icon={Truck}
            color="blue"
            subtext="حديد تسليح، أسمنت، زلط ورمل"
          />

          <MetricCard
            label="أعمال الإنشاء والمقاولين"
            value={`${(constructionAmount / 1000).toLocaleString()} ألف ج.م`}
            icon={Building}
            color="purple"
            subtext="صب خرسانات، مصنعيات وعمالة"
          />
        </section>

        {/* Filter and Search Bar */}
        <div className="flex flex-col sm:flex-row items-center justify-between gap-4 p-4 rounded-2xl bg-slate-900/60 border border-slate-800">
          <div className="relative w-full sm:w-80">
            <Search className="w-4 h-4 text-slate-500 absolute right-3 top-3" />
            <input
              type="text"
              placeholder="بحث في المصروفات أو اسم المورد..."
              value={search}
              onChange={e => setSearch(e.target.value)}
              className="w-full pl-3 pr-9 py-2 bg-slate-800/80 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-blue-500"
            />
          </div>

          <div className="flex items-center gap-2 overflow-x-auto w-full sm:w-auto pb-1 sm:pb-0">
            {[
              { id: 'all', label: 'كافة المصروفات' },
              { id: ExpenseCategory.Materials, label: 'مواد بناء' },
              { id: ExpenseCategory.Construction, label: 'إنشاءات' },
              { id: ExpenseCategory.Permits, label: 'تراخيص' },
            ].map(tab => (
              <button
                key={tab.id}
                onClick={() => setFilter(tab.id)}
                className={`px-3 py-1.5 rounded-xl text-xs font-semibold shrink-0 transition ${
                  filter === tab.id
                    ? 'bg-blue-600 text-white'
                    : 'bg-slate-800 text-slate-400 hover:text-white'
                }`}
              >
                {tab.label}
              </button>
            ))}
          </div>
        </div>

        {/* Expenses Table */}
        <div className="rounded-3xl bg-slate-900/80 border border-slate-800 p-6 shadow-lg space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-base font-bold text-white">دفتر المصروفات والتشوينات</h3>
            <span className="text-xs text-slate-400">{filtered.length} بند مسجل</span>
          </div>

          <div className="overflow-x-auto rounded-2xl border border-slate-800">
            <table className="w-full text-right text-xs">
              <thead className="bg-slate-800/80 text-slate-300 font-bold border-b border-slate-700">
                <tr>
                  <th className="p-3.5">بيان المصروف</th>
                  <th className="p-3.5">التصنيف</th>
                  <th className="p-3.5">المبلغ</th>
                  <th className="p-3.5">التاريخ</th>
                  <th className="p-3.5">المورد / المقاول</th>
                  <th className="p-3.5">الشريك الدافع</th>
                  <th className="p-3.5">رقم الإيصال</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800 text-slate-200">
                {filtered.map(exp => {
                  const partner = initialPartners.find(p => p.id === exp.paidByPartnerId);
                  return (
                    <tr key={exp.id} className="hover:bg-slate-800/40 transition">
                      <td className="p-3.5 font-bold text-white">{exp.title}</td>
                      <td className="p-3.5">
                        <span className="px-2 py-0.5 rounded-lg bg-slate-800 text-slate-300 border border-slate-700 text-[11px]">
                          {ExpenseCategoryLabels[exp.category] || exp.category}
                        </span>
                      </td>
                      <td className="p-3.5 font-mono font-bold text-amber-400">
                        {exp.amount.toLocaleString()} ج.م
                      </td>
                      <td className="p-3.5 font-mono text-slate-400">{exp.date}</td>
                      <td className="p-3.5 text-slate-300">{exp.supplierName || '—'}</td>
                      <td className="p-3.5 font-medium text-purple-300">{partner?.name || 'الشركة'}</td>
                      <td className="p-3.5 font-mono text-slate-400">{exp.receiptNumber || '—'}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>

        {/* Add Expense Modal */}
        {showAddModal && (
          <div className="fixed inset-0 bg-black/75 backdrop-blur-sm z-50 flex items-center justify-center p-4">
            <div className="w-full max-w-lg rounded-3xl bg-slate-900 border border-slate-800 p-6 space-y-4">
              <div className="flex items-center justify-between pb-3 border-b border-slate-800">
                <h3 className="text-base font-bold text-white flex items-center gap-2">
                  <Receipt className="w-5 h-5 text-amber-400" />
                  تسجيل مصروف أو فاتورة جديدة
                </h3>
                <button onClick={() => setShowAddModal(false)} className="text-slate-400 hover:text-white">
                  <X className="w-5 h-5" />
                </button>
              </div>

              <form onSubmit={handleAddExpense} className="space-y-4 text-xs">
                <div>
                  <label className="block text-slate-300 font-bold mb-1">بيان المصروف</label>
                  <input
                    type="text"
                    required
                    placeholder="مثال: توريد 30 طن أسمنت"
                    value={title}
                    onChange={e => setTitle(e.target.value)}
                    className="w-full px-3 py-2 rounded-xl bg-slate-800 border border-slate-700 text-white focus:outline-none focus:border-blue-500"
                  />
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-slate-300 font-bold mb-1">المبلغ (ج.م)</label>
                    <input
                      type="number"
                      required
                      value={amount}
                      onChange={e => setAmount(Number(e.target.value))}
                      className="w-full px-3 py-2 rounded-xl bg-slate-800 border border-slate-700 text-white focus:outline-none focus:border-blue-500 font-mono"
                    />
                  </div>
                  <div>
                    <label className="block text-slate-300 font-bold mb-1">التصنيف</label>
                    <select
                      value={category}
                      onChange={e => setCategory(e.target.value as ExpenseCategory)}
                      className="w-full px-3 py-2 rounded-xl bg-slate-800 border border-slate-700 text-white focus:outline-none focus:border-blue-500"
                    >
                      <option value={ExpenseCategory.Materials}>مواد بناء (تشوينات)</option>
                      <option value={ExpenseCategory.Construction}>إنشاءات ومقاولات</option>
                      <option value={ExpenseCategory.Permits}>تراخيص ورسوم</option>
                      <option value={ExpenseCategory.Legal}>أتعاب قانونية</option>
                      <option value={ExpenseCategory.Other}>أخرى</option>
                    </select>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-slate-300 font-bold mb-1">المشروع التابع له</label>
                    <select
                      value={propertyId}
                      onChange={e => setPropertyId(e.target.value)}
                      className="w-full px-3 py-2 rounded-xl bg-slate-800 border border-slate-700 text-white focus:outline-none focus:border-blue-500"
                    >
                      {initialProjects.map(p => (
                        <option key={p.id} value={p.id}>{p.name}</option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="block text-slate-300 font-bold mb-1">الشريك الدافع</label>
                    <select
                      value={paidByPartnerId}
                      onChange={e => setPaidByPartnerId(e.target.value)}
                      className="w-full px-3 py-2 rounded-xl bg-slate-800 border border-slate-700 text-white focus:outline-none focus:border-blue-500"
                    >
                      {initialPartners.map(p => (
                        <option key={p.id} value={p.id}>{p.name}</option>
                      ))}
                    </select>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-slate-300 font-bold mb-1">اسم المورد / الشركة</label>
                    <input
                      type="text"
                      placeholder="اسم المورد"
                      value={supplierName}
                      onChange={e => setSupplierName(e.target.value)}
                      className="w-full px-3 py-2 rounded-xl bg-slate-800 border border-slate-700 text-white focus:outline-none focus:border-blue-500"
                    />
                  </div>
                  <div>
                    <label className="block text-slate-300 font-bold mb-1">رقم الفاتورة / الإيصال</label>
                    <input
                      type="text"
                      placeholder="REC-..."
                      value={receiptNumber}
                      onChange={e => setReceiptNumber(e.target.value)}
                      className="w-full px-3 py-2 rounded-xl bg-slate-800 border border-slate-700 text-white focus:outline-none focus:border-blue-500 font-mono"
                    />
                  </div>
                </div>

                <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-800">
                  <button
                    type="button"
                    onClick={() => setShowAddModal(false)}
                    className="px-4 py-2 rounded-xl text-slate-400 hover:text-white"
                  >
                    إلغاء
                  </button>
                  <button
                    type="submit"
                    className="px-5 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-500 text-white font-bold transition"
                  >
                    حفظ المصروف
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </div>
    </AppShell>
  );
}
