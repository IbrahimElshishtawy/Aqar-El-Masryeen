// Type definitions converted from aqarelmasryeen/lib/shared/enums and models

export enum UserRole {
  Owner = 'owner',
  Admin = 'admin',
  Accountant = 'accountant',
  Partner = 'partner',
  Viewer = 'viewer',
}

export type AccountRole = 'admin' | 'accountant' | 'partner' | 'viewer';

export interface AuthUserSession {
  uid: string;
  email: string;
  fullName: string;
  role: AccountRole;
  partnerId?: string; // If role === 'partner', links to partners/{partnerId}
  workspaceId: string;
  createdAt?: string;
}

export enum PartnerLedgerEntryType {
  Contribution = 'contribution',
  Settlement = 'settlement',
  Obligation = 'obligation',
  Adjustment = 'adjustment',
}

export const PartnerLedgerEntryTypeLabels: Record<PartnerLedgerEntryType, string> = {
  [PartnerLedgerEntryType.Contribution]: 'إيداع رأس مال ومساهمة',
  [PartnerLedgerEntryType.Settlement]: 'تسوية وتصفية مالية',
  [PartnerLedgerEntryType.Obligation]: 'التزام مالي مستحق',
  [PartnerLedgerEntryType.Adjustment]: 'تسوية قيد محاسبي',
};

export interface PartnerLedgerEntry {
  id: string;
  partnerId: string;
  propertyId: string;
  entryType: PartnerLedgerEntryType;
  amount: number;
  authorizedBy: string;
  notes?: string;
  createdAt: string;
  updatedAt: string;
  archived?: boolean;
}

export interface MaterialExpenseEntry {
  id: string;
  propertyId: string;
  materialCategory: MaterialCategory;
  itemName: string;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
  supplierName: string;
  amountPaid: number;
  amountRemaining: number;
  date: string;
  dueDate?: string;
  initialPaidByPartnerId?: string;
  initialPaidAmount?: number;
  notes?: string;
  archived?: boolean;
  createdAt?: string;
}

export interface SupplierPaymentRecord {
  id: string;
  propertyId: string;
  supplierName: string;
  amount: number;
  date: string;
  paidByPartnerId: string;
  paymentMethod?: PaymentMethod;
  notes?: string;
  archived?: boolean;
  createdAt?: string;
}

export interface PaymentRecord {
  id: string;
  propertyId: string;
  unitId: string;
  installmentId?: string;
  amount: number;
  customerName: string;
  payerName?: string;
  receivedAt: string;
  paymentMethod: PaymentMethod;
  paymentSource: 'downPayment' | 'installment' | 'cashCollection' | 'other';
  notes?: string;
  receiptNumber?: string;
  createdBy: string;
}

export interface PriceHistoryRecord {
  id: string;
  propertyId: string;
  unitId?: string; // Optional if price change was at property level
  entityType: 'property' | 'unit';
  propertyName: string;
  unitNumber?: string;
  previousPrice: number;
  newPrice: number;
  absoluteChange: number;
  percentageChange: number;
  reason?: string;
  changedBy: string;
  changedByName: string;
  timestamp: string;
}

export interface ActivityLogEntry {
  id: string;
  actorId: string;
  actorName: string;
  action: string;
  entityType: 'property' | 'unit' | 'expense' | 'payment' | 'partner' | 'installment' | 'price' | 'auth';
  entityId: string;
  createdAt: string;
  metadata?: Record<string, unknown>;
}

export interface PartnerLedgerSummaryRow {
  partner: Partner;
  totalPaid: number;
  totalOwed: number;
  balance: number; // positive = company owes partner, negative = partner owes company
  expectedShare: number;
  lastUpdated: string;
  notes: string;
}


export enum PropertyStatus {
  Planning = 'planning',
  Active = 'active',
  Delivered = 'delivered',
  Archived = 'archived',
}

export enum UnitStatus {
  Available = 'available',
  Reserved = 'reserved',
  Sold = 'sold',
  Cancelled = 'cancelled',
}

export enum UnitType {
  Apartment = 'apartment',
  Penthouse = 'penthouse',
  Office = 'office',
  Retail = 'retail',
  Floor = 'floor',
  Villa = 'villa',
}

export enum InstallmentStatus {
  Pending = 'pending',
  PartiallyPaid = 'partiallyPaid',
  Paid = 'paid',
  Overdue = 'overdue',
}

export enum PaymentMethod {
  Cash = 'cash',
  BankTransfer = 'bankTransfer',
  Cheque = 'cheque',
  Wallet = 'wallet',
  Other = 'other',
}

export enum ExpenseCategory {
  Construction = 'construction',
  Legal = 'legal',
  Permits = 'permits',
  Utilities = 'utilities',
  Marketing = 'marketing',
  Brokerage = 'brokerage',
  Maintenance = 'maintenance',
  Materials = 'materials',
  PartnerSettlement = 'partnerSettlement',
  Other = 'other',
}

