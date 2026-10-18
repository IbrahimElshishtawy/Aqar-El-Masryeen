import { Money } from './precision';
import {
  Partner,
  ExpenseRecord,
  MaterialExpenseEntry,
  SupplierPaymentRecord,
  PartnerLedgerEntry,
  PartnerLedgerEntryType,
  PartnerLedgerSummaryRow,
  PartnerSettlement,
  UnitSale,
  Installment,
  PaymentRecord,
  InstallmentStatus,
  PropertyProject,
} from '@/types';

export interface CompanyReconciliation {
  totalSalesValue: number;
  totalCollected: number;
  totalOutstandingReceivables: number;
  totalGeneralExpenses: number;
  totalMaterialPurchases: number;
  totalExpenseExposure: number;
  totalSupplierPaid: number;
  totalSupplierDuesPayable: number;
  netCompanyProfit: number;
  netCashFlow: number;
  partnerLedgerRows: PartnerLedgerSummaryRow[];
  settlements: PartnerSettlement[];
}

export class AccountingEngine {
  /**
   * Authoritative Partner Ledger Calculation
   * Matches aqarelmasryeen/lib/features/partners/domain/partner_ledger_calculator.dart
   * Calculated using decimal-safe Money arithmetic.
   */
  static calculatePartnerLedgers(params: {
    partners: Partner[];
    expenses: ExpenseRecord[];
    materialExpenses: MaterialExpenseEntry[];
    supplierPayments: SupplierPaymentRecord[];
    ledgerEntries: PartnerLedgerEntry[];
  }): PartnerLedgerSummaryRow[] {
    const { partners, expenses, materialExpenses, supplierPayments, ledgerEntries } = params;

    // Total expense exposure = sum(expenses) + sum(materialExpenses.totalPrice)
    let totalExpenseExposureMoney = Money.zero();
    for (const exp of expenses) {
      totalExpenseExposureMoney = totalExpenseExposureMoney.plus(exp.amount);
    }
    for (const mat of materialExpenses) {
      if (!mat.archived) {
        totalExpenseExposureMoney = totalExpenseExposureMoney.plus(mat.totalPrice);
      }
    }

    const rows: PartnerLedgerSummaryRow[] = partners.map(partner => {
      // 1. Authorized ledger entries
      const partnerEntries = ledgerEntries
        .filter(entry => !entry.archived && entry.partnerId === partner.id)
        .sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime());

      let authorizedPaidMoney = Money.zero();
      for (const entry of partnerEntries) {
        if (
          entry.entryType === PartnerLedgerEntryType.Contribution ||
          entry.entryType === PartnerLedgerEntryType.Settlement ||
          entry.entryType === PartnerLedgerEntryType.Adjustment
        ) {
          authorizedPaidMoney = authorizedPaidMoney.plus(entry.amount);
        }
      }

      // 2. Direct expenses paid by partner
      let directExpensePaidMoney = Money.zero();
      for (const exp of expenses) {
        if (exp.paidByPartnerId === partner.id) {
          directExpensePaidMoney = directExpensePaidMoney.plus(exp.amount);
        }
      }

      // 3. Initial material expense paid by partner
      let initialMaterialPaidMoney = Money.zero();
      for (const mat of materialExpenses) {
        if (!mat.archived && mat.initialPaidByPartnerId === partner.id) {
          initialMaterialPaidMoney = initialMaterialPaidMoney.plus(mat.initialPaidAmount || 0);
        }
      }

      // 4. Supplier payments made by partner
      let supplierPaymentsPaidMoney = Money.zero();
      for (const pay of supplierPayments) {
        if (!pay.archived && pay.paidByPartnerId === partner.id) {
          supplierPaymentsPaidMoney = supplierPaymentsPaidMoney.plus(pay.amount);
        }
      }

      // Total paid by partner
      const totalPaidMoney = authorizedPaidMoney
        .plus(directExpensePaidMoney)
        .plus(initialMaterialPaidMoney)
        .plus(supplierPaymentsPaidMoney);

      // Safe share ratio (0.0 <= ratio <= 1.0)
      const safeRatio = isFinite(partner.shareRatio) && partner.shareRatio > 0 ? partner.shareRatio : 0;
      const expectedShareMoney = totalExpenseExposureMoney.multiply(safeRatio);

      // Outstanding calculation
      const rawOutstandingMoney = expectedShareMoney.minus(totalPaidMoney);
      let totalOwedMoney = Money.zero();
      if (rawOutstandingMoney.isPositive()) {
        totalOwedMoney = rawOutstandingMoney.toNumber() >= expectedShareMoney.toNumber()
          ? expectedShareMoney
          : rawOutstandingMoney;
      }

      // Balance delta: totalPaid - expectedShare
      // Positive = Company/others owe this partner
      // Negative = Partner owes company/others
      const balanceMoney = totalPaidMoney.minus(expectedShareMoney);

      const lastUpdated = partnerEntries[0]?.updatedAt || partner.joinedDate || new Date().toISOString();
      const notes = partnerEntries[0]?.notes || '';

      return {
        partner,
        totalPaid: totalPaidMoney.toNumber(),
        totalOwed: totalOwedMoney.toNumber(),
        balance: balanceMoney.toNumber(),
        expectedShare: expectedShareMoney.toNumber(),
        lastUpdated,
        notes,
      };
    });

