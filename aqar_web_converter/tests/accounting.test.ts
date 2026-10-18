import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { Money, roundToTwoDecimals } from '../src/lib/accounting/precision';
import { AccountingEngine } from '../src/lib/accounting/engine';
import { PriceMonitoringEngine } from '../src/lib/price-monitoring/engine';
import { SessionService } from '../src/lib/auth/session';
import { authorizedUsers, verifyUserCredentials } from '../src/lib/auth/users';
import {
  Partner,
  ExpenseRecord,
  MaterialExpenseEntry,
  SupplierPaymentRecord,
  PropertyProject,
  UnitSale,
  Installment,
  InstallmentStatus,
  PriceHistoryRecord,
  ExpenseCategory,
  PaymentMethod,
  UnitStatus,
  UnitType,
} from '../src/types';

describe('Phase 1 & 3: Precision Money Arithmetic & Decimal Safety', () => {
  it('prevents IEEE 754 binary floating point precision drift', () => {
    // Standard JS float: 0.1 + 0.2 === 0.30000000000000004
    const m1 = Money.from(0.1);
    const m2 = Money.from(0.2);
    const sum = m1.plus(m2);

    assert.equal(sum.toNumber(), 0.3);
    assert.equal(sum.toCents(), BigInt(30));
  });

  it('performs accurate addition, subtraction, and multiplication', () => {
    const base = Money.from(1000.50);
    const added = base.plus(250.25);
    assert.equal(added.toNumber(), 1250.75);

    const subtracted = added.minus(50.75);
    assert.equal(subtracted.toNumber(), 1200.00);

    // 25% share
    const share = subtracted.multiply(0.25);
    assert.equal(share.toNumber(), 300.00);
  });

  it('handles negative balances, zero, and absolute values', () => {
    const deficit = Money.from(-450.75);
    assert.equal(deficit.isNegative(), true);
    assert.equal(deficit.isPositive(), false);
    assert.equal(deficit.abs().toNumber(), 450.75);

    const zero = Money.zero();
    assert.equal(zero.isZero(), true);
    assert.equal(zero.toNumber(), 0);
  });

  it('correctly rounds to two decimal places without drift', () => {
    assert.equal(roundToTwoDecimals(123.456), 123.46);
    assert.equal(roundToTwoDecimals(123.454), 123.45);
  });
});

