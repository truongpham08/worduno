import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/app_navigation_notifier.dart';
import '../../../../app/routes/route_paths.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/utils/tts_helper.dart';
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
  _ViewMode _viewMode = _ViewMode.flashcard;
  _FilterMode _filter = _FilterMode.all;

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

    if (_filter == _FilterMode.all) return searched;
    return searched.where((t) {
      final state = vm.getWordState(t.id);
      if (_filter == _FilterMode.starred) return state.isStarred;
      if (_filter == _FilterMode.learned) return state.status == WordStatus.know;
      if (_filter == _FilterMode.learning) return state.status == WordStatus.learning;
      if (_filter == _FilterMode.newWord) return state.status == WordStatus.newWord;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TermListViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 19, color: Color(0xFF111827)),
          onPressed: () =>
              context.read<AppNavigationNotifier>().popHomeRoute(),
        ),
        title: const Text(
          'Lexia',
          style: TextStyle(
            color: Color(0xFF3B82F6),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
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
                          color: Color(0xFF111827),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${vm.knownCount} of ${vm.terms.length} words',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF9CA3AF)),
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
                        color: const Color(0xFF3B82F6),
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
                        color: const Color(0xFFEF4444),
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
                        color: const Color(0xFF8B5CF6),
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
                          child: Text('No terms found.',
                              style: TextStyle(color: Colors.grey)),
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
                                  onStatusChanged: (status) =>
                                      vm.updateStatus(term.id, status),
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
                          child: Text('No terms found.',
                              style: TextStyle(color: Colors.grey)),
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
                                onStatusChanged: (status) =>
                                    vm.updateStatus(term.id, status),
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
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Color(0xFFBCC0CC), fontSize: 14),
        prefixIcon:
            const Icon(Icons.search, color: Color(0xFFBCC0CC), size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
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
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
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
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
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
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected
                    ? const Color(0xFF111827)
                    : const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: selected
                      ? const Color(0xFF111827)
                      : const Color(0xFF9CA3AF),
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
          color: selected ? const Color(0xFF3B82F6) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? const Color(0xFF3B82F6)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF6B7280),
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
    required this.onStatusChanged,
  });

  final Term term;
  final UserWordState state;
  final VoidCallback onStarTapped;
  final ValueChanged<WordStatus> onStatusChanged;

  Color get _statusColor {
    return switch (state.status) {
      WordStatus.know => const Color(0xFF10B981),
      WordStatus.learning => const Color(0xFFF59E0B),
      WordStatus.newWord => const Color(0xFF3B82F6),
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
    final sc = _statusColor;
    final sl = _statusLabel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: term + status badge | icons ─────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final vm = context.read<TermListViewModel>();
                    context.read<AppNavigationNotifier>().openHomeRoute(
                          HomeRoutePaths.learn,
                          params: {
                            'level': vm.levelCode,
                            'unit': vm.unitName,
                            'unitId': vm.unitId,
                            'termId': term.id,
                          },
                        );
                  },
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
                          color: Color(0xFF111827),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: sc.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          sl,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: sc,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.volume_up_outlined,
                        size: 19, color: Colors.grey[400]),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => TtsHelper.speak(term.text),
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
                          ? const Color(0xFFF59E0B)
                          : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ── Definition ─────────────────────────────────────────
          GestureDetector(
            onTap: () {
              final vm = context.read<TermListViewModel>();
              context.read<AppNavigationNotifier>().openHomeRoute(
                    HomeRoutePaths.learn,
                    params: {
                      'level': vm.levelCode,
                      'unit': vm.unitName,
                      'unitId': vm.unitId,
                      'termId': term.id,
                    },
                  );
            },
            child: Text(
              term.definition,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 13),
          // ── Know / Learning buttons ─────────────────────────────
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onStatusChanged(
                      _isLearned ? WordStatus.newWord : WordStatus.know),
                  child: _TermBtn(
                    icon: Icons.check_rounded,
                    label: 'Know',
                    filled: _isLearned,
                    fillColor: const Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => onStatusChanged(
                      _isLearning ? WordStatus.newWord : WordStatus.learning),
                  child: _TermBtn(
                    icon: Icons.refresh_rounded,
                    label: 'Learning',
                    filled: _isLearning,
                    fillColor: const Color(0xFFF59E0B),
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
  });

  final IconData icon;
  final String label;
  final bool filled;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: filled ? fillColor : fillColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 15,
              color: filled ? Colors.white : fillColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: filled ? Colors.white : fillColor,
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
    required this.onStatusChanged,
  });

  final Term term;
  final UserWordState state;
  final VoidCallback onStarTapped;
  final ValueChanged<WordStatus> onStatusChanged;

  @override
  State<_FlashcardListItem> createState() => _FlashcardListItemState();
}

class _FlashcardListItemState extends State<_FlashcardListItem> {
  Color get _statusColor {
    return switch (widget.state.status) {
      WordStatus.know => const Color(0xFF10B981),
      WordStatus.learning => const Color(0xFFF59E0B),
      WordStatus.newWord => const Color(0xFF3B82F6),
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

  @override
  Widget build(BuildContext context) {
    final sc = _statusColor;
    final sl = _statusLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── The Card ───────────────────────────────────────
          GestureDetector(
            onTap: () {
              final vm = context.read<TermListViewModel>();
              context.read<AppNavigationNotifier>().openHomeRoute(
                    HomeRoutePaths.learn,
                    params: {
                      'level': vm.levelCode,
                      'unit': vm.unitName,
                      'unitId': vm.unitId,
                      'termId': widget.term.id,
                    },
                  );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  // Card Header: Status badge on left, Star icon on right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: sc.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          sl,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: sc,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onStarTapped,
                        child: Icon(
                          widget.state.isStarred
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 22,
                          color: widget.state.isStarred
                              ? const Color(0xFFF59E0B)
                              : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Word / Definition Text
                  const Text(
                    'Word',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9CA3AF),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.term.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Tap card to learn',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFBCC0CC),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // ── The button bar below the card ───────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Audio pronunciation circular button
                GestureDetector(
                  onTap: () => TtsHelper.speak(widget.term.text),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.volume_up_outlined,
                      size: 18,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Know button
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onStatusChanged(
                        _isLearned ? WordStatus.newWord : WordStatus.know),
                    child: _TermBtn(
                      icon: Icons.check_rounded,
                      label: 'Know',
                      filled: _isLearned,
                      fillColor: const Color(0xFF10B981),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Learning button
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onStatusChanged(
                        _isLearning ? WordStatus.newWord : WordStatus.learning),
                    child: _TermBtn(
                      icon: Icons.refresh_rounded,
                      label: 'Learning',
                      filled: _isLearning,
                      fillColor: const Color(0xFFF59E0B),
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
}
