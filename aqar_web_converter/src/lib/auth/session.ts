// Server-side session management and role-based access control (RBAC)
import { AccountRole, AuthUserSession } from '@/types';

const SESSION_COOKIE_NAME = 'aqar_accounting_session';
const SESSION_SECRET = process.env.ACCOUNTING_SESSION_SECRET || 'aqar-el-masryeen-secure-accounting-jwt-key-2026';

export interface TokenPayload extends AuthUserSession {
  exp: number; // Expiration timestamp in seconds
  iat: number; // Issued at timestamp in seconds
}

// Convert string to Uint8Array
function stringToUint8Array(str: string): Uint8Array {
  return new TextEncoder().encode(str);
}

// Base64Url encode
function base64UrlEncode(data: Uint8Array): string {
  let str = '';
  for (let i = 0; i < data.length; i++) {
    str += String.fromCharCode(data[i]);
  }
  return btoa(str).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

// Base64Url decode
function base64UrlDecode(str: string): Uint8Array {
  str = str.replace(/-/g, '+').replace(/_/g, '/');
  while (str.length % 4) {
    str += '=';
  }
  const binary = atob(str);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

// Generate HMAC-SHA256 signature
async function sign(message: string, secret: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    'raw',
    stringToUint8Array(secret) as unknown as BufferSource,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );
  const signature = await crypto.subtle.sign('HMAC', key, stringToUint8Array(message) as unknown as BufferSource);
  return base64UrlEncode(new Uint8Array(signature));
}

// Verify HMAC-SHA256 signature
async function verify(message: string, signature: string, secret: string): Promise<boolean> {
  const expectedSig = await sign(message, secret);
  return expectedSig === signature;
}

export class SessionService {
  static get cookieName(): string {
    return SESSION_COOKIE_NAME;
  }

  /**
   * Creates a signed session token
   */
  static async createToken(user: AuthUserSession, expiresInHours = 24): Promise<string> {
    const now = Math.floor(Date.now() / 1000);
    const payload: TokenPayload = {
      ...user,
      iat: now,
      exp: now + expiresInHours * 3600,
    };

    const header = { alg: 'HS256', typ: 'JWT' };
    const encodedHeader = base64UrlEncode(stringToUint8Array(JSON.stringify(header)));
    const encodedPayload = base64UrlEncode(stringToUint8Array(JSON.stringify(payload)));
    const message = `${encodedHeader}.${encodedPayload}`;
    const signature = await sign(message, SESSION_SECRET);

    return `${message}.${signature}`;
  }

  /**
   * Verifies and decodes a session token
   */
  static async verifyToken(token: string): Promise<TokenPayload | null> {
    try {
      const parts = token.split('.');
      if (parts.length !== 3) return null;

      const [encodedHeader, encodedPayload, signature] = parts;
      const message = `${encodedHeader}.${encodedPayload}`;

      const isValid = await verify(message, signature, SESSION_SECRET);
      if (!isValid) return null;

      const decodedBytes = base64UrlDecode(encodedPayload);
      const payloadString = new TextDecoder().decode(decodedBytes);
      const payload: TokenPayload = JSON.parse(payloadString);

      const now = Math.floor(Date.now() / 1000);
      if (payload.exp && payload.exp < now) {
        return null; // Expired session
      }

      return payload;
    } catch {
      return null;
    }
  }

  /**
   * Role-based permissions matrix
   */
  static hasPermission(
    role: AccountRole,
    action:
      | 'view_all_accounting'
      | 'view_own_partner_ledger'
      | 'manage_expenses'
      | 'manage_installments'
      | 'manage_partners'
      | 'manage_price_monitoring'
      | 'approve_settlements'
      | 'manage_users'
  ): boolean {
    switch (role) {
      case 'admin':
        return true; // Admin can perform all operations

      case 'accountant':
        // Accountants can manage financial operations and view accounting, but cannot alter partners or users
        return (
          action === 'view_all_accounting' ||
          action === 'view_own_partner_ledger' ||
          action === 'manage_expenses' ||
          action === 'manage_installments' ||
          action === 'manage_price_monitoring'
        );

      case 'partner':
        // Partners can only view their own financial records and general price metrics
        return (
          action === 'view_own_partner_ledger' ||
          action === 'manage_price_monitoring'
        );

      case 'viewer':
        return action === 'manage_price_monitoring';

      default:
        return false;
    }
  }
}
