import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_scaffold.dart';
import '../../core/utils/haptics.dart';
import 'onboarding_controller.dart';
import 'widgets/onboarding_page_indicator.dart';
import 'widgets/permissions_step_view.dart';
import 'widgets/ready_step_view.dart';
import 'widgets/setup_step_view.dart';
import 'widgets/welcome_step_view.dart';

/// Full-screen interactive wizard guiding first-time users through value propositions,
/// Android platform permissions, quick preferences, and foreground service setup.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({
    super.key,
    this.isReplay = false,
  });

  /// Whether this screen was opened from Settings to replay the walkthrough.
  final bool isReplay;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      // User returned from system settings -> automatically refresh permission statuses
      ref.read(onboardingControllerProvider.notifier).refreshPermissionStatuses();
    }
  }

  void _goToPage(int page) {
    AppHaptics.selectionTick();
    ref.read(onboardingControllerProvider.notifier).setPage(page);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _handleFinish() async {
    AppHaptics.contextClick();
    final controller = ref.read(onboardingControllerProvider.notifier);
    await controller.completeOnboarding();

    if (!mounted) return;

    if (widget.isReplay) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppScaffold()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.isReplay || state.currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  if (state.currentPage > 0) {
                    _goToPage(state.currentPage - 1);
                  } else if (widget.isReplay) {
                    Navigator.of(context).pop();
                  }
                },
              )
            : null,
        actions: [
          if (state.currentPage < state.totalPages - 1) ...[
            TextButton(
              onPressed: () {
                AppHaptics.selectionTick();
                _goToPage(state.totalPages - 1);
              },
              child: const Text('Skip'),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // PageView Carousel
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  controller.setPage(index);
                },
                children: [
                  const WelcomeStepView(),
                  PermissionsStepView(
                    state: state,
                    controller: controller,
                  ),
                  SetupStepView(
                    state: state,
                    controller: controller,
                  ),
                  ReadyStepView(
                    state: state,
                    onLaunch: _handleFinish,
                  ),
                ],
              ),
            ),

            // Bottom Navigation Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Dots
                  OnboardingPageIndicator(
                    currentPage: state.currentPage,
                    pageCount: state.totalPages,
                  ),

                  // Action Button
                  if (state.currentPage < state.totalPages - 1) ...[
                    FilledButton.icon(
                      onPressed: () {
                        _goToPage(state.currentPage + 1);
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text(
                        state.currentPage == 0 ? 'Get Started' : 'Continue',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ] else ...[
                    FilledButton.icon(
                      onPressed: state.isCompleting ? null : _handleFinish,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text(
                        'Start Using ByteMeter',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