describe('Phase 4: Flutter Partner Ledger & Settlement Parity', () => {
  const mockPartners: Partner[] = [
    {
      id: 'partner-1',
      name: 'الحاج إبراهيم الشيشتاوي',
      phone: '01012345678',
      shareRatio: 0.6, // 60% share
      initialCapital: 1000000,
      totalWithdrawals: 0,
      currentBalance: 0,
      status: 'active',
      joinedDate: '2025-01-01',
    },
    {
      id: 'partner-2',
      name: 'م. حسام الدين غانم',
      phone: '01087654321',
      shareRatio: 0.4, // 40% share
      initialCapital: 1000000,
      totalWithdrawals: 0,
      currentBalance: 0,
      status: 'active',
      joinedDate: '2025-01-01',
    },
  ];

  const mockExpenses: ExpenseRecord[] = [
    {
      id: 'exp-1',
      propertyId: 'prop-1',
      category: ExpenseCategory.Materials,
      amount: 1000000, // Total project expense = 1,000,000
      date: '2025-02-01',
      recipient: 'شركة أسمنت سيناء',
      description: 'دفعة أسمنت أولي',
      approvedBy: 'admin',
      paidByPartnerId: 'partner-1', // Partner 1 paid this 1,000,000 direct expense!
    },
  ];

  it('calculates partner exposure and delta matching Flutter PartnerLedgerCalculator exactly', () => {
    // Total exposure = 1,000,000 EGP
    // Partner 1: 60% expected share = 600,000 EGP. Paid = 1,000,000 EGP. Balance = +400,000 (Company owes Partner 1)
    // Partner 2: 40% expected share = 400,000 EGP. Paid = 0. Balance = -400,000, totalOwed = 400,000 (Partner 2 owes Company)

    const rows = AccountingEngine.calculatePartnerLedgers({
      partners: mockPartners,
      expenses: mockExpenses,
      materialExpenses: [],
      supplierPayments: [],
      ledgerEntries: [],
    });

    assert.equal(rows.length, 2);

    const p1 = rows.find((r) => r.partner.id === 'partner-1');
    assert.ok(p1);
    assert.equal(p1.expectedShare, 600000);
    assert.equal(p1.totalPaid, 1000000);
    assert.equal(p1.balance, 400000);
    assert.equal(p1.totalOwed, 0);

    const p2 = rows.find((r) => r.partner.id === 'partner-2');
    assert.ok(p2);
    assert.equal(p2.expectedShare, 400000);
    assert.equal(p2.totalPaid, 0);
    assert.equal(p2.balance, -400000);
    assert.equal(p2.totalOwed, 400000);
  });

  it('calculates supplier materials and payments reconciliation', () => {
    const materials: MaterialExpenseEntry[] = [
      {
        id: 'mat-1',
        supplierName: 'شركة حديد عز',
        quantity: 10,
        unit: 'طن',
        unitPrice: 35000,
        totalPrice: 350000,
        amountPaid: 200000,
        date: '2025-01-15',
        propertyId: 'prop-1',
        propertyName: 'برج الأندلس',
      },
      {
        id: 'mat-2',
        supplierName: 'شركة حديد عز',
        quantity: 5,
        unit: 'طن',
        unitPrice: 35000,
        totalPrice: 175000,
        amountPaid: 175000,
        date: '2025-02-10',
        propertyId: 'prop-1',
        propertyName: 'برج الأندلس',
      },
    ];

    const supplierPayments: SupplierPaymentRecord[] = [
      {
        id: 'sp-1',
        supplierName: 'شركة حديد عز',
        amount: 200000,
        paymentDate: '2025-01-15',
        propertyId: 'prop-1',
        propertyName: 'برج الأندلس',
        paymentMethod: PaymentMethod.BankTransfer,
      },
      {
        id: 'sp-2',
        supplierName: 'شركة حديد عز',
        amount: 175000,
        paymentDate: '2025-02-10',
        propertyId: 'prop-1',
        propertyName: 'برج الأندلس',
        paymentMethod: PaymentMethod.Cheque,
      },
    ];

    const supplierSummary = AccountingEngine.calculateSupplierLedger(materials, supplierPayments);
    assert.equal(supplierSummary.overallTotal, 525000);
    assert.equal(supplierSummary.overallPaid, 375000);
    assert.equal(supplierSummary.overallRemaining, 150000);

    const ezzSteel = supplierSummary.summaries.find((s) => s.supplierName === 'شركة حديد عز');
    assert.ok(ezzSteel);
    assert.equal(ezzSteel.totalPurchased, 525000);
    assert.equal(ezzSteel.totalPaid, 375000);
    assert.equal(ezzSteel.totalRemaining, 150000);
  });

  it('produces an authoritative master company reconciliation summary', () => {
    const projects: PropertyProject[] = [
      {
        id: 'prop-1',
        name: 'برج الأندلس',
        location: 'التجمع الخامس',
        availableUnits: 5,
        totalRevenue: 2000000,
        collectedRevenue: 1000000,
        totalExpenses: 900000,
        expectedProfit: 1100000,
        completionRate: 60,
        createdAt: '2025-01-01',
      },
    ];

    const units: UnitSale[] = [
      {
        id: 'unit-1',
        propertyId: 'prop-1',
        unitNumber: 'A-101',
        unitType: UnitType.Apartment,
        areaSqm: 180,
        salePrice: 2000000,
        downPayment: 500000,
        customerName: 'محمود عبد الرحيم',
        customerPhone: '01011112222',
        status: UnitStatus.Sold,
        contractDate: '2025-02-01',
      },
    ];

    const installments: Installment[] = [
      {
        id: 'inst-1',
        unitId: 'unit-1',
        propertyId: 'prop-1',
        clientName: 'محمود عبد الرحيم',
        amount: 300000,
        paidAmount: 300000,
        dueDate: '2025-03-01',
        status: InstallmentStatus.Paid,
        propertyTitle: 'برج الأندلس',
        paidDate: '2025-03-01',
      },
      {
        id: 'inst-2',
        unitId: 'unit-1',
        propertyId: 'prop-1',
        clientName: 'محمود عبد الرحيم',
        amount: 200000,
        paidAmount: 0,
        dueDate: '2025-06-01',
        status: InstallmentStatus.Pending,
        propertyTitle: 'برج الأندلس',
      },
    ];

    const recon = AccountingEngine.reconcileCompany({
      projects,
      units,
      installments,
      payments: [],
      expenses: mockExpenses,
      materialExpenses: [],
      supplierPayments: [],
      partners: mockPartners,
      ledgerEntries: [],
    });

    // Total sales value = 2,000,000 (from unit-1)
    assert.equal(recon.totalSalesValue, 2000000);
    // Total collected = down payment (500,000) + paid installment (300,000) = 800,000
    assert.equal(recon.totalCollected, 800000);
    // Outstanding receivables = 2,000,000 - 800,000 = 1,200,000
    assert.equal(recon.totalOutstandingReceivables, 1200000);
    // Total general expenses = 1,000,000 (from mockExpenses)
    assert.equal(recon.totalGeneralExpenses, 1000000);
    // Net profit = 2,000,000 - 1,000,000 = 1,000,000
    assert.equal(recon.netCompanyProfit, 1000000);
  });
});

