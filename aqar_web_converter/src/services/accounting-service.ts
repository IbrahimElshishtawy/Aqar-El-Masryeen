import {
  PropertyProject,
  UnitSale,
  Installment,
  ExpenseRecord,
  Partner,
  MaterialExpenseEntry,
  SupplierPaymentRecord,
  PartnerLedgerEntry,
  PaymentRecord,
  PriceHistoryRecord,
  ActivityLogEntry,
  AuthUserSession,
  PartnerLedgerEntryType,
  InstallmentStatus,
  PropertyStatus,
  UnitStatus,
} from '@/types';
import {
  initialProjects,
  initialUnits,
  initialInstallments,
  initialExpenses,
  initialPartners,
} from './store';
import { AccountingEngine, CompanyReconciliation } from '../lib/accounting/engine';
import { PriceMonitoringEngine, PriceMetric } from '../lib/price-monitoring/engine';

// Initial seed material expenses matching Flutter Firestore
const initialMaterialExpenses: MaterialExpenseEntry[] = [
  {
    id: 'mat-1',
    propertyId: 'prop-1',
    materialCategory: 'steel' as any,
    itemName: 'حديد تسليح 16 مم - عز الدخيلة',
    quantity: 35,
    unitPrice: 42000,
    totalPrice: 1470000,
    supplierName: 'شركة الأهرام لتجارة وتوزيع الحديد',
    amountPaid: 1000000,
    amountRemaining: 470000,
    date: '2025-03-25',
    dueDate: '2026-05-15',
    initialPaidByPartnerId: 'partner-1',
    initialPaidAmount: 1000000,
    notes: 'توريد الدفعة الأولى من الهيكل الخرساني',
    createdAt: '2025-03-25T10:00:00Z',
  },
  {
    id: 'mat-2',
    propertyId: 'prop-1',
    materialCategory: 'cement' as any,
    itemName: 'أسمنت بورتلاندي مسلح - السويس',
    quantity: 60,
    unitPrice: 2800,
    totalPrice: 168000,
    supplierName: 'مصنع أسمنت السويس',
    amountPaid: 168000,
    amountRemaining: 0,
    date: '2025-04-05',
    initialPaidByPartnerId: 'partner-2',
    initialPaidAmount: 168000,
    notes: 'مسدد بالكامل عند الاستلام',
    createdAt: '2025-04-05T12:00:00Z',
  },
];

const initialSupplierPayments: SupplierPaymentRecord[] = [
  {
    id: 'sup-pay-1',
    propertyId: 'prop-1',
    supplierName: 'شركة الأهرام لتجارة وتوزيع الحديد',
    amount: 300000,
    date: '2025-05-20',
    paidByPartnerId: 'partner-2',
    notes: 'سداد دفعة ثانية من مديونية الحديد',
    createdAt: '2025-05-20T14:00:00Z',
  },
];

const initialPartnerLedgerEntries: PartnerLedgerEntry[] = [
  {
    id: 'pledger-1',
    partnerId: 'partner-1',
    propertyId: 'prop-1',
    entryType: PartnerLedgerEntryType.Contribution,
    amount: 15000000,
    authorizedBy: 'uid-admin-01',
    notes: 'إيداع رأس المال التأسيسي المعتمد (60%)',
    createdAt: '2025-01-01T08:00:00Z',
    updatedAt: '2025-01-01T08:00:00Z',
  },
  {
    id: 'pledger-2',
    partnerId: 'partner-2',
    propertyId: 'prop-1',
    entryType: PartnerLedgerEntryType.Contribution,
    amount: 10000000,
    authorizedBy: 'uid-admin-01',
    notes: 'إيداع رأس المال التأسيسي المعتمد (40%)',
    createdAt: '2025-01-01T08:00:00Z',
    updatedAt: '2025-01-01T08:00:00Z',
  },
];

const initialPayments: PaymentRecord[] = [
  {
    id: 'pay-1',
    propertyId: 'prop-1',
    unitId: 'unit-101',
    installmentId: 'inst-1',
    amount: 140000,
    customerName: 'م. أحمد محمود البدري',
    receivedAt: '2025-06-08',
    paymentMethod: 'bankTransfer' as any,
    paymentSource: 'installment',
    notes: 'تحويل بنكي على حساب الشركة',
    receiptNumber: 'RC-1001',
    createdBy: 'uid-admin-01',
  },
  {
    id: 'pay-2',
    propertyId: 'prop-1',
    unitId: 'unit-101',
    installmentId: 'inst-2',
    amount: 140000,
    customerName: 'م. أحمد محمود البدري',
    receivedAt: '2025-09-12',
    paymentMethod: 'bankTransfer' as any,
    paymentSource: 'installment',
    notes: 'تحويل بنكي - قسط سبتمبر',
    receiptNumber: 'RC-1002',
    createdBy: 'uid-admin-01',
  },
  {
    id: 'pay-3',
    propertyId: 'prop-1',
    unitId: 'unit-102',
    installmentId: 'inst-5',
    amount: 157500,
    customerName: 'د. خالد عبد الرحمن',
    receivedAt: '2025-07-01',
    paymentMethod: 'cheque' as any,
    paymentSource: 'installment',
    notes: 'شيك مصرفي مقبول الدفع',
    receiptNumber: 'RC-1003',
    createdBy: 'uid-admin-01',
  },
];

