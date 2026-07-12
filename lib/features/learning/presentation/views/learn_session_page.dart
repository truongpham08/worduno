import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_navigation_widgets.dart';
import '../../../../core/tts/presentation/speak_term.dart';
import '../../../../shared/vocabulary/domain/entities/term.dart';
import '../viewmodels/learn_session_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page entry point — owns ViewModel lifecycle
// ─────────────────────────────────────────────────────────────────────────────

class LearnSessionPage extends StatefulWidget {
  const LearnSessionPage({
    super.key,
    required this.levelCode,
    required this.unitName,
    this.unitId,
    this.initialTermId,
  });

  final String levelCode;
  final String unitName;
  final String? unitId;
  final String? initialTermId;

  @override
  State<LearnSessionPage> createState() => _LearnSessionPageState();
}

class _LearnSessionPageState extends State<LearnSessionPage> {
  late final LearnSessionViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = LearnSessionViewModel(
      levelCode: widget.levelCode,
      unitName: widget.unitName,
      unitId: widget.unitId,
      initialTermId: widget.initialTermId,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadSession();
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LearnSessionViewModel>.value(
      value: _viewModel,
      child: const _LearnSessionView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// View
// ─────────────────────────────────────────────────────────────────────────────

class _LearnSessionView extends StatefulWidget {
  const _LearnSessionView();

  @override
  State<_LearnSessionView> createState() => _LearnSessionViewState();
}

class _LearnSessionViewState extends State<_LearnSessionView> {
  String? _markAnim;
  double _dragDx = 0;

  Future<void> _speak(String text) => speakTermWithFeedback(context, text);

  Future<void> _markWithAnim(
    LearnSessionViewModel vm,
    Future<void> Function() action,
    String direction,
  ) async {
    if (_markAnim != null) return;
    setState(() => _markAnim = direction);
    await Future<void>.delayed(const Duration(milliseconds: 380));
    if (!mounted) return;
    await action();
    if (!mounted) return;
    setState(() => _markAnim = null);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LearnSessionViewModel>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: vm.isLoading
            ? const AppLoading(message: 'Loading session...')
            : vm.errorMessage != null
                ? AppErrorView(
                    message: vm.errorMessage!,
                    onRetry: vm.loadSession,
                  )
                : vm.isEmptySession
                    ? _buildEmptyScreen(context)
                    : vm.isCompleted
                        ? _buildCompletionScreen(context, vm)
                        : _buildSessionScreen(context, vm),
      ),
    );
  }

  Widget _buildCompletionScreen(BuildContext context, LearnSessionViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
                boxShadow: AppDecorations.shadowMd,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 50,
                color: AppColors.greenDark,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Congratulations!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "You've completed this learn session! Go back to vocabulary list to see your progress.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.mid,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 32),
            _ScaleButton(
              onTap: () {
                AppBackButton.handleDefaultBack(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: AppDecorations.pillButton(AppColors.greenDark),
                child: const Center(
                  child: Text(
                    'Back to List',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Empty screen (unit has no terms)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildEmptyScreen(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No terms available to learn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.mid,
              ),
            ),
            const SizedBox(height: 20),
            _ScaleButton(
              onTap: () {
                AppBackButton.handleDefaultBack(context);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.greenDark,
                  borderRadius:
                      BorderRadius.circular(AppDecorations.radiusSm),
                ),
                child: const Text(
                  'Back to List',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Session screen
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildSessionScreen(BuildContext context, LearnSessionViewModel vm) {
    final currentTerm = vm.currentTerm;
    if (currentTerm == null) {
      return const Center(
        child: Text('No terms available to learn.'),
      );
    }

    final isStarred = vm.currentStarred;
    final progress = vm.progress;
    final progressText = vm.progressLabel;

    return Column(
      children: [
        // ── Header Row: Back button, Progress bar ───────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 20, 0),
          child: Row(
            children: [
              _ScaleButton(
                onTap: () {
                  AppBackButton.handleDefaultBack(context);
                },
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 19,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.greenDark),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                progressText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mid,
                ),
              ),
            ],
          ),
        ),

        // ── Title Row: Unit Name, Undo, Shuffle ────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        vm.unitName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (vm.canUndo) ...[
                      const SizedBox(width: 8),
                      _ScaleButton(
                        onTap: vm.undo,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.undo_rounded,
                            size: 15,
                            color: AppColors.mid,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Shuffle button
              _ScaleButton(
                onTap: vm.shuffle,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.greenDark,
                      width: 1.5,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.shuffle_rounded,
                        size: 14,
                        color: AppColors.greenDark,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Shuffle',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.greenDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Large interactive 3D Flip Card ─────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _markAnim == null ? vm.flipCard : null,
              onHorizontalDragStart: (_) {
                _dragDx = 0;
              },
              onHorizontalDragUpdate: (details) {
                _dragDx += details.delta.dx;
              },
              onHorizontalDragEnd: (details) {
                if (_markAnim != null) return;
                final velocity = details.primaryVelocity ?? 0;
                // Prefer distance for slow swipes; velocity for flicks.
                if (_dragDx <= -64 || velocity < -200) {
                  _markWithAnim(vm, vm.markKnow, 'know');
                } else if (_dragDx >= 64 || velocity > 200) {
                  _markWithAnim(vm, vm.markLearning, 'learning');
                }
                _dragDx = 0;
              },
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: vm.isFlipped ? math.pi : 0),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                builder: (context, val, child) {
                  final isBack = val >= math.pi / 2;
                  final slideX = _markAnim == 'know'
                      ? 55.0
                      : _markAnim == 'learning'
                          ? -55.0
                          : 0.0;
                  final opacity = _markAnim == null ? 1.0 : 0.15;

                  return Opacity(
                    opacity: opacity,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(val)
                        ..translate(slideX, 0.0),
                      child: isBack
                          ? Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(math.pi),
                              child: _buildCardBack(currentTerm, isStarred, vm),
                            )
                          : _buildCardFront(currentTerm, isStarred, vm),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // ── Audio speaker control ──────────────────────────────────
        _ScaleButton(
          onTap: () => _speak(currentTerm.text),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.blue,
              shape: BoxShape.circle,
              boxShadow: AppDecorations.shadowSm,
            ),
            child: const Icon(
              Icons.volume_up_outlined,
              size: 24,
              color: AppColors.greenDark,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ── Bottom Buttons ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Row(
            children: [
              // Still learning button
              Expanded(
                child: _ScaleButton(
                  onTap: () => _markWithAnim(vm, vm.markLearning, 'learning'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius:
                          BorderRadius.circular(AppDecorations.radiusLg),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: AppColors.coralDark,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Still Learning',
                          style: TextStyle(
                            color: AppColors.coralDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // I know this button
              Expanded(
                child: _ScaleButton(
                  onTap: () => _markWithAnim(vm, vm.markKnow, 'know'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius:
                          BorderRadius.circular(AppDecorations.radiusLg),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: AppColors.greenDark,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'I Know This',
                          style: TextStyle(
                            color: AppColors.greenDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardFront(
    Term currentTerm,
    bool isStarred,
    LearnSessionViewModel vm,
  ) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: AppDecorations.card().copyWith(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          // Star button in top right
          Positioned(
            top: 20,
            right: 20,
            child: _ScaleButton(
              onTap: vm.toggleStarCurrent,
              child: Icon(
                isStarred
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 26,
                color: isStarred
                    ? AppColors.coralMid
                    : AppColors.light,
              ),
            ),
          ),

          // Main content
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'WORD',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.light,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentTerm.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tap to reveal',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.light,
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

  Widget _buildCardBack(
    Term currentTerm,
    bool isStarred,
    LearnSessionViewModel vm,
  ) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppDecorations.shadowMd,
      ),
      child: Stack(
        children: [
          // Star button in top right
          Positioned(
            top: 20,
            right: 20,
            child: _ScaleButton(
              onTap: vm.toggleStarCurrent,
              child: Icon(
                isStarred
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 26,
                color: isStarred
                    ? AppColors.coralMid
                    : AppColors.light,
              ),
            ),
          ),

          // Main content
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'DEFINITION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mid,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentTerm.definition,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tap to show word',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.mid,
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

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Scale Button for tactile micro-interactions
// ─────────────────────────────────────────────────────────────────────────────

class _ScaleButton extends StatefulWidget {
  const _ScaleButton({
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