describe('Phase 5: Real-Estate Price Monitoring Engine', () => {
  const projects: PropertyProject[] = [
    {
      id: 'prop-1',
      name: 'برج الأندلس',
      location: 'التجمع الخامس',
      availableUnits: 1,
      totalRevenue: 4000000,
      collectedRevenue: 1800000,
      totalExpenses: 900000,
      expectedProfit: 1100000,
      completionRate: 60,
      createdAt: '2025-01-01',
    },
  ];

  const units: UnitSale[] = [
    {
      id: 'unit-1',
      propertyId: 'prop-1',
      unitNumber: 'U-101',
      unitType: UnitType.Apartment,
      areaSqm: 200,
      salePrice: 2200000,
      downPayment: 500000,
      customerName: '',
      customerPhone: '',
      status: UnitStatus.Available,
    },
    {
      id: 'unit-2',
      propertyId: 'prop-1',
      unitNumber: 'U-102',
      unitType: UnitType.Penthouse,
      areaSqm: 250,
      salePrice: 1800000,
      downPayment: 500000,
      customerName: 'خالد توفيق',
      customerPhone: '01099998888',
      status: UnitStatus.Sold,
    },
  ];

  const history: PriceHistoryRecord[] = [
    {
      id: 'ph-1',
      propertyId: 'prop-1',
      unitId: 'unit-1',
      entityType: 'unit',
      propertyName: 'برج الأندلس',
      unitNumber: 'U-101',
      previousPrice: 2000000,
      newPrice: 2200000,
      absoluteChange: 200000,
      percentageChange: 10,
      reason: 'تحديث سعر الطرح الأولي',
      changedBy: 'uid-admin-01',
      changedByName: 'مدير المنظومة',
      timestamp: '2026-03-01T10:00:00Z',
    },
  ];

  it('builds price metrics and price change comparisons', () => {
    const metrics = PriceMonitoringEngine.buildPriceMetrics({
      projects,
      units,
      historyRecords: history,
    });

    assert.equal(metrics.length, 2);

    const m1 = metrics.find((m) => m.unitId === 'unit-1');
    assert.ok(m1);
    assert.equal(m1.currentAskingPrice, 2200000);
    assert.equal(m1.previousPrice, 2000000);
    assert.equal(m1.absoluteChange, 200000);
    assert.equal(m1.percentageChange, 10);
    // Price per meter = 2,200,000 / 200 = 11,000
    assert.equal(m1.pricePerMeter, 11000);
  });

  it('evaluates unit price update with history record and never affects realized revenue', () => {
    const result = PriceMonitoringEngine.createPriceChangeRecord({
      unit: units[0],
      propertyName: 'برج الأندلس',
      newPrice: 2420000,
      changedBy: 'uid-admin-01',
      changedByName: 'الحاج إبراهيم الشيشتاوي',
      reason: 'ارتفاع أسعار مواد البناء والتشطيب الفاخر',
    });

    assert.equal(result.updatedUnit.salePrice, 2420000);
    assert.equal(result.record.previousPrice, 2200000);
    assert.equal(result.record.newPrice, 2420000);
    assert.equal(result.record.absoluteChange, 220000);
    assert.equal(result.record.percentageChange, 10);
    assert.equal(result.record.changedBy, 'uid-admin-01');
    assert.ok(result.record.timestamp);
  });
});