const initialPriceHistory: PriceHistoryRecord[] = [
  {
    id: 'ph-1',
    propertyId: 'prop-1',
    unitId: 'unit-101',
    entityType: 'unit',
    propertyName: 'كمبوند الأندلس ريزيدنس',
    unitNumber: 'A-101',
    previousPrice: 2500000,
    newPrice: 2800000,
    absoluteChange: 300000,
    percentageChange: 12.0,
    reason: 'ارتفاع تكاليف مواد البناء وتحديث أسعار التجمع الخامس',
    changedBy: 'uid-admin-01',
    changedByName: 'الحاج إبراهيم الشيشتاوي',
    timestamp: '2025-01-20T10:30:00Z',
  },
  {
    id: 'ph-2',
    propertyId: 'prop-1',
    unitId: 'unit-102',
    entityType: 'unit',
    propertyName: 'كمبوند الأندلس ريزيدنس',
    unitNumber: 'A-102',
    previousPrice: 2900000,
    newPrice: 3150000,
    absoluteChange: 250000,
    percentageChange: 8.62,
    reason: 'إضافة باقة تشطيب ألترا سوبر لوكس',
    changedBy: 'uid-admin-01',
    changedByName: 'الحاج إبراهيم الشيشتاوي',
    timestamp: '2025-02-15T11:15:00Z',
  },
];

const initialActivityLogs: ActivityLogEntry[] = [
  {
    id: 'act-1',
    actorId: 'uid-admin-01',
    actorName: 'الحاج إبراهيم الشيشتاوي',
    action: 'bootstrap_system',
    entityType: 'auth',
    entityId: 'main-ws',
    createdAt: '2025-01-01T08:00:00Z',
    metadata: { description: 'تشغيل النظام المحاسبي المركزي وتوثيق الشركاء' },
  },
  {
    id: 'act-2',
    actorId: 'uid-admin-01',
    actorName: 'الحاج إبراهيم الشيشتاوي',
    action: 'update_price',
    entityType: 'price',
    entityId: 'unit-101',
    createdAt: '2025-01-20T10:30:00Z',
    metadata: { unitNumber: 'A-101', newPrice: 2800000 },
  },
];

// In-Memory Authoritative Accounting Repository
class AccountingRepository {
  private projects: PropertyProject[] = [...initialProjects];
  private units: UnitSale[] = [...initialUnits];
  private installments: Installment[] = [...initialInstallments];
  private expenses: ExpenseRecord[] = [...initialExpenses];
  private materialExpenses: MaterialExpenseEntry[] = [...initialMaterialExpenses];
  private supplierPayments: SupplierPaymentRecord[] = [...initialSupplierPayments];
  private partners: Partner[] = [...initialPartners];
  private partnerLedgers: PartnerLedgerEntry[] = [...initialPartnerLedgerEntries];
  private payments: PaymentRecord[] = [...initialPayments];
  private priceHistory: PriceHistoryRecord[] = [...initialPriceHistory];
  private activityLogs: ActivityLogEntry[] = [...initialActivityLogs];

  // Audit Logging
  private logActivity(
    user: AuthUserSession,
    action: string,
    entityType: ActivityLogEntry['entityType'],
    entityId: string,
    metadata?: Record<string, unknown>
  ) {
    const entry: ActivityLogEntry = {
      id: `act-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`,
      actorId: user.uid,
      actorName: user.fullName,
      action,
      entityType,
      entityId,
      createdAt: new Date().toISOString(),
      metadata,
    };
    this.activityLogs.unshift(entry);
  }

  // Getters with Role-Based Scoping
  getProjects() {
    return [...this.projects];
  }

  getUnits(user?: AuthUserSession) {
    return [...this.units];
  }

  getInstallments(user?: AuthUserSession) {
    return [...this.installments];
  }

  getExpenses(user?: AuthUserSession) {
    return [...this.expenses];
  }

  getMaterialExpenses() {
    return [...this.materialExpenses];
  }

  getSupplierPayments() {
    return [...this.supplierPayments];
  }

  getPartners(user?: AuthUserSession) {
    if (user && user.role === 'partner' && user.partnerId) {
      // Partner can view partner list for transparency or their own ledger
      return this.partners.filter(p => p.id === user.partnerId);
    }
    return [...this.partners];
  }

