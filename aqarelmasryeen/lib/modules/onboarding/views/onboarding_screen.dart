import 'package:aqarelmasryeen/app/routes/app_routes.dart';
import 'package:aqarelmasryeen/core/services/session_service.dart';
import 'package:aqarelmasryeen/core/theme/app_spacing.dart';
import 'package:aqarelmasryeen/shared/widgets/app_button.dart';
import 'package:aqarelmasryeen/shared/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pageAnimationDuration = Duration(milliseconds: 420);
  static const _pageAnimationCurve = Curves.easeOutCubic;

  final PageController _pageController = PageController();
  late final SessionService _sessionService;

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _sessionService = Get.find<SessionService>();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToNextPage(int lastPage) async {
    if (_currentPage >= lastPage) {
      await _completeOnboarding();
      return;
    }

    await _pageController.nextPage(
      duration: _pageAnimationDuration,
      curve: _pageAnimationCurve,
    );
  }

  Future<void> _completeOnboarding() async {
    await _sessionService.markOnboardingSeen();
    if (!mounted) {
      return;
    }
    Get.offAllNamed(AppRoutes.login);
  }

  List<_OnboardingSlideData> _slidesFor(BuildContext context) {
    final locale = Get.locale ?? Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';

    if (isArabic) {
      return const [
        _OnboardingSlideData(
          accentColor: Color(0xFF1976D2),
          badge: 'تجربة جوال احترافية',
          title: 'أدر عملياتك العقارية من هاتفك بثقة ووضوح',
          subtitle:
              'واجهة بيضاء أنيقة مع تدفق واضح للمهام اليومية، لتبقى الأرقام والتحديثات المهمة في متناولك طوال الوقت.',
          heroLabel: 'وصول فوري',
          metricValue: '24/7',
          metricLabel: 'إدارة ومتابعة في أي وقت',
          highlights: [
            _SlideHighlight(
              icon: Icons.dashboard_customize_rounded,
              label: 'لوحة تحكم سهلة القراءة على الهاتف',
            ),
            _SlideHighlight(
              icon: Icons.swipe_rounded,
              label: 'تنقل سلس بين الخطوات والشاشات',
            ),
            _SlideHighlight(
              icon: Icons.trending_up_rounded,
              label: 'مؤشرات واضحة تساعدك على اتخاذ القرار',
            ),
          ],
        ),
        _OnboardingSlideData(
          accentColor: Color(0xFF1565C0),
          badge: 'متابعة أسرع',
          title: 'تابع المبيعات والتحصيل والتنبيهات لحظة بلحظة',
          subtitle:
              'كل تحديث مهم يظهر أمامك داخل تجربة متوازنة بصرياً، مع عناصر متحركة ناعمة تعطي إحساساً سريعاً وحديثاً.',
          heroLabel: 'إشعارات ذكية',
          metricValue: '3s',
          metricLabel: 'وصول أسرع للمعلومات المهمة',
          highlights: [
            _SlideHighlight(
              icon: Icons.notifications_active_rounded,
              label: 'تنبيهات مهمة عند حدوث أي تحديث',
            ),
            _SlideHighlight(
              icon: Icons.groups_rounded,
              label: 'رؤية أوضح لحركة الفريق والعملاء',
            ),
            _SlideHighlight(
              icon: Icons.insights_rounded,
              label: 'ملخصات سريعة تدعم المتابعة اليومية',
            ),
          ],
        ),
        _OnboardingSlideData(
          accentColor: Color(0xFF1E88E5),
          badge: 'تسجيل آمن',
          title: 'ابدأ برقم هاتفك مع تجربة تحقق جاهزة للجوال',
          subtitle:
              'مسار دخول احترافي يهيئ المستخدمين لخطوات التحقق بسهولة، مع دعم جيد للاتجاه من اليمين إلى اليسار منذ البداية.',
          heroLabel: 'رمز تحقق',
          metricValue: '100%',
          metricLabel: 'تجربة مهيأة للشاشات الصغيرة',
          highlights: [
            _SlideHighlight(
              icon: Icons.verified_user_rounded,
              label: 'تجربة تحقق أكثر وضوحاً وموثوقية',
            ),
            _SlideHighlight(
              icon: Icons.phone_android_rounded,
              label: 'تصميم مريح ومناسب لكل المقاسات',
            ),
            _SlideHighlight(
              icon: Icons.compare_arrows_rounded,
              label: 'جاهز للتعامل مع LTR و RTL',
            ),
          ],
        ),
      ];
    }

    return const [
      _OnboardingSlideData(
        accentColor: Color(0xFF1976D2),
        badge: 'Professional mobile UX',
        title: 'Run your property operations from your phone with confidence',
        subtitle:
            'A polished white interface with focused blue accents keeps your key numbers, daily actions, and team updates easy to reach.',
        heroLabel: 'Instant access',
        metricValue: '24/7',
        metricLabel: 'Manage and monitor anywhere',
        highlights: [
          _SlideHighlight(
            icon: Icons.dashboard_customize_rounded,
            label: 'Phone-first dashboard layout',
          ),
          _SlideHighlight(
            icon: Icons.swipe_rounded,
            label: 'Smooth step-by-step navigation',
          ),
          _SlideHighlight(
            icon: Icons.trending_up_rounded,
            label: 'Clear signals for faster decisions',
          ),
        ],
      ),
      _OnboardingSlideData(
        accentColor: Color(0xFF1565C0),
        badge: 'Faster follow-up',
        title: 'Stay on top of sales, collections, and alerts in real time',
        subtitle:
            'Important updates surface inside a balanced, modern experience with motion that feels smooth without getting in the way.',
        heroLabel: 'Smart alerts',
        metricValue: '3s',
        metricLabel: 'Faster access to what matters',
        highlights: [
          _SlideHighlight(
            icon: Icons.notifications_active_rounded,
            label: 'Actionable notifications',
          ),
          _SlideHighlight(
            icon: Icons.groups_rounded,
            label: 'Better visibility across the team',
          ),
          _SlideHighlight(
            icon: Icons.insights_rounded,
            label: 'Quick summaries for daily follow-up',
          ),
        ],
      ),
      _OnboardingSlideData(
        accentColor: Color(0xFF1E88E5),
        badge: 'Secure sign-in',
        title: 'Start with your phone number in a polished mobile-ready flow',
        subtitle:
            'A clear onboarding journey prepares users for secure verification and a frictionless entry experience with RTL readiness built in.',
        heroLabel: 'OTP ready',
        metricValue: '100%',
        metricLabel: 'Optimized for compact screens',
        highlights: [
          _SlideHighlight(
            icon: Icons.verified_user_rounded,
            label: 'Clearer verification moments',
          ),
          _SlideHighlight(
            icon: Icons.phone_android_rounded,
            label: 'Comfortable layout on small devices',
          ),
          _SlideHighlight(
            icon: Icons.compare_arrows_rounded,
            label: 'Ready for LTR and RTL',
          ),
        ],
      ),
    ];
  }

  String _nextLabel(BuildContext context) {
    final locale = Get.locale ?? Localizations.localeOf(context);
    return locale.languageCode == 'ar' ? 'التالي' : 'Next';
  }

  IconData _forwardIconFor(TextDirection direction) {
    return direction == TextDirection.rtl
        ? Icons.arrow_back_rounded
        : Icons.arrow_forward_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slidesFor(context);
    final textDirection = Directionality.of(context);
    final currentSlide = slides[_currentPage];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompactHeight = constraints.maxHeight < 760;
            final horizontalPadding = constraints.maxWidth < 380
                ? AppSpacing.md
                : AppSpacing.lg;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.md,
                horizontalPadding,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppLogo(showText: constraints.maxWidth > 360),
                      ),
                      if (constraints.maxWidth > 380)
                        Flexible(
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              transitionBuilder: (child, animation) {
                                final offset = Tween<Offset>(
                                  begin: const Offset(0, -0.12),
                                  end: Offset.zero,
                                ).animate(animation);
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: offset,
                                    child: child,
                                  ),
                                );
                              },
                              child: Container(
                                key: ValueKey(currentSlide.badge),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: currentSlide.accentColor.withOpacity(
                                    0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: currentSlide.accentColor.withOpacity(
                                      0.14,
                                    ),
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.phone_android_rounded,
                                        size: 18,
                                        color: currentSlide.accentColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        currentSlide.badge,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              color: currentSlide.accentColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: isCompactHeight ? 18 : 26),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: slides.length,
                      onPageChanged: (value) {
                        if (_currentPage == value) {
                          return;
                        }
                        setState(() => _currentPage = value);
                      },
                      itemBuilder: (context, index) {
                        return AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            var page = _currentPage.toDouble();
                            if (_pageController.hasClients) {
                              final controllerPage = _pageController.page;
                              if (controllerPage != null) {
                                page = controllerPage;
                              }
                            }

                            final pageDelta = page - index;
                            final distance = pageDelta.abs().clamp(0.0, 1.0);

                            return _OnboardingSlide(
                              data: slides[index],
                              isActive: index == _currentPage,
                              distance: distance,
                              pageDelta: pageDelta,
                              isCompactHeight: isCompactHeight,
                              textDirection: textDirection,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: isCompactHeight ? 12 : 18),
                  _PageIndicators(
                    itemCount: slides.length,
                    currentIndex: _currentPage,
                    activeColor: currentSlide.accentColor,
                  ),
                  SizedBox(height: isCompactHeight ? 16 : 24),
                  _OnboardingActionBar(
                    showShortcut: _currentPage < slides.length - 1,
                    nextLabel: _nextLabel(context),
                    getStartedLabel: 'get_started'.tr,
                    forwardIcon: _forwardIconFor(textDirection),
                    onNext: () => _goToNextPage(slides.length - 1),
                    onGetStarted: _completeOnboarding,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.data,
    required this.isActive,
    required this.distance,
    required this.pageDelta,
    required this.isCompactHeight,
    required this.textDirection,
  });

  final _OnboardingSlideData data;
  final bool isActive;
  final double distance;
  final double pageDelta;
  final bool isCompactHeight;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    final opacity = (1 - (distance * 0.55)).clamp(0.0, 1.0);
    final horizontalShift = pageDelta * 34;
    final verticalShift = distance * 14;

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(horizontalShift, verticalShift),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OnboardingHero(
                    data: data,
                    isActive: isActive,
                    distance: distance,
                    isCompactHeight: isCompactHeight,
                    textDirection: textDirection,
                  ),
                  SizedBox(height: isCompactHeight ? 24 : 32),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: isActive ? 1 : 0.88,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: data.accentColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        data.badge,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: data.accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isCompactHeight ? 16 : 20),
                  Text(
                    data.title,
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    data.subtitle,
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF5B6474),
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: isCompactHeight ? 20 : 24),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: data.highlights
                        .map(
                          (item) => _FeatureChip(
                            accentColor: data.accentColor,
                            icon: item.icon,
                            label: item.label,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingHero extends StatelessWidget {
  const _OnboardingHero({
    required this.data,
    required this.isActive,
    required this.distance,
    required this.isCompactHeight,
    required this.textDirection,
  });

  final _OnboardingSlideData data;
  final bool isActive;
  final double distance;
  final bool isCompactHeight;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    final heroHeight = isCompactHeight ? 288.0 : 340.0;
    final phoneCardSize = isCompactHeight ? 152.0 : 176.0;
    final ringScale = 1 - (distance * 0.08);

    return SizedBox(
      height: heroHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                gradient: LinearGradient(
                  colors: [
                    data.accentColor.withOpacity(0.12),
                    const Color(0xFFFDFEFF),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border.all(color: data.accentColor.withOpacity(0.12)),
                boxShadow: [
                  BoxShadow(
                    color: data.accentColor.withOpacity(0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 22,
            left: textDirection == TextDirection.ltr ? 18 : null,
            right: textDirection == TextDirection.rtl ? 18 : null,
            child: _FloatingPill(
              accentColor: data.accentColor,
              icon: Icons.wifi_tethering_rounded,
              label: data.heroLabel,
            ),
          ),
          Positioned(
            top: 36,
            right: textDirection == TextDirection.ltr ? 28 : null,
            left: textDirection == TextDirection.rtl ? 28 : null,
            child: _DecorativeOrb(
              color: data.accentColor.withOpacity(0.18),
              size: 18,
            ),
          ),
          Positioned(
            bottom: 26,
            right: textDirection == TextDirection.ltr ? 18 : null,
            left: textDirection == TextDirection.rtl ? 18 : null,
            child: _MetricCard(
              accentColor: data.accentColor,
              value: data.metricValue,
              label: data.metricLabel,
            ),
          ),
          Positioned(
            bottom: 54,
            left: textDirection == TextDirection.ltr ? 32 : null,
            right: textDirection == TextDirection.rtl ? 32 : null,
            child: _DecorativeOrb(
              color: data.accentColor.withOpacity(0.1),
              size: 26,
            ),
          ),
          Center(
            child: TweenAnimationBuilder<double>(
              key: ValueKey('${data.title}_$isActive'),
              tween: Tween<double>(begin: 0.92, end: isActive ? 1 : 0.97),
              duration: const Duration(milliseconds: 760),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale * ringScale, child: child);
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: phoneCardSize * 1.55,
                    height: phoneCardSize * 1.55,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: data.accentColor.withOpacity(0.14),
                        width: 1.5,
                      ),
                    ),
                  ),
                  Container(
                    width: phoneCardSize * 1.24,
                    height: phoneCardSize * 1.24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: data.accentColor.withOpacity(0.06),
                    ),
                  ),
                  Container(
                    width: phoneCardSize,
                    height: phoneCardSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      gradient: LinearGradient(
                        colors: [
                          data.accentColor,
                          data.accentColor.withOpacity(0.84),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: data.accentColor.withOpacity(0.26),
                          blurRadius: 30,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.smartphone_rounded,
                          color: Colors.white,
                          size: 74,
                        ),
                        const Spacer(),
                        Container(
                          width: 52,
                          height: 6,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.28),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.accentColor,
    required this.icon,
    required this.label,
  });

  final Color accentColor;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF243042),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingPill extends StatelessWidget {
  const _FloatingPill({
    required this.accentColor,
    required this.icon,
    required this.label,
  });

  final Color accentColor;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFF1F2A3D),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.accentColor,
    required this.value,
    required this.label,
  });

  final Color accentColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF5B6474),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeOrb extends StatelessWidget {
  const _DecorativeOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _PageIndicators extends StatelessWidget {
  const _PageIndicators({
    required this.itemCount,
    required this.currentIndex,
    required this.activeColor,
  });

  final int itemCount;
  final int currentIndex;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: isActive ? 28 : 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? activeColor : activeColor.withOpacity(0.18),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _OnboardingActionBar extends StatelessWidget {
  const _OnboardingActionBar({
    required this.showShortcut,
    required this.nextLabel,
    required this.getStartedLabel,
    required this.forwardIcon,
    required this.onNext,
    required this.onGetStarted,
  });

  final bool showShortcut;
  final String nextLabel;
  final String getStartedLabel;
  final IconData forwardIcon;
  final Future<void> Function() onNext;
  final Future<void> Function() onGetStarted;

  @override
  Widget build(BuildContext context) {
    if (!showShortcut) {
      return AppButton(
        label: getStartedLabel,
        icon: Icon(forwardIcon),
        onPressed: () => onGetStarted(),
      );
    }

    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: getStartedLabel,
            variant: AppButtonVariant.secondary,
            onPressed: () => onGetStarted(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            label: nextLabel,
            icon: Icon(forwardIcon),
            onPressed: () => onNext(),
          ),
        ),
      ],
    );
  }
}

class _OnboardingSlideData {
  const _OnboardingSlideData({
    required this.accentColor,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.heroLabel,
    required this.metricValue,
    required this.metricLabel,
    required this.highlights,
  });

  final Color accentColor;
  final String badge;
  final String title;
  final String subtitle;
  final String heroLabel;
  final String metricValue;
  final String metricLabel;
  final List<_SlideHighlight> highlights;
}

class _SlideHighlight {
  const _SlideHighlight({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