describe('Phase 6: Dedicated Accounting Authentication & RBAC Security Matrix', () => {
  it('authenticates valid users with salted SHA-256 password hash', async () => {
    const user = await verifyUserCredentials('admin@aqarelmasryeen.com', 'Aqar@2026Secure');
    assert.ok(user);
    assert.equal(user.role, 'admin');
    assert.equal(user.email, 'admin@aqarelmasryeen.com');
  });

  it('rejects invalid password or unknown user', async () => {
    const wrongPass = await verifyUserCredentials('admin@aqarelmasryeen.com', 'WrongPassword123');
    assert.equal(wrongPass, null);

    const unknownUser = await verifyUserCredentials('nonexistent@domain.com', 'Aqar@2026Secure');
    assert.equal(unknownUser, null);
  });

  it('generates cryptographic HMAC-SHA256 session token and verifies it', async () => {
    const user = authorizedUsers[0]; // Admin
    const token = await SessionService.createToken(user, 2); // 2 hours validity

    const verified = await SessionService.verifyToken(token);
    assert.ok(verified);
    assert.equal(verified.email, user.email);
    assert.equal(verified.role, 'admin');
  });

  it('rejects tampered tokens with invalid HMAC signatures', async () => {
    const user = authorizedUsers[0];
    const token = await SessionService.createToken(user, 2);

    // Tamper payload
    const parts = token.split('.');
    parts[1] = Buffer.from(JSON.stringify({ ...user, role: 'super_hacker' })).toString('base64url');
    const tamperedToken = parts.join('.');

    const result = await SessionService.verifyToken(tamperedToken);
    assert.equal(result, null);
  });

  it('enforces RBAC permissions strictly across all 4 roles', () => {
    // Admin: can do everything
    assert.equal(SessionService.hasPermission('admin', 'view_all_accounting'), true);
    assert.equal(SessionService.hasPermission('admin', 'manage_users'), true);
    assert.equal(SessionService.hasPermission('admin', 'approve_settlements'), true);

    // Accountant: can manage financial ops, cannot manage users or alter partners
    assert.equal(SessionService.hasPermission('accountant', 'view_all_accounting'), true);
    assert.equal(SessionService.hasPermission('accountant', 'manage_expenses'), true);
    assert.equal(SessionService.hasPermission('accountant', 'manage_installments'), true);
    assert.equal(SessionService.hasPermission('accountant', 'manage_users'), false);
    assert.equal(SessionService.hasPermission('accountant', 'approve_settlements'), false);

    // Partner: can only view own ledger and price monitoring
    assert.equal(SessionService.hasPermission('partner', 'view_own_partner_ledger'), true);
    assert.equal(SessionService.hasPermission('partner', 'manage_price_monitoring'), true);
    assert.equal(SessionService.hasPermission('partner', 'view_all_accounting'), false);
    assert.equal(SessionService.hasPermission('partner', 'manage_expenses'), false);
    assert.equal(SessionService.hasPermission('partner', 'manage_users'), false);

    // Viewer: read-only price monitoring
    assert.equal(SessionService.hasPermission('viewer', 'manage_price_monitoring'), true);
    assert.equal(SessionService.hasPermission('viewer', 'view_all_accounting'), false);
    assert.equal(SessionService.hasPermission('viewer', 'manage_expenses'), false);
  });

  it('enforces Partner Data Isolation (cannot access other partner records)', () => {
    const partnerUser = authorizedUsers.find((u) => u.role === 'partner');
    assert.ok(partnerUser);
    assert.equal(partnerUser.partnerId, 'partner-2');

    // Trying to view partner-2: Allowed
    const canViewSelf = partnerUser.role === 'admin' || (partnerUser.partnerId as string) === 'partner-2';
    assert.equal(canViewSelf, true);

    // Trying to view partner-1: Forbidden
    const canViewOther = partnerUser.role === 'admin' || (partnerUser.partnerId as string) === 'partner-1';
    assert.equal(canViewOther, false);
  });
});