  getAllPartners() {
    return [...this.partners];
  }

  getPartnerLedgers(user?: AuthUserSession) {
    if (user && user.role === 'partner' && user.partnerId) {
      return this.partnerLedgers.filter(entry => entry.partnerId === user.partnerId);
    }
    return [...this.partnerLedgers];
  }

  getPayments() {
    return [...this.payments];
  }

  getPriceHistory() {
    return [...this.priceHistory];
  }

  getActivityLogs(user?: AuthUserSession) {
    if (user && user.role === 'partner') {
      return this.activityLogs.filter(log => log.actorId === user.uid);
    }
    return [...this.activityLogs];
  }

  // Computations
  getReconciliation(user?: AuthUserSession): CompanyReconciliation {
    return AccountingEngine.reconcileCompany({
      projects: this.projects,
      units: this.units,
      installments: this.installments,
      payments: this.payments,
      expenses: this.expenses,
      materialExpenses: this.materialExpenses,
      supplierPayments: this.supplierPayments,
      partners: this.partners,
      ledgerEntries: this.partnerLedgers,
    });
  }

  getPriceMetrics(): PriceMetric[] {
    return PriceMonitoringEngine.buildPriceMetrics({
      projects: this.projects,
      units: this.units,
      historyRecords: this.priceHistory,
    });
  }

  // Mutations
  recordExpense(user: AuthUserSession, expense: Omit<ExpenseRecord, 'id'>): ExpenseRecord {
    const newRecord: ExpenseRecord = {
      ...expense,
      id: `exp-${Date.now()}`,
    };
    this.expenses.unshift(newRecord);
    this.logActivity(user, 'create_expense', 'expense', newRecord.id, {
      title: newRecord.title,
      amount: newRecord.amount,
      category: newRecord.category,
    });
    return newRecord;
  }

  recordMaterialExpense(user: AuthUserSession, entry: Omit<MaterialExpenseEntry, 'id'>): MaterialExpenseEntry {
    const newEntry: MaterialExpenseEntry = {
      ...entry,
      id: `mat-${Date.now()}`,
      createdAt: new Date().toISOString(),
    };
    this.materialExpenses.unshift(newEntry);
    this.logActivity(user, 'create_material_expense', 'expense', newEntry.id, {
      itemName: newEntry.itemName,
      supplierName: newEntry.supplierName,
      totalPrice: newEntry.totalPrice,
    });
    return newEntry;
  }

  recordSupplierPayment(user: AuthUserSession, payment: Omit<SupplierPaymentRecord, 'id'>): SupplierPaymentRecord {
    const newRecord: SupplierPaymentRecord = {
      ...payment,
      id: `sup-pay-${Date.now()}`,
      createdAt: new Date().toISOString(),
    };
    this.supplierPayments.unshift(newRecord);

    // Update remaining dues in material invoices for this supplier
    let remainingToDeduct = newRecord.amount;
    for (const invoice of this.materialExpenses) {
      if (invoice.supplierName === newRecord.supplierName && invoice.amountRemaining > 0 && remainingToDeduct > 0) {
        const deduct = Math.min(invoice.amountRemaining, remainingToDeduct);
        invoice.amountPaid += deduct;
        invoice.amountRemaining -= deduct;
        remainingToDeduct -= deduct;
      }
    }

    this.logActivity(user, 'record_supplier_payment', 'payment', newRecord.id, {
      supplierName: newRecord.supplierName,
      amount: newRecord.amount,
      paidByPartnerId: newRecord.paidByPartnerId,
    });
    return newRecord;
  }

  recordPartnerLedgerEntry(user: AuthUserSession, entry: Omit<PartnerLedgerEntry, 'id' | 'createdAt' | 'updatedAt'>): PartnerLedgerEntry {
    const now = new Date().toISOString();
    const newEntry: PartnerLedgerEntry = {
      ...entry,
      id: `pledger-${Date.now()}`,
      createdAt: now,
      updatedAt: now,
    };
    this.partnerLedgers.unshift(newEntry);

    // Update partner capital if entry is contribution
    if (newEntry.entryType === PartnerLedgerEntryType.Contribution) {
      const partner = this.partners.find(p => p.id === newEntry.partnerId);
      if (partner) {
        partner.initialCapital += newEntry.amount;
      }
    }

    this.logActivity(user, 'create_partner_ledger_entry', 'partner', newEntry.id, {
      partnerId: newEntry.partnerId,
      entryType: newEntry.entryType,
      amount: newEntry.amount,
    });
    return newEntry;
  }

