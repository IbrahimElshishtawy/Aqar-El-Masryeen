// Decimal-safe financial calculation utilities
// Prevents binary floating point IEEE 754 precision issues (e.g. 0.1 + 0.2 = 0.30000000000000004)

export class Money {
  private readonly cents: bigint;

  constructor(amount: number | string | bigint, fromCents = false) {
    if (fromCents) {
      this.cents = BigInt(amount);
    } else if (typeof amount === 'bigint') {
      this.cents = amount * BigInt(100);
    } else {
      const num = typeof amount === 'string' ? parseFloat(amount) : amount;
      if (isNaN(num) || !isFinite(num)) {
        this.cents = BigInt(0);
      } else {
        // Round to 2 decimal places to avoid fraction precision drift
        this.cents = BigInt(Math.round(num * 100));
      }
    }
  }

  static from(amount: number | string | bigint): Money {
    return new Money(amount);
  }

  static fromCents(cents: bigint | number): Money {
    return new Money(cents, true);
  }

  static zero(): Money {
    return new Money(BigInt(0), true);
  }

  plus(other: Money | number): Money {
    const o = other instanceof Money ? other : Money.from(other);
    return Money.fromCents(this.cents + o.cents);
  }

  minus(other: Money | number): Money {
    const o = other instanceof Money ? other : Money.from(other);
    return Money.fromCents(this.cents - o.cents);
  }

  multiply(factor: number): Money {
    if (isNaN(factor) || !isFinite(factor)) return Money.zero();
    const result = Math.round(Number(this.cents) * factor);
    return Money.fromCents(BigInt(result));
  }

  divide(divisor: number): Money {
    if (!divisor || isNaN(divisor) || !isFinite(divisor)) return Money.zero();
    const result = Math.round(Number(this.cents) / divisor);
    return Money.fromCents(BigInt(result));
  }

  toNumber(): number {
    return Number(this.cents) / 100;
  }

  toCents(): bigint {
    return this.cents;
  }

  format(currency = 'ج.م'): string {
    const formatted = this.toNumber().toLocaleString('ar-EG', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    });
    return `${formatted} ${currency}`;
  }

  formatEn(currency = 'EGP'): string {
    const formatted = this.toNumber().toLocaleString('en-US', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    });
    return `${formatted} ${currency}`;
  }

  isPositive(): boolean {
    return this.cents > BigInt(0);
  }

  isNegative(): boolean {
    return this.cents < BigInt(0);
  }

  isZero(): boolean {
    return this.cents === BigInt(0);
  }

  abs(): Money {
    return this.cents < BigInt(0) ? Money.fromCents(-this.cents) : this;
  }
}

export function roundToTwoDecimals(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}
