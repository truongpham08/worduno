import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/app_navigation_notifier.dart';
import '../../../../app/routes/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_navigation_widgets.dart';
import '../../../../core/utils/sort_utils.dart';
import '../../../../core/tts/presentation/speak_term.dart';
import '../../../../shared/vocabulary/domain/entities/term.dart';
import '../../../../shared/word_state/domain/entities/user_word_state.dart';
import '../../../../shared/word_state/domain/entities/word_status.dart';
import '../viewmodels/term_list_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

enum _ViewMode { list, flashcard }

enum _FilterMode { all, learned, learning, newWord, starred }

// ─────────────────────────────────────────────────────────────────────────────
// Page entry point — owns ViewModel lifecycle
// ─────────────────────────────────────────────────────────────────────────────

class TermListPage extends StatefulWidget {
  const TermListPage({
    super.key,
    required this.levelCode,
    required this.unitName,
    this.unitId,
  });

  final String levelCode;
  final String unitName;
  final String? unitId;

  @override
  State<TermListPage> createState() => _TermListPageState();
}

class _TermListPageState extends State<TermListPage> {
  late final TermListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TermListViewModel(
      levelCode: widget.levelCode,
      unitName: widget.unitName,
      unitId: widget.unitId,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadTerms();
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TermListViewModel>.value(
      value: _viewModel,
      child: const _TermListView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// View (stateful for local UI state)
// ─────────────────────────────────────────────────────────────────────────────

class _TermListView extends StatefulWidget {
  const _TermListView();

  @override
  State<_TermListView> createState() => _TermListViewState();
}

class _TermListViewState extends State<_TermListView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _ViewMode _viewMode = _ViewMode.list;
  _FilterMode _filter = _FilterMode.all;
  SortOrder _sort = SortOrder.original;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Term> _applyFilter(List<Term> terms, TermListViewModel vm) {
    final searched = terms
        .where((t) =>
            t.text.toLowerCase().contains(_searchQuery) ||
            t.definition.toLowerCase().contains(_searchQuery))
        .toList();

    final filtered = _filter == _FilterMode.all
        ? searched
        : searched.where((t) {
            final state = vm.getWordState(t.id);
            if (_filter == _FilterMode.starred) return state.isStarred;
            if (_filter == _FilterMode.learned) {
              return state.status == WordStatus.know;
            }
            if (_filter == _FilterMode.learning) {
              return state.status == WordStatus.learning;
            }
            if (_filter == _FilterMode.newWord) {
              return state.status == WordStatus.newWord;
            }
            return true;
          }).toList();

    return SortUtils.sortByName(
      items: filtered,
      nameSelector: (term) => term.text,
      order: _sort,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TermListViewModel>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const LexiaAppBar(showBack: true),
      body: vm.isLoading
          ? const AppLoading(message: 'Loading terms...')
          : vm.errorMessage != null
              ? AppErrorView(
                  message: vm.errorMessage!,
                  onRetry: vm.loadTerms,
                )
              : _buildContent(vm),
    );
  }

  Widget _buildContent(TermListViewModel vm) {
    final displayTerms = _applyFilter(vm.terms, vm);

    return Column(
      children: [
        // ── Scrollable top section ─────────────────────────────────
        Expanded(
          child: CustomScrollView(
            slivers: [
              // ── Page header ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vm.unitName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${displayTerms.length} of ${vm.terms.length} words',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.light,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Search bar ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: _SearchBarField(
                    controller: _searchController,
                    hint: 'Search vocabulary...',
                  ),
                ),
              ),

              // ── Action buttons: Learn / Exam / Coach ────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    children: [
                      _ActionBtn(
                        icon: Icons.menu_book_outlined,
                        label: 'Learn',
                        color: AppColors.greenDark,
                        onTap: () {
                          context.read<AppNavigationNotifier>().openHomeRoute(
                            HomeRoutePaths.learn,
                            params: {
                              'level': vm.levelCode,
                              'unit': vm.unitName,
                              'unitId': vm.unitId,
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      _ActionBtn(
                        icon: Icons.quiz_outlined,
                        label: 'Exam',
                        color: AppColors.coralDark,
                        onTap: () {
                          context.read<AppNavigationNotifier>().openHomeRoute(
                            HomeRoutePaths.examConfig,
                            params: {
                              'level': vm.levelCode,
                              'unit': vm.unitName,
                              'unitId': vm.unitId,
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      _ActionBtn(
                        icon: Icons.smart_toy_outlined,
                        label: 'Coach',
                        color: AppColors.greenMid,
                        onTap: () {
                          context.read<AppNavigationNotifier>().openHomeRoute(
                            HomeRoutePaths.coachConfig,
                            params: {
                              'level': vm.levelCode,
                              'unit': vm.unitName,
                              'unitId': vm.unitId,
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ── List / Flashcards toggle ─────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: _ViewToggle(
                    current: _viewMode,
                    onChanged: (m) {
                      setState(() {
                        _viewMode = m;
                      });
                    },
                  ),
                ),
              ),

              // ── Sort chips (spec §11) ───────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip2(
                          label: 'Original order',
                          selected: _sort == SortOrder.original,
                          onTap: () =>
                              setState(() => _sort = SortOrder.original),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip2(
                          label: 'A–Z',
                          selected: _sort == SortOrder.aToZ,
                          onTap: () =>
                              setState(() => _sort = SortOrder.aToZ),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip2(
                          label: 'Z–A',
                          selected: _sort == SortOrder.zToA,
                          onTap: () =>
                              setState(() => _sort = SortOrder.zToA),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Filter chips ─────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip2(
                          label: 'All',
                          selected: _filter == _FilterMode.all,
                          onTap: () =>
                              setState(() => _filter = _FilterMode.all),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip2(
                          label: 'Learned',
                          selected: _filter == _FilterMode.learned,
                          onTap: () => setState(
                              () => _filter = _FilterMode.learned),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip2(
                          label: 'Learning',
                          selected: _filter == _FilterMode.learning,
                          onTap: () => setState(
                              () => _filter = _FilterMode.learning),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip2(
                          label: 'New',
                          selected: _filter == _FilterMode.newWord,
                          onTap: () => setState(
                              () => _filter = _FilterMode.newWord),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip2(
                          label: 'Starred',
                          selected: _filter == _FilterMode.starred,
                          onTap: () => setState(
                              () => _filter = _FilterMode.starred),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Content ─────────────────────────────────────────
              if (_viewMode == _ViewMode.list)
                displayTerms.isEmpty
                    ? const SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'No terms found.',
                            style: TextStyle(color: AppColors.light),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 14, 20, 32),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final term = displayTerms[i];
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 12),
                                child: _TermCard(
                                  term: term,
                                  state: vm.getWordState(term.id),
                                  onStarTapped: () => vm.toggleStar(term.id),
                                  onKnowTapped: () =>
                                      vm.updateStatus(term.id, WordStatus.know),
                                  onLearningTapped: () => vm.updateStatus(
                                      term.id, WordStatus.learning),
                                ),
                              );
                            },
                            childCount: displayTerms.length,
                          ),
                        ),
                      )
              else
                // Flashcard list view
                displayTerms.isEmpty
                    ? const SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'No terms found.',
                            style: TextStyle(color: AppColors.light),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final term = displayTerms[i];
                              return _FlashcardListItem(
                                key: ValueKey('fc-${term.id}'),
                                term: term,
                                state: vm.getWordState(term.id),
                                onStarTapped: () => vm.toggleStar(term.id),
                                onKnowTapped: () =>
                                    vm.updateStatus(term.id, WordStatus.know),
                                onLearningTapped: () => vm.updateStatus(
                                    term.id, WordStatus.learning),
                              );
                            },
                            childCount: displayTerms.length,
                          ),
                        ),
                      ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBarField extends StatelessWidget {
  const _SearchBarField(
      {required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: AppColors.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.light, fontSize: 14),
        prefixIcon:
            const Icon(Icons.search, color: AppColors.light, size: 20),
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusPill),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusPill),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusPill),
          borderSide:
              const BorderSide(color: AppColors.greenMid, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action button (Learn / Exam / Coach)
// ─────────────────────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.white, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// List / Flashcard toggle
// ─────────────────────────────────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  const _ViewToggle(
      {required this.current, required this.onChanged});

  final _ViewMode current;
  final ValueChanged<_ViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
      ),
      child: Row(
        children: [
          _ToggleOption(
            icon: Icons.list_rounded,
            label: 'List',
            selected: current == _ViewMode.list,
            onTap: () => onChanged(_ViewMode.list),
          ),
          _ToggleOption(
            icon: Icons.style_outlined,
            label: 'Flashcards',
            selected: current == _ViewMode.flashcard,
            onTap: () => onChanged(_ViewMode.flashcard),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected ? AppDecorations.shadowSm : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? AppColors.ink : AppColors.light,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.ink : AppColors.light,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter chip
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip2 extends StatelessWidget {
  const _FilterChip2({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.greenDark : AppColors.white,
          borderRadius: BorderRadius.circular(AppDecorations.radiusPill),
          border: Border.all(
            color: selected ? AppColors.greenDark : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : AppColors.mid,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Term card (List view)
// ─────────────────────────────────────────────────────────────────────────────

class _TermCard extends StatelessWidget {
  const _TermCard({
    required this.term,
    required this.state,
    required this.onStarTapped,
    required this.onKnowTapped,
    required this.onLearningTapped,
  });

  final Term term;
  final UserWordState state;
  final VoidCallback onStarTapped;
  final VoidCallback onKnowTapped;
  final VoidCallback onLearningTapped;

  String get _statusKey {
    return switch (state.status) {
      WordStatus.know => 'learned',
      WordStatus.learning => 'learning',
      WordStatus.newWord => 'new',
    };
  }

  String get _statusLabel {
    return switch (state.status) {
      WordStatus.know => 'learned',
      WordStatus.learning => 'learning',
      WordStatus.newWord => 'new',
    };
  }

  bool get _isLearned => state.status == WordStatus.know;
  bool get _isLearning => state.status == WordStatus.learning;

  @override
  Widget build(BuildContext context) {
    final statusPal = AppColors.wordStatus(_statusKey);
    final sl = _statusLabel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
        boxShadow: AppDecorations.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: term + status badge | icons ─────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      term.text,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusPal.bg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        sl,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusPal.fg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.volume_up_outlined,
                        size: 19, color: AppColors.light),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => speakTermWithFeedback(context, term.text),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onStarTapped,
                    child: Icon(
                      state.isStarred
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 20,
                      color: state.isStarred
                          ? AppColors.coralMid
                          : AppColors.light,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            term.definition,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.mid,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onKnowTapped,
                  child: _TermBtn(
                    icon: Icons.check_rounded,
                    label: 'Know',
                    filled: _isLearned,
                    fillColor: AppColors.greenDark,
                    unfilledBg: AppColors.green,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: onLearningTapped,
                  child: _TermBtn(
                    icon: Icons.refresh_rounded,
                    label: 'Learning',
                    filled: _isLearning,
                    fillColor: AppColors.coralMid,
                    unfilledBg: AppColors.beigeLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TermBtn extends StatelessWidget {
  const _TermBtn({
    required this.icon,
    required this.label,
    required this.filled,
    required this.fillColor,
    this.unfilledBg,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final Color fillColor;
  final Color? unfilledBg;

  @override
  Widget build(BuildContext context) {
    final bg = filled ? fillColor : (unfilledBg ?? fillColor.withValues(alpha: 0.1));
    final fg = filled ? AppColors.white : fillColor;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDecorations.radiusPill),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Flashcard list item
// ─────────────────────────────────────────────────────────────────────────────

class _FlashcardListItem extends StatefulWidget {
  const _FlashcardListItem({
    super.key,
    required this.term,
    required this.state,
    required this.onStarTapped,
    required this.onKnowTapped,
    required this.onLearningTapped,
  });

  final Term term;
  final UserWordState state;
  final VoidCallback onStarTapped;
  final VoidCallback onKnowTapped;
  final VoidCallback onLearningTapped;

  @override
  State<_FlashcardListItem> createState() => _FlashcardListItemState();
}

class _FlashcardListItemState extends State<_FlashcardListItem> {
  bool _isFlipped = false;

  String get _statusKey {
    return switch (widget.state.status) {
      WordStatus.know => 'learned',
      WordStatus.learning => 'learning',
      WordStatus.newWord => 'new',
    };
  }

  String get _statusLabel {
    return switch (widget.state.status) {
      WordStatus.know => 'learned',
      WordStatus.learning => 'learning',
      WordStatus.newWord => 'new',
    };
  }

  bool get _isLearned => widget.state.status == WordStatus.know;
  bool get _isLearning => widget.state.status == WordStatus.learning;

  void _toggleFlip() => setState(() => _isFlipped = !_isFlipped);

  @override
  Widget build(BuildContext context) {
    final statusPal = AppColors.wordStatus(_statusKey);
    final sl = _statusLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _toggleFlip,
            child: SizedBox(
              height: 168,
              width: double.infinity,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: _isFlipped ? math.pi : 0,
                ),
                duration: const Duration(milliseconds: 520),
                curve: Curves.easeInOut,
                builder: (context, angle, child) {
                  final showBack = angle >= math.pi / 2;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: showBack
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: _buildCardBack(),
                          )
                        : _buildCardFront(statusPal, sl),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
              boxShadow: AppDecorations.shadowSm,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => speakTermWithFeedback(context, widget.term.text),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: AppColors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.volume_up_outlined,
                      size: 18,
                      color: AppColors.greenMid,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onKnowTapped,
                    child: _TermBtn(
                      icon: Icons.check_rounded,
                      label: 'Know',
                      filled: _isLearned,
                      fillColor: AppColors.greenDark,
                      unfilledBg: AppColors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onLearningTapped,
                    child: _TermBtn(
                      icon: Icons.refresh_rounded,
                      label: 'Learning',
                      filled: _isLearning,
                      fillColor: AppColors.coralMid,
                      unfilledBg: AppColors.beigeLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFront(WordStatusPalette statusPal, String statusLabel) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
        boxShadow: AppDecorations.shadowSm,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: widget.onStarTapped,
              child: Icon(
                widget.state.isStarred
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 22,
                color: widget.state.isStarred
                    ? AppColors.coralMid
                    : AppColors.light,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusPal.bg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusPal.fg,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.term.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap card to flip',
                    style: TextStyle(
                      fontSize: 11,
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

  Widget _buildCardBack() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
        boxShadow: AppDecorations.shadowSm,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: widget.onStarTapped,
              child: Icon(
                widget.state.isStarred
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 22,
                color: widget.state.isStarred
                    ? AppColors.coralMid
                    : AppColors.light,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'DEFINITION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mid,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.term.definition,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                      height: 1.5,
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