  recordPayment(user: AuthUserSession, payment: Omit<PaymentRecord, 'id'>): PaymentRecord {
    const newPayment: PaymentRecord = {
      ...payment,
      id: `pay-${Date.now()}`,
    };
    this.payments.unshift(newPayment);

    // If linked to an installment, update installment status
    if (newPayment.installmentId) {
      const inst = this.installments.find(i => i.id === newPayment.installmentId);
      if (inst) {
        inst.paidAmount += newPayment.amount;
        if (inst.paidAmount >= inst.amount) {
          inst.status = InstallmentStatus.Paid;
          inst.paidDate = newPayment.receivedAt;
        } else {
          inst.status = InstallmentStatus.PartiallyPaid;
        }
      }
    }

    this.logActivity(user, 'record_customer_payment', 'payment', newPayment.id, {
      unitId: newPayment.unitId,
      amount: newPayment.amount,
      customerName: newPayment.customerName,
      source: newPayment.paymentSource,
    });
    return newPayment;
  }

  updateUnitPrice(user: AuthUserSession, unitId: string, newPrice: number, reason?: string): PriceHistoryRecord {
    const unitIndex = this.units.findIndex(u => u.id === unitId);
    if (unitIndex === -1) {
      throw new Error(`Unit with ID ${unitId} not found`);
    }

    const unit = this.units[unitIndex];
    const project = this.projects.find(p => p.id === unit.propertyId);
    const propertyName = project?.name || 'مشروع غير محدد';

    const { record, updatedUnit } = PriceMonitoringEngine.createPriceChangeRecord({
      unit,
      propertyName,
      newPrice,
      changedBy: user.uid,
      changedByName: user.fullName,
      reason,
    });

    this.units[unitIndex] = updatedUnit;
    this.priceHistory.unshift(record);

    this.logActivity(user, 'update_unit_price', 'price', record.id, {
      unitId,
      unitNumber: unit.unitNumber,
      previousPrice: record.previousPrice,
      newPrice: record.newPrice,
      absoluteChange: record.absoluteChange,
      percentageChange: record.percentageChange,
      reason: record.reason,
    });

    return record;
  }

  createProject(user: AuthUserSession, project: Omit<PropertyProject, 'id' | 'createdAt' | 'updatedAt' | 'createdBy' | 'workspaceId' | 'archived'>): PropertyProject {
    const now = new Date().toISOString().split('T')[0];
    const newProject: PropertyProject = {
      ...project,
      id: `prop-${Date.now()}`,
      createdAt: now,
      updatedAt: now,
      createdBy: user.uid,
      workspaceId: user.workspaceId,
      archived: false,
    };
    this.projects.unshift(newProject);
    this.logActivity(user, 'create_project', 'property', newProject.id, {
      name: newProject.name,
      location: newProject.location,
      totalBudget: newProject.totalBudget,
      totalSalesTarget: newProject.totalSalesTarget,
    });
    return newProject;
  }

  createUnit(user: AuthUserSession, unit: Omit<UnitSale, 'id' | 'status' | 'contractDate'> & { status?: UnitStatus }): UnitSale {
    const newUnit: UnitSale = {
      ...unit,
      id: `unit-${Date.now()}`,
      status: unit.status || (unit.customerName ? UnitStatus.Sold : UnitStatus.Available),
      contractDate: unit.customerName ? new Date().toISOString().split('T')[0] : '',
    };
    this.units.unshift(newUnit);
    this.logActivity(user, 'create_unit', 'unit', newUnit.id, {
      propertyId: newUnit.propertyId,
      unitNumber: newUnit.unitNumber,
      salePrice: newUnit.salePrice,
      status: newUnit.status,
    });
    return newUnit;
  }

  createPartner(user: AuthUserSession, partner: Omit<Partner, 'id' | 'joinedDate' | 'status'>): Partner {
    const newPartner: Partner = {
      ...partner,
      id: `partner-${Date.now()}`,
      joinedDate: new Date().toISOString().split('T')[0],
      status: 'active',
    };
    this.partners.push(newPartner);

    // Automatically create corresponding initial capital ledger entry
    if (newPartner.initialCapital > 0) {
      const now = new Date().toISOString();
      this.partnerLedgers.unshift({
        id: `pledger-${Date.now()}`,
        partnerId: newPartner.id,
        propertyId: this.projects[0]?.id || 'prop-1',
        entryType: PartnerLedgerEntryType.Contribution,
        amount: newPartner.initialCapital,
        authorizedBy: user.uid,
        notes: `إيداع رأس المال التأسيسي للشريك ${newPartner.name}`,
        createdAt: now,
        updatedAt: now,
      });
    }

    this.logActivity(user, 'create_partner', 'partner', newPartner.id, {
      name: newPartner.name,
      shareRatio: newPartner.shareRatio,
      initialCapital: newPartner.initialCapital,
    });
    return newPartner;
  }
}

// Global Singleton Accounting Service Instance
export const accountingService = new AccountingRepository();
