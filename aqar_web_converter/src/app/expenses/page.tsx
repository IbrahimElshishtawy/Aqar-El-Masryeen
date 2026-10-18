'use client';

import React, { useState, useEffect } from 'react';
import {
  Receipt,
  Plus,
  Search,
  Filter,
  DollarSign,
  Building,
  Truck,
  FileText,
  X,
  CheckCircle2,
  AlertCircle,
  CreditCard,
  Layers,
  ArrowRight,
  TrendingDown,
} from 'lucide-react';
import AppShell from '@/components/layout/AppShell';
import MetricCard from '@/components/ui/MetricCard';
import {
  ExpenseRecord,
  ExpenseCategory,
  ExpenseCategoryLabels,
  MaterialExpenseEntry,
  MaterialCategory,
  MaterialCategoryLabels,
  SupplierPaymentRecord,
  PropertyProject,
  Partner,
} from '@/types';

export default function ExpensesPage() {
  const [activeTab, setActiveTab] = useState<'general' | 'materials' | 'suppliers'>('general');
  const [expenses, setExpenses] = useState<ExpenseRecord[]>([]);
  const [materialExpenses, setMaterialExpenses] = useState<MaterialExpenseEntry[]>([]);
  const [supplierPayments, setSupplierPayments] = useState<SupplierPaymentRecord[]>([]);
  const [projects, setProjects] = useState<PropertyProject[]>([]);
  const [partners, setPartners] = useState<Partner[]>([]);
  const [filter, setFilter] = useState<string>('all');
  const [search, setSearch] = useState('');
  const [userRole, setUserRole] = useState<string>('admin');

  // Modals
  const [showAddExpenseModal, setShowAddExpenseModal] = useState(false);
  const [showAddMaterialModal, setShowAddMaterialModal] = useState(false);
  const [showSupplierPaymentModal, setShowSupplierPaymentModal] = useState(false);
  const [alertMessage, setAlertMessage] = useState('');

  // General Expense Form
  const [title, setTitle] = useState('');
  const [amount, setAmount] = useState(50000);
  const [category, setCategory] = useState<ExpenseCategory>(ExpenseCategory.Construction);
  const [propertyId, setPropertyId] = useState('prop-1');
  const [paidByPartnerId, setPaidByPartnerId] = useState('partner-1');
  const [supplierName, setSupplierName] = useState('');
  const [receiptNumber, setReceiptNumber] = useState('');

  // Material Expense Form
  const [matCategory, setMatCategory] = useState<MaterialCategory>(MaterialCategory.Steel);
  const [matItemName, setMatItemName] = useState('حديد تسليح 16 مم');
  const [matQuantity, setMatQuantity] = useState(10);
  const [matUnitPrice, setMatUnitPrice] = useState(42000);
  const [matSupplierName, setMatSupplierName] = useState('شركة الأهرام لتجارة وتوزيع الحديد');
  const [matAmountPaid, setMatAmountPaid] = useState(300000);
  const [matDueDate, setMatDueDate] = useState('2026-06-30');

  // Supplier Payment Form
  const [supPaySupplierName, setSupPaySupplierName] = useState('شركة الأهرام لتجارة وتوزيع الحديد');
  const [supPayAmount, setSupPayAmount] = useState(100000);
  const [supPayPartnerId, setSupPayPartnerId] = useState('partner-1');
  const [supPayNotes, setSupPayNotes] = useState('سداد دفعة نقدية');

  const loadData = async () => {
    try {
      const res = await fetch('/api/accounting/data');
      if (res.ok) {
        const json = await res.json();
        setExpenses(json.data.expenses || []);
        setMaterialExpenses(json.data.materialExpenses || []);
        setSupplierPayments(json.data.supplierPayments || []);
        setProjects(json.data.projects || []);
        setPartners(json.data.partners || []);
        setUserRole(json.user?.role || 'admin');
        if (json.data.partners?.[0]?.id) {
          setPaidByPartnerId(json.data.partners[0].id);
          setSupPayPartnerId(json.data.partners[0].id);
        }
      }
    } catch (e) {
      console.error(e);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleAddExpense = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title || !amount) return;

    try {
      const res = await fetch('/api/accounting/data', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: 'create_expense',
          payload: {
            propertyId,
            category,
            title,
            amount: Number(amount),
            date: new Date().toISOString().split('T')[0],
            paidByPartnerId,
            supplierName,
            receiptNumber,
          },
        }),
      });

      if (!res.ok) {
        const err = await res.json();
        throw new Error(err.error || 'فشل تسجيل المصروف');
      }

      setAlertMessage('تم تسجيل المصروف في دفتر المشروعات بنجاح');
      setShowAddExpenseModal(false);
      setTitle('');
      setSupplierName('');
      setReceiptNumber('');
      await loadData();
      setTimeout(() => setAlertMessage(''), 4000);
    } catch (err: any) {
      alert(err.message);
    }
  };

  const handleAddMaterial = async (e: React.FormEvent) => {
    e.preventDefault();
    const totalPrice = Number(matQuantity) * Number(matUnitPrice);
    const amountPaid = Number(matAmountPaid);
    const amountRemaining = Math.max(0, totalPrice - amountPaid);

    try {
      const res = await fetch('/api/accounting/data', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: 'create_material_expense',
          payload: {
            propertyId,
            materialCategory: matCategory,
            itemName: matItemName,
            quantity: Number(matQuantity),
            unitPrice: Number(matUnitPrice),
            totalPrice,
            supplierName: matSupplierName,
            amountPaid,
            amountRemaining,
            date: new Date().toISOString().split('T')[0],
            dueDate: matDueDate,
            initialPaidByPartnerId: paidByPartnerId,
            initialPaidAmount: amountPaid,
          },
        }),
      });

      if (!res.ok) {
        const err = await res.json();
        throw new Error(err.error || 'فشل تسجيل التشوينة');
      }

      setAlertMessage('تم تسجيل فاتورة مواد البناء وتحديث مديونية المورد بنجاح');
      setShowAddMaterialModal(false);
      await loadData();
      setTimeout(() => setAlertMessage(''), 4000);
    } catch (err: any) {
      alert(err.message);
    }
  };

  const handleRecordSupplierPayment = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!supPayAmount) return;

    try {
      const res = await fetch('/api/accounting/data', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: 'record_supplier_payment',
          payload: {
            propertyId,
            supplierName: supPaySupplierName,
            amount: Number(supPayAmount),
            date: new Date().toISOString().split('T')[0],
            paidByPartnerId: supPayPartnerId,
            notes: supPayNotes,
          },
        }),
      });

      if (!res.ok) {
        const err = await res.json();
        throw new Error(err.error || 'فشل تسجيل الدفعة');
      }

      setAlertMessage('تم سداد الدفعة للمورد وخصمها من الرصيد المتبقي بنجاح');
      setShowSupplierPaymentModal(false);
      await loadData();
      setTimeout(() => setAlertMessage(''), 4000);
    } catch (err: any) {
      alert(err.message);
    }
  };

  const totalGeneralAmount = expenses.reduce((sum, item) => sum + item.amount, 0);
  const totalMaterialsPurchased = materialExpenses.reduce((sum, item) => sum + item.totalPrice, 0);
  const totalMaterialsRemaining = materialExpenses.reduce((sum, item) => sum + item.amountRemaining, 0);

  return (
    <AppShell
      title="دفتر المصروفات والتشوينات والتوريدات"
      subtitle="سجل التكاليف التنفيذية، فواتير الموردين، جداول التشوينات، وسدادات مواد البناء"
      actions={
        <div className="flex items-center gap-2">
          {userRole !== 'viewer' && (
            <>
              <button
                onClick={() => setShowSupplierPaymentModal(true)}
                className="px-3.5 py-2 rounded-xl bg-[#FFFFFF] border border-[#E2DFD8] text-[#242424] font-bold text-xs flex items-center gap-1.5 hover:bg-[#F4F4F2] transition"
              >
                <CreditCard className="w-4 h-4 text-[#A89F91]" />
                <span>سداد دفعة للمورد</span>
              </button>

              <button
                onClick={() => setShowAddMaterialModal(true)}
                className="px-3.5 py-2 rounded-xl bg-[#FFFFFF] border border-[#E2DFD8] text-[#242424] font-bold text-xs flex items-center gap-1.5 hover:bg-[#F4F4F2] transition"
              >
                <Truck className="w-4 h-4 text-[#A89F91]" />
                <span>توريد مواد بناء (تشوينة)</span>
              </button>

              <button
                onClick={() => setShowAddExpenseModal(true)}
                className="px-4 py-2 rounded-xl bg-[#242424] hover:bg-[#1A1A1A] text-white font-bold text-xs flex items-center gap-2 shadow-sm transition active:scale-95"
              >
                <Plus className="w-4 h-4 text-[#A89F91]" />
                <span>مصروف مشروع</span>
              </button>
            </>
          )}
        </div>
      }
    >
      <div className="space-y-6">
        {/* Success Alert */}
        {alertMessage && (
          <div className="p-4 rounded-2xl bg-emerald-50 border border-emerald-300 text-emerald-900 text-xs font-bold flex items-center gap-2 animate-in fade-in">
            <CheckCircle2 className="w-5 h-5 text-emerald-600" />
            <span>{alertMessage}</span>
          </div>
        )}

        {/* Metric Cards Row */}
        <section className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <MetricCard
            label="إجمالي المصروفات المنفذة"
            value={`${(totalGeneralAmount / 1000000).toFixed(2)}M ج.م`}
            icon={Receipt}
            subtext="إنشاءات وتراخيص ومقاولين"
          />

          <MetricCard
            label="إجمالي فواتير مواد البناء (تشوينات)"
            value={`${(totalMaterialsPurchased / 1000000).toFixed(2)}M ج.م`}
            icon={Truck}
            subtext="حديد تسليح، أسمنت، زلط ورمل"
          />

          <MetricCard
            label="المتبقي المستحق للموردين"
            value={`${(totalMaterialsRemaining / 1000000).toFixed(2)}M ج.م`}
            icon={Building}
            subtext="مديونيات آجلة تحت السداد"
          />
        </section>

        {/* Section Tabs */}
        <div className="flex border-b border-[#E2DFD8] gap-4 text-xs font-bold">
          <button
            onClick={() => setActiveTab('general')}
            className={`pb-3 px-2 border-b-2 transition ${
              activeTab === 'general'
                ? 'border-[#242424] text-[#242424]'
                : 'border-transparent text-[#777777] hover:text-[#242424]'
            }`}
          >
            المصروفات العامة للمشروع ({expenses.length})
          </button>

          <button
            onClick={() => setActiveTab('materials')}
            className={`pb-3 px-2 border-b-2 transition ${
              activeTab === 'materials'
                ? 'border-[#242424] text-[#242424]'
                : 'border-transparent text-[#777777] hover:text-[#242424]'
            }`}
          >
            توريدات وتشوينات مواد البناء ({materialExpenses.length})
          </button>

          <button
            onClick={() => setActiveTab('suppliers')}
            className={`pb-3 px-2 border-b-2 transition ${
              activeTab === 'suppliers'
                ? 'border-[#242424] text-[#242424]'
                : 'border-transparent text-[#777777] hover:text-[#242424]'
            }`}
          >
            سدادات الموردين المعتمدة ({supplierPayments.length})
          </button>
        </div>

        {/* Tab 1: General Expenses Table */}
        {activeTab === 'general' && (
          <section className="rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] p-6 shadow-sm space-y-4">
            <div className="overflow-x-auto">
              <table className="w-full text-right text-xs">
                <thead className="bg-[#F4F4F2] text-[#777777] border-b border-[#E2DFD8]">
                  <tr>
                    <th className="py-3 px-4 font-bold">بيان المصروف</th>
                    <th className="py-3 px-4 font-bold">البند المحاسبي</th>
                    <th className="py-3 px-4 font-bold">المبلغ</th>
                    <th className="py-3 px-4 font-bold">الشريك المسدد</th>
                    <th className="py-3 px-4 font-bold">المورد / الجهة</th>
                    <th className="py-3 px-4 font-bold">التاريخ</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E2DFD8]">
                  {expenses.map(exp => {
                    const partner = partners.find(p => p.id === exp.paidByPartnerId);
                    return (
                      <tr key={exp.id} className="hover:bg-[#FAF9F6] transition">
                        <td className="py-3.5 px-4 font-bold text-[#242424]">
                          {exp.title}
                        </td>
                        <td className="py-3.5 px-4">
                          <span className="bg-[#EBE8E1] text-[#242424] px-2 py-0.5 rounded-full text-[10px] font-bold">
                            {ExpenseCategoryLabels[exp.category] || exp.category}
                          </span>
                        </td>
                        <td className="py-3.5 px-4 font-bold text-[#242424]">
                          {exp.amount.toLocaleString()} ج.م
                        </td>
                        <td className="py-3.5 px-4 text-[#777777]">
                          {partner?.name || 'الشركة مباشرة'}
                        </td>
                        <td className="py-3.5 px-4 text-[#777777]">
                          {exp.supplierName || '-'}
                        </td>
                        <td className="py-3.5 px-4 text-[#777777]">
                          {exp.date}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </section>
        )}

        {/* Tab 2: Materials & Supplies */}
        {activeTab === 'materials' && (
          <section className="rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] p-6 shadow-sm space-y-4">
            <div className="overflow-x-auto">
              <table className="w-full text-right text-xs">
                <thead className="bg-[#F4F4F2] text-[#777777] border-b border-[#E2DFD8]">
                  <tr>
                    <th className="py-3 px-4 font-bold">المادة والتصنيف</th>
                    <th className="py-3 px-4 font-bold">الكمية</th>
                    <th className="py-3 px-4 font-bold">سعر الوحدة</th>
                    <th className="py-3 px-4 font-bold">إجمالي الفاتورة</th>
                    <th className="py-3 px-4 font-bold">المسدد</th>
                    <th className="py-3 px-4 font-bold">المتبقي</th>
                    <th className="py-3 px-4 font-bold">المورد</th>
                    <th className="py-3 px-4 font-bold">التاريخ</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E2DFD8]">
                  {materialExpenses.map(mat => (
                    <tr key={mat.id} className="hover:bg-[#FAF9F6] transition">
                      <td className="py-3.5 px-4">
                        <span className="font-bold text-[#242424] block">{mat.itemName}</span>
                        <span className="text-[10px] text-[#777777]">
                          {MaterialCategoryLabels[mat.materialCategory] || mat.materialCategory}
                        </span>
                      </td>
                      <td className="py-3.5 px-4 font-bold text-[#242424]">
                        {mat.quantity}
                      </td>
                      <td className="py-3.5 px-4 text-[#777777]">
                        {mat.unitPrice.toLocaleString()} ج.م
                      </td>
                      <td className="py-3.5 px-4 font-bold text-[#242424]">
                        {mat.totalPrice.toLocaleString()} ج.م
                      </td>
                      <td className="py-3.5 px-4 font-bold text-emerald-700">
                        {mat.amountPaid.toLocaleString()} ج.م
                      </td>
                      <td className="py-3.5 px-4 font-bold text-amber-700">
                        {mat.amountRemaining.toLocaleString()} ج.م
                      </td>
                      <td className="py-3.5 px-4 text-[#777777]">
                        {mat.supplierName}
                      </td>
                      <td className="py-3.5 px-4 text-[#777777]">
                        {mat.date}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>
        )}

        {/* Tab 3: Supplier Payments */}
        {activeTab === 'suppliers' && (
          <section className="rounded-3xl bg-[#FFFFFF] border border-[#E2DFD8] p-6 shadow-sm space-y-4">
            <div className="overflow-x-auto">
              <table className="w-full text-right text-xs">
                <thead className="bg-[#F4F4F2] text-[#777777] border-b border-[#E2DFD8]">
                  <tr>
                    <th className="py-3 px-4 font-bold">اسم المورد</th>
                    <th className="py-3 px-4 font-bold">قيمة الدفعة المسددة</th>
                    <th className="py-3 px-4 font-bold">الشريك القائم بالسداد</th>
                    <th className="py-3 px-4 font-bold">البيان والملاحظات</th>
                    <th className="py-3 px-4 font-bold">التاريخ</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E2DFD8]">
                  {supplierPayments.map(pay => {
                    const partner = partners.find(p => p.id === pay.paidByPartnerId);
                    return (
                      <tr key={pay.id} className="hover:bg-[#FAF9F6] transition">
                        <td className="py-3.5 px-4 font-bold text-[#242424]">
                          {pay.supplierName}
                        </td>
                        <td className="py-3.5 px-4 font-bold text-emerald-700 text-sm">
                          {pay.amount.toLocaleString()} ج.م
                        </td>
                        <td className="py-3.5 px-4 text-[#777777]">
                          {partner?.name || 'الشركة مباشرة'}
                        </td>
                        <td className="py-3.5 px-4 text-[#777777]">
                          {pay.notes || '-'}
                        </td>
                        <td className="py-3.5 px-4 text-[#777777]">
                          {pay.date}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </section>
        )}
      </div>

      {/* Add General Expense Modal */}
      {showAddExpenseModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-[#FFFFFF] border border-[#E2DFD8] rounded-3xl max-w-lg w-full p-6 shadow-2xl relative animate-in zoom-in-95 duration-200">
            <button
              onClick={() => setShowAddExpenseModal(false)}
              className="absolute left-6 top-6 p-1.5 rounded-xl text-[#777777] hover:bg-[#F4F4F2] transition"
            >
              <X className="w-5 h-5" />
            </button>

            <h3 className="font-editorial text-lg font-bold text-[#242424] mb-1">تسجيل مصروف مشروع جديد</h3>
            <p className="text-xs text-[#777777] mb-4">توثيق بنود الإنشاءات، التراخيص، والمقاولين</p>

            <form onSubmit={handleAddExpense} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-[#242424] mb-1">بيان المصروف</label>
                <input
                  type="text"
                  required
                  placeholder="مثال: صب خرسانة مسلحة لسقف الدور الأول"
                  value={title}
                  onChange={e => setTitle(e.target.value)}
                  className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none focus:border-[#242424]"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-[#242424] mb-1">المبلغ (ج.م)</label>
                  <input
                    type="number"
                    step={1000}
                    required
                    value={amount}
                    onChange={e => setAmount(Number(e.target.value))}
                    className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none focus:border-[#242424]"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-[#242424] mb-1">البند المحاسبي</label>
                  <select
                    value={category}
                    onChange={e => setCategory(e.target.value as ExpenseCategory)}
                    className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none"
                  >
                    {Object.entries(ExpenseCategoryLabels).map(([catKey, label]) => (
                      <option key={catKey} value={catKey}>
                        {label}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-[#242424] mb-1">الشريك المسدد</label>
                  <select
                    value={paidByPartnerId}
                    onChange={e => setPaidByPartnerId(e.target.value)}
                    className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none"
                  >
                    {partners.map(p => (
                      <option key={p.id} value={p.id}>
                        {p.name}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-bold text-[#242424] mb-1">المشروع</label>
                  <select
                    value={propertyId}
                    onChange={e => setPropertyId(e.target.value)}
                    className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none"
                  >
                    {projects.map(p => (
                      <option key={p.id} value={p.id}>
                        {p.name}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="pt-2 flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setShowAddExpenseModal(false)}
                  className="px-4 py-2 rounded-xl text-xs font-bold text-[#777777] hover:bg-[#F4F4F2] transition"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-5 py-2.5 rounded-xl bg-[#242424] hover:bg-[#1A1A1A] text-white font-bold text-xs transition"
                >
                  تسجيل المصروف
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Add Material Modal */}
      {showAddMaterialModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-[#FFFFFF] border border-[#E2DFD8] rounded-3xl max-w-lg w-full p-6 shadow-2xl relative animate-in zoom-in-95 duration-200">
            <button
              onClick={() => setShowAddMaterialModal(false)}
              className="absolute left-6 top-6 p-1.5 rounded-xl text-[#777777] hover:bg-[#F4F4F2] transition"
            >
              <X className="w-5 h-5" />
            </button>

            <h3 className="font-editorial text-lg font-bold text-[#242424] mb-1">تسجيل توريد مواد بناء (تشوينة)</h3>
            <p className="text-xs text-[#777777] mb-4">حديد تسليح، أسمنت، زلط، رمل، طوب وفواتير التشوين</p>

            <form onSubmit={handleAddMaterial} className="space-y-4">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-[#242424] mb-1">تصنيف المادة</label>
                  <select
                    value={matCategory}
                    onChange={e => setMatCategory(e.target.value as MaterialCategory)}
                    className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none"
                  >
                    {Object.entries(MaterialCategoryLabels).map(([catKey, label]) => (
                      <option key={catKey} value={catKey}>
                        {label}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-bold text-[#242424] mb-1">اسم الصنف</label>
                  <input
                    type="text"
                    required
                    value={matItemName}
                    onChange={e => setMatItemName(e.target.value)}
                    className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-[#242424] mb-1">الكمية (طن / متر / عدد)</label>
                  <input
                    type="number"
                    step={1}
                    required
                    value={matQuantity}
                    onChange={e => setMatQuantity(Number(e.target.value))}
                    className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-[#242424] mb-1">سعر الوحدة (ج.م)</label>
                  <input
                    type="number"
                    step={100}
                    required
                    value={matUnitPrice}
                    onChange={e => setMatUnitPrice(Number(e.target.value))}
                    className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-[#242424] mb-1">اسم المورد أو المصنع</label>
                <input
                  type="text"
                  required
                  value={matSupplierName}
                  onChange={e => setMatSupplierName(e.target.value)}
                  className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-[#242424] mb-1">المدفوع مقدماً (ج.م)</label>
                  <input
                    type="number"
                    step={1000}
                    value={matAmountPaid}
                    onChange={e => setMatAmountPaid(Number(e.target.value))}
                    className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-[#242424] mb-1">تاريخ الاستحقاق للمتبقي</label>
                  <input
                    type="date"
                    value={matDueDate}
                    onChange={e => setMatDueDate(e.target.value)}
                    className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none"
                  />
                </div>
              </div>

              <div className="pt-2 flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setShowAddMaterialModal(false)}
                  className="px-4 py-2 rounded-xl text-xs font-bold text-[#777777] hover:bg-[#F4F4F2] transition"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-5 py-2.5 rounded-xl bg-[#242424] hover:bg-[#1A1A1A] text-white font-bold text-xs transition"
                >
                  حفظ الفاتورة والتشوينة
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Supplier Payment Modal */}
      {showSupplierPaymentModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-[#FFFFFF] border border-[#E2DFD8] rounded-3xl max-w-lg w-full p-6 shadow-2xl relative animate-in zoom-in-95 duration-200">
            <button
              onClick={() => setShowSupplierPaymentModal(false)}
              className="absolute left-6 top-6 p-1.5 rounded-xl text-[#777777] hover:bg-[#F4F4F2] transition"
            >
              <X className="w-5 h-5" />
            </button>

            <h3 className="font-editorial text-lg font-bold text-[#242424] mb-1">سداد دفعة حساب للمورد</h3>
            <p className="text-xs text-[#777777] mb-4">خصم المبالغ المسددة من مديونيات فواتير التشوين</p>

            <form onSubmit={handleRecordSupplierPayment} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-[#242424] mb-1">اسم المورد</label>
                <input
                  type="text"
                  required
                  value={supPaySupplierName}
                  onChange={e => setSupPaySupplierName(e.target.value)}
                  className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-[#242424] mb-1">المبلغ المسدد (ج.م)</label>
                  <input
                    type="number"
                    step={1000}
                    required
                    value={supPayAmount}
                    onChange={e => setSupPayAmount(Number(e.target.value))}
                    className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-[#242424] mb-1">الشريك القائم بالسداد</label>
                  <select
                    value={supPayPartnerId}
                    onChange={e => setSupPayPartnerId(e.target.value)}
                    className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none"
                  >
                    {partners.map(p => (
                      <option key={p.id} value={p.id}>
                        {p.name}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-[#242424] mb-1">الملاحظات</label>
                <input
                  type="text"
                  value={supPayNotes}
                  onChange={e => setSupPayNotes(e.target.value)}
                  className="w-full px-4 py-2 bg-[#F4F4F2] border border-[#E2DFD8] rounded-xl text-xs text-[#242424] focus:outline-none"
                />
              </div>

              <div className="pt-2 flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setShowSupplierPaymentModal(false)}
                  className="px-4 py-2 rounded-xl text-xs font-bold text-[#777777] hover:bg-[#F4F4F2] transition"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="px-5 py-2.5 rounded-xl bg-[#242424] hover:bg-[#1A1A1A] text-white font-bold text-xs transition"
                >
                  اعتماد السداد
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </AppShell>
  );
}