export enum MaterialCategory {
  Cement = 'cement',
  Brick = 'brick',
  Steel = 'steel',
  Sand = 'sand',
  Gravel = 'gravel',
  Finishing = 'finishing',
  Electrical = 'electrical',
  Plumbing = 'plumbing',
  Paint = 'paint',
  Other = 'other',
}

// Arabic Labels Dictionaries
export const PropertyStatusLabels: Record<PropertyStatus, string> = {
  [PropertyStatus.Planning]: 'تحت الإنشاء',
  [PropertyStatus.Active]: 'نشط',
  [PropertyStatus.Delivered]: 'تم التسليم',
  [PropertyStatus.Archived]: 'مؤرشف',
};

export const UnitStatusLabels: Record<UnitStatus, string> = {
  [UnitStatus.Available]: 'متاحة',
  [UnitStatus.Reserved]: 'محجوزة',
  [UnitStatus.Sold]: 'مباعة',
  [UnitStatus.Cancelled]: 'ملغاة',
};

export const UnitTypeLabels: Record<UnitType, string> = {
  [UnitType.Apartment]: 'شقة',
  [UnitType.Penthouse]: 'بنتهاوس',
  [UnitType.Office]: 'مكتب',
  [UnitType.Retail]: 'محل تجاري',
  [UnitType.Floor]: 'دور كامل',
  [UnitType.Villa]: 'فيلا',
};

export const InstallmentStatusLabels: Record<InstallmentStatus, string> = {
  [InstallmentStatus.Pending]: 'مستحق',
  [InstallmentStatus.PartiallyPaid]: 'مدفوع جزئياً',
  [InstallmentStatus.Paid]: 'تم السداد',
  [InstallmentStatus.Overdue]: 'متأخر',
};

export const ExpenseCategoryLabels: Record<ExpenseCategory, string> = {
  [ExpenseCategory.Construction]: 'إنشاءات وبناء',
  [ExpenseCategory.Legal]: 'أتعاب قانونية',
  [ExpenseCategory.Permits]: 'تراخيص ورسوم',
  [ExpenseCategory.Utilities]: 'مرافق وخدمات',
  [ExpenseCategory.Marketing]: 'تسويق ودعاية',
  [ExpenseCategory.Brokerage]: 'عمولات سمسرة',
  [ExpenseCategory.Maintenance]: 'صيانة',
  [ExpenseCategory.Materials]: 'مواد بناء',
  [ExpenseCategory.PartnerSettlement]: 'تسوية أرباح شريك',
  [ExpenseCategory.Other]: 'مصروفات أخرى',
};

export const MaterialCategoryLabels: Record<MaterialCategory, string> = {
  [MaterialCategory.Cement]: 'أسمنت',
  [MaterialCategory.Brick]: 'طوب',
  [MaterialCategory.Steel]: 'حديد تسليح',
  [MaterialCategory.Sand]: 'رمل',
  [MaterialCategory.Gravel]: 'زلط',
  [MaterialCategory.Finishing]: 'تشطيبات وديكور',
  [MaterialCategory.Electrical]: 'تأسيس كهرباء',
  [MaterialCategory.Plumbing]: 'تأسيس سباكة',
  [MaterialCategory.Paint]: 'دهانات',
  [MaterialCategory.Other]: 'مواد أخرى',
};

// Data Models
export interface PropertyProject {
  id: string;
  name: string;
  location: string;
  apartmentCount: number;
  description: string;
  status: PropertyStatus;
  totalBudget: number;
  totalSalesTarget: number;
  createdAt: string;
  updatedAt: string;
  createdBy: string;
  workspaceId: string;
  archived: boolean;
}

export interface UnitSale {
  id: string;
  propertyId: string;
  unitNumber: string;
  unitType: UnitType;
  floor: number;
  areaSqm: number;
  salePrice: number;
  downPayment: number;
  customerName: string;
  customerPhone: string;
  status: UnitStatus;
  contractDate: string;
  notes?: string;
}

export interface InstallmentPlan {
  id: string;
  propertyId: string;
  unitId: string;
  customerName: string;
  totalAmount: number;
  installmentCount: number;
  installmentAmount: number;
  intervalDays: number;
  startDate: string;
  workspaceId: string;
}

export interface Installment {
  id: string;
  planId: string;
  propertyId: string;
  unitId: string;
  sequence: number;
  amount: number;
  paidAmount: number;
  dueDate: string;
  status: InstallmentStatus;
  customerName?: string;
  paidDate?: string;
}

export interface ExpenseRecord {
  id: string;
  propertyId: string;
  category: ExpenseCategory;
  title: string;
  amount: number;
  date: string;
  paidByPartnerId?: string;
  notes?: string;
  supplierName?: string;
  receiptNumber?: string;
}

export interface Partner {
  id: string;
  name: string;
  phone: string;
  shareRatio: number; // e.g. 0.40 for 40%
  initialCapital: number;
  joinedDate: string;
  status: 'active' | 'inactive';
}

export interface PartnerSettlement {
  partnerId: string;
  partnerName: string;
  contributedAmount: number;
  shareRatio: number;
  expectedContribution: number;
  balanceDelta: number; // positive = owed money, negative = needs to pay
}
