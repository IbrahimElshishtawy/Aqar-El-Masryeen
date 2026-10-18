import { NextRequest, NextResponse } from 'next/server';
import { SessionService } from '@/lib/auth/session';

// Protected accounting routes
const PROTECTED_PREFIXES = [
  '/dashboard',
  '/properties',
  '/installments',
  '/expenses',
  '/partners',
  '/reports',
  '/price-monitoring',
  '/api/accounting',
  '/api/price-monitoring',
];

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Check if requested path is protected
  const isProtected = PROTECTED_PREFIXES.some(prefix => pathname.startsWith(prefix));
  if (!isProtected) {
    return NextResponse.next();
  }

  // Get session cookie
  const sessionCookie = request.cookies.get(SessionService.cookieName)?.value;

  if (!sessionCookie) {
    // If API route, return 401 JSON
    if (pathname.startsWith('/api/')) {
      return NextResponse.json(
        { error: 'غير مصرح لك، يرجى تسجيل الدخول أولاً' },
        { status: 401 }
      );
    }

    // For web pages, redirect to dedicated accounting login
    const loginUrl = new URL('/accounting/login', request.url);
    loginUrl.searchParams.set('redirect', pathname);
    return NextResponse.redirect(loginUrl);
  }

  // Verify session token
  const session = await SessionService.verifyToken(sessionCookie);
  if (!session) {
    if (pathname.startsWith('/api/')) {
      return NextResponse.json(
        { error: 'جلسة العمل غير صالحة أو منتهية، يرجى تسجيل الدخول مجدداً' },
        { status: 401 }
      );
    }

    const loginUrl = new URL('/accounting/login', request.url);
    loginUrl.searchParams.set('redirect', pathname);
    loginUrl.searchParams.set('expired', 'true');
    const response = NextResponse.redirect(loginUrl);
    response.cookies.delete(SessionService.cookieName);
    return response;
  }

  // Role-based restrictions:
  // If user role is 'viewer' and they try to mutate via POST/PUT/DELETE
  if (session.role === 'viewer' && ['POST', 'PUT', 'DELETE', 'PATCH'].includes(request.method)) {
    return NextResponse.json(
      { error: 'حساب المشاهدة للقراءة فقط، ليس لديك صلاحية لإجراء تعديلات' },
      { status: 403 }
    );
  }

  // Pass user role and uid in request headers for downstream server components
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set('x-user-uid', session.uid);
  requestHeaders.set('x-user-role', session.role);
  requestHeaders.set('x-user-email', session.email);
  if (session.partnerId) {
    requestHeaders.set('x-user-partner-id', session.partnerId);
  }

  return NextResponse.next({
    request: {
      headers: requestHeaders,
    },
  });
}

export const config = {
  matcher: [
    '/dashboard/:path*',
    '/properties/:path*',
    '/installments/:path*',
    '/expenses/:path*',
    '/partners/:path*',
    '/reports/:path*',
    '/price-monitoring/:path*',
    '/api/accounting/:path*',
    '/api/price-monitoring/:path*',
  ],
};