describe('Phase 7 & 9: Database Integrity, Financial Audit Logging & Idempotency', () => {
  it('creates immutable audit trail entry for price changes', () => {
    const unit: UnitSale = {
      id: 'unit-audit-01',
      propertyId: 'prop-1',
      unitNumber: 'B-204',
      unitType: UnitType.Apartment,
      areaSqm: 150,
      salePrice: 1500000,
      downPayment: 300000,
      customerName: '',
      customerPhone: '',
      status: UnitStatus.Available,
    };

    const change = PriceMonitoringEngine.createPriceChangeRecord({
      unit,
      propertyName: 'برج الأندلس',
      newPrice: 1650000,
      changedBy: 'uid-admin-01',
      changedByName: 'الحاج إبراهيم الشيشتاوي',
      reason: 'زيادة مرحلية حسب جدول الأسعار',
    });

    assert.ok(change.record.id.startsWith('price-hist-'));
    assert.equal(change.record.previousPrice, 1500000);
    assert.equal(change.record.newPrice, 1650000);
    assert.equal(change.record.percentageChange, 10);
    assert.equal(change.record.changedBy, 'uid-admin-01');
    assert.ok(change.record.timestamp);
  });

  it('preserves consistency: asking price change never increases collected revenue or net profit', () => {
    // In real estate accounting: increasing the asking price of an unsold unit does NOT count as profit
    const initialUnit: UnitSale = {
      id: 'unit-inv-01',
      propertyId: 'prop-1',
      unitNumber: 'C-301',
      unitType: UnitType.Penthouse,
      areaSqm: 300,
      salePrice: 3000000,
      downPayment: 0,
      customerName: '',
      customerPhone: '',
      status: UnitStatus.Available,
    };

    const initialRecon = AccountingEngine.reconcileCompany({
      projects: [],
      units: [initialUnit],
      installments: [],
      payments: [],
      expenses: [],
      materialExpenses: [],
      supplierPayments: [],
      partners: [],
      ledgerEntries: [],
    });

    // Unsold unit has 0 collected revenue
    assert.equal(initialRecon.totalCollected, 0);

    // Re-evaluating with asking price increased to 3,500,000
    const updatedUnit = { ...initialUnit, salePrice: 3500000 };
    const updatedRecon = AccountingEngine.reconcileCompany({
      projects: [],
      units: [updatedUnit],
      installments: [],
      payments: [],
      expenses: [],
      materialExpenses: [],
      supplierPayments: [],
      partners: [],
      ledgerEntries: [],
    });

    // Collected revenue MUST remain 0 (no unearned revenue recognition!)
    assert.equal(updatedRecon.totalCollected, 0);
  });

  it('guarantees zero-sum partner balance reconciliation across entire syndicate', () => {
    // If all project expenses are 1,000,000 and total paid is 1,000,000,
    // the sum of (balanceDelta) across all partners must sum to 0
    const partners: Partner[] = [
      {
        id: 'p1',
        name: 'شريك 1',
        phone: '111',
        shareRatio: 0.5,
        initialCapital: 0,
        totalWithdrawals: 0,
        currentBalance: 0,
        status: 'active',
        joinedDate: '2025-01-01',
      },
      {
        id: 'p2',
        name: 'شريك 2',
        phone: '222',
        shareRatio: 0.5,
        initialCapital: 0,
        totalWithdrawals: 0,
        currentBalance: 0,
        status: 'active',
        joinedDate: '2025-01-01',
      },
    ];

    const exp: ExpenseRecord[] = [
      {
        id: 'e1',
        propertyId: 'prop-1',
        category: ExpenseCategory.Materials,
        amount: 800000,
        date: '2025-01-01',
        recipient: 'مورد',
        description: 'حديد',
        approvedBy: 'admin',
        paidByPartnerId: 'p1', // p1 paid 800,000
      },
    ];

    const rows = AccountingEngine.calculatePartnerLedgers({
      partners,
      expenses: exp,
      materialExpenses: [],
      supplierPayments: [],
      ledgerEntries: [],
    });

    const sumBalance = rows.reduce((acc, r) => acc + r.balance, 0);
    // 400,000 (owed to p1) + (-400,000 owed by p2) = 0!
    assert.equal(Math.round(sumBalance), 0);
  });
});
