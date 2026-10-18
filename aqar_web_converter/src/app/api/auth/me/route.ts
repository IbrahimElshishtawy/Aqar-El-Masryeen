import { NextRequest, NextResponse } from 'next/server';
import { SessionService } from '@/lib/auth/session';

export async function GET(request: NextRequest) {
  const token = request.cookies.get(SessionService.cookieName)?.value;
  if (!token) {
    return NextResponse.json({ authenticated: false }, { status: 401 });
  }

  const session = await SessionService.verifyToken(token);
  if (!session) {
    return NextResponse.json({ authenticated: false }, { status: 401 });
  }

  return NextResponse.json({
    authenticated: true,
    user: {
      uid: session.uid,
      email: session.email,
      fullName: session.fullName,
      role: session.role,
      partnerId: session.partnerId,
      workspaceId: session.workspaceId,
    },
  });
}
