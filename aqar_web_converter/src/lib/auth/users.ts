import { AuthUserSession, AccountRole } from '@/types';

export interface SystemUser extends AuthUserSession {
  passwordHash: string;
  salt: string;
}

// Generate salted hash using Web Crypto SHA-256
export async function hashPassword(password: string, salt: string): Promise<string> {
  const enc = new TextEncoder();
  const data = enc.encode(`${salt}:${password}`);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

// Known authorized users for the accounting system
// Matching Firebase Auth & Firestore profiles
export const authorizedUsers: Array<{
  uid: string;
  email: string;
  fullName: string;
  role: AccountRole;
  partnerId?: string;
  workspaceId: string;
  salt: string;
  // Pre-hashed passwords for test/seed accounts (Password for all seed accounts: "Aqar@2026Secure")
  // Hash generated via hashPassword("Aqar@2026Secure", salt)
  passwordHash: string;
}> = [
  {
    uid: 'uid-admin-01',
    email: 'admin@aqarelmasryeen.com',
    fullName: 'الحاج إبراهيم الشيشتاوي (مدير المنظومة)',
    role: 'admin',
    partnerId: 'partner-1',
    workspaceId: 'main-ws',
    salt: 'salt_admin_8841',
    // SHA256 of "salt_admin_8841:Aqar@2026Secure"
    passwordHash: '52d36137205729e6073a82ed88dea1d12e62ea1bc80fc4b9cc3f91771c9bd99e',
  },
  {
    uid: 'uid-accountant-01',
    email: 'accountant@aqarelmasryeen.com',
    fullName: 'أ. طارق الشربيني (رئيس الحسابات)',
    role: 'accountant',
    workspaceId: 'main-ws',
    salt: 'salt_acc_9012',
    // SHA256 of "salt_acc_9012:Aqar@2026Secure"
    passwordHash: 'b7552f74041ee5a1f0f6d116f952530b460a53bd8ea50b18efdfa63aa8e92686',
  },
  {
    uid: 'uid-partner-02',
    email: 'hossam.ghanem@aqarelmasryeen.com',
    fullName: 'م. حسام الدين غانم (شريك بنسبة 40%)',
    role: 'partner',
    partnerId: 'partner-2',
    workspaceId: 'main-ws',
    salt: 'salt_partner_4412',
    // SHA256 of "salt_partner_4412:Aqar@2026Secure"
    passwordHash: '4e2eb7815d5c8a917f8fb353dcfaf5aa6caa504666f0105e08f75ff13651a49b',
  },
  {
    uid: 'uid-viewer-01',
    email: 'viewer@aqarelmasryeen.com',
    fullName: 'مراقب حسابات ومستثمر (مشاهدة فقط)',
    role: 'viewer',
    workspaceId: 'main-ws',
    salt: 'salt_viewer_1029',
    // SHA256 of "salt_viewer_1029:Aqar@2026Secure"
    passwordHash: '9007e1d67c8b6d9b4d47f5c81085606b6e19ea9953dac062baa6041cbba17e8a',
  },
];

export async function verifyUserCredentials(email: string, password: string): Promise<AuthUserSession | null> {
  const normalizedEmail = email.trim().toLowerCase();
  const user = authorizedUsers.find(u => u.email.toLowerCase() === normalizedEmail);
  if (!user) return null;

  const inputHash = await hashPassword(password, user.salt);
  if (inputHash !== user.passwordHash) {
    return null;
  }

  return {
    uid: user.uid,
    email: user.email,
    fullName: user.fullName,
    role: user.role,
    partnerId: user.partnerId,
    workspaceId: user.workspaceId,
  };
}
