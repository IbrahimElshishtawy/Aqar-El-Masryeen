import { NextRequest, NextResponse } from 'next/server';
import { verifyUserCredentials } from '@/lib/auth/users';
import { SessionService } from '@/lib/auth/session';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { email, password } = body;

    if (!email || !password) {
      return NextResponse.json(
        { error: 'البريد الإلكتروني وكلمة المرور مطلوبة' },
        { status: 400 }
      );
    }

    const user = await verifyUserCredentials(email, password);
    if (!user) {
      return NextResponse.json(
        { error: 'بيانات الدخول غير صحيحة، يرجى التأكد من البريد الإلكتروني وكلمة المرور' },
        { status: 401 }
      );
    }

    const token = await SessionService.createToken(user, 24); // 24 hours

    const response = NextResponse.json({
      success: true,
      user: {
        uid: user.uid,
        email: user.email,
        fullName: user.fullName,
        role: user.role,
        partnerId: user.partnerId,
        workspaceId: user.workspaceId,
      },
    });

    response.cookies.set({
      name: SessionService.cookieName,
      value: token,
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      path: '/',
      maxAge: 24 * 60 * 60, // 24 hours
    });

    return response;
  } catch (error) {
    console.error('Login error:', error);
    return NextResponse.json(
      { error: 'حدث خطأ أثناء معالجة تسجيل الدخول' },
      { status: 500 }
    );
  }
}
