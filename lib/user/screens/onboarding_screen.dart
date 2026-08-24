import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/theme/mazonn_colors.dart';
import '../../../core/theme/mazonn_metrics.dart';
import '../../../shared/controllers/auth_controller.dart';
import '../../../shared/widgets/mazonn_button.dart';
import '../../../shared/widgets/mazonn_visual.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;

  static const _pages = [
    (
      title: 'Objects with intention',
      body: 'A considered edit of fashion, home, and ritual — chosen for material, not noise.',
      seed: 2,
      category: 'fashion',
    ),
    (
      title: 'From atelier to door',
      body: 'Independent makers, transparent details, and delivery that treats every piece as if it were yours.',
      seed: 9,
      category: 'home',
    ),
    (
      title: 'Yours, quietly',
      body: 'Save favorites, track orders, and shop a Mazonn that remembers how you live.',
      seed: 13,
      category: 'beauty',
    ),
  ];

  Future<void> _finish() async {
    await context.read<AuthController>().completeOnboarding();
    if (mounted) context.go(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: Text('Skip', style: Theme.of(context).textTheme.labelLarge),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _page,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final page = _pages[i];
                    return Column(
                      children: [
                        Expanded(
                          child: MazonnVisual(
                            seed: page.seed,
                            categoryId: page.category,
                            monogram: 'M',
                            borderRadius: BorderRadius.circular(MazonnRadius.lg),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page.body,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: MazonnColors.stone,
                              ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    width: active ? 22 : 6,
                    decoration: BoxDecoration(
                      color: active ? MazonnColors.noir : MazonnColors.linen,
                      borderRadius: MazonnRadius.pillAll,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              MazonnButton(
                label: last ? 'Get started' : 'Next',
                onPressed: () {
                  if (last) {
                    _finish();
                  } else {
                    _page.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