    return rows.sort((a, b) => b.totalOwed - a.totalOwed);
  }

  /**
   * Fast Partner Settlement Calculator
   * Matches aqarelmasryeen/lib/features/partners/domain/partner_settlement_calculator.dart
   */
  static calculateSettlements(partners: Partner[], expenses: ExpenseRecord[]): PartnerSettlement[] {
    let totalExpensesMoney = Money.zero();
    for (const exp of expenses) {
      totalExpensesMoney = totalExpensesMoney.plus(exp.amount);
    }

    return partners.map(partner => {
      let contributedMoney = Money.zero();
      for (const exp of expenses) {
        if (exp.paidByPartnerId === partner.id) {
          contributedMoney = contributedMoney.plus(exp.amount);
        }
      }

      const expectedMoney = totalExpensesMoney.multiply(partner.shareRatio || 0);
      const balanceDeltaMoney = contributedMoney.minus(expectedMoney);

      return {
        partnerId: partner.id,
        partnerName: partner.name,
        contributedAmount: contributedMoney.toNumber(),
        shareRatio: partner.shareRatio,
        expectedContribution: expectedMoney.toNumber(),
        balanceDelta: balanceDeltaMoney.toNumber(),
      };
    });
  }

  /**
   * Comprehensive Supplier & Materials Ledger
   * Matches aqarelmasryeen/lib/features/expenses/domain/materials_ledger_calculator.dart
   */
  static calculateSupplierLedger(
    materialExpenses: MaterialExpenseEntry[],
    supplierPayments: SupplierPaymentRecord[]
  ) {
    const suppliersMap = new Map<string, {
      supplierName: string;
      totalPurchased: Money;
      recordedInvoicePaid: Money;
      initialPaid: Money;
      supplierPayments: Money;
      invoiceCount: number;
    }>();

    for (const mat of materialExpenses) {
      if (mat.archived) continue;
      const key = (mat.supplierName || 'مورد عام').trim();
      const current = suppliersMap.get(key) || {
        supplierName: key,
        totalPurchased: Money.zero(),
        recordedInvoicePaid: Money.zero(),
        initialPaid: Money.zero(),
        supplierPayments: Money.zero(),
        invoiceCount: 0,
      };

      current.totalPurchased = current.totalPurchased.plus(mat.totalPrice);
      current.recordedInvoicePaid = current.recordedInvoicePaid.plus(mat.amountPaid);
      current.initialPaid = current.initialPaid.plus(mat.initialPaidAmount || 0);
      current.invoiceCount += 1;
      suppliersMap.set(key, current);
    }

    for (const pay of supplierPayments) {
      if (pay.archived) continue;
      const key = (pay.supplierName || 'مورد عام').trim();
      const current = suppliersMap.get(key) || {
        supplierName: key,
        totalPurchased: Money.zero(),
        recordedInvoicePaid: Money.zero(),
        initialPaid: Money.zero(),
        supplierPayments: Money.zero(),
        invoiceCount: 0,
      };

      current.supplierPayments = current.supplierPayments.plus(pay.amount);
      suppliersMap.set(key, current);
    }

    const summaries = Array.from(suppliersMap.values()).map(item => {
      const resolvedPaidNumber = Math.max(
        item.recordedInvoicePaid.toNumber(),
        item.initialPaid.plus(item.supplierPayments).toNumber()
      );
      const resolvedPaid = Money.from(resolvedPaidNumber);
      const purchasedNum = item.totalPurchased.toNumber();
      const remainingNum = Math.max(0, purchasedNum - resolvedPaid.toNumber());

      return {
        supplierName: item.supplierName,
        totalPurchased: purchasedNum,
        totalPaid: resolvedPaid.toNumber(),
        totalRemaining: remainingNum,
        invoiceCount: item.invoiceCount,
      };
    });

    const overallTotal = summaries.reduce((acc, s) => acc.plus(s.totalPurchased), Money.zero()).toNumber();
    const overallPaid = summaries.reduce((acc, s) => acc.plus(s.totalPaid), Money.zero()).toNumber();
    const overallRemaining = summaries.reduce((acc, s) => acc.plus(s.totalRemaining), Money.zero()).toNumber();

    return {
      summaries,
      overallTotal,
      overallPaid,
      overallRemaining,
    };
  }

  /**
   * Master Company & Partner Financial Reconciliation
   */
  static reconcileCompany(params: {
    projects: PropertyProject[];
    units: UnitSale[];
    installments: Installment[];
    payments: PaymentRecord[];
    expenses: ExpenseRecord[];
    materialExpenses: MaterialExpenseEntry[];
    supplierPayments: SupplierPaymentRecord[];
    partners: Partner[];
    ledgerEntries: PartnerLedgerEntry[];
  }): CompanyReconciliation {
    const {
      units,
      installments,
      payments,
      expenses,
      materialExpenses,
      supplierPayments,
      partners,
      ledgerEntries,
    } = params;

    // 1. Sales & Collections
    let totalSalesValue = Money.zero();
    let totalDownPayments = Money.zero();
    for (const unit of units) {
      if (unit.status === 'sold' || unit.customerName?.trim()) {
        totalSalesValue = totalSalesValue.plus(unit.salePrice);
        totalDownPayments = totalDownPayments.plus(unit.downPayment);
      }
    }

    let totalInstallmentCollections = Money.zero();
    for (const inst of installments) {
      if (inst.status === InstallmentStatus.Paid) {
        totalInstallmentCollections = totalInstallmentCollections.plus(inst.paidAmount);
      }
    }

    // Direct payments collection check
    let directPaymentsTotal = Money.zero();
    for (const p of payments) {
      directPaymentsTotal = directPaymentsTotal.plus(p.amount);
    }

    // Authoritative total collected is the greater of tracked installment collections + down payments vs direct receipts
    const totalCollected = Math.max(
      totalDownPayments.plus(totalInstallmentCollections).toNumber(),
      directPaymentsTotal.toNumber()
    );

    const totalOutstandingReceivables = Math.max(0, totalSalesValue.toNumber() - totalCollected);

    // 2. Expenses & Material Exposure
    let totalGeneralExpenses = Money.zero();
    for (const exp of expenses) {
      totalGeneralExpenses = totalGeneralExpenses.plus(exp.amount);
    }

    const supplierLedger = this.calculateSupplierLedger(materialExpenses, supplierPayments);
    const totalMaterialPurchases = supplierLedger.overallTotal;
    const totalSupplierDuesPayable = supplierLedger.overallRemaining;
    const totalSupplierPaid = supplierLedger.overallPaid;

    const totalExpenseExposure = totalGeneralExpenses.toNumber() + totalMaterialPurchases;

    // 3. Profit & Cash Flow
    // Realized Net Profit = totalSalesValue - totalExpenseExposure
    // Net Cash Flow = totalCollected - (totalGeneralExpenses + totalSupplierPaid)
    const netCompanyProfit = totalSalesValue.toNumber() - totalExpenseExposure;
    const netCashFlow = totalCollected - (totalGeneralExpenses.toNumber() + totalSupplierPaid);

    // 4. Partner Ledger Rows & Settlements
    const partnerLedgerRows = this.calculatePartnerLedgers({
      partners,
      expenses,
      materialExpenses,
      supplierPayments,
      ledgerEntries,
    });

    const settlements = this.calculateSettlements(partners, expenses);

    return {
      totalSalesValue: totalSalesValue.toNumber(),
      totalCollected,
      totalOutstandingReceivables,
      totalGeneralExpenses: totalGeneralExpenses.toNumber(),
      totalMaterialPurchases,
      totalExpenseExposure,
      totalSupplierPaid,
      totalSupplierDuesPayable,
      netCompanyProfit,
      netCashFlow,
      partnerLedgerRows,
      settlements,
    };
  }
}
