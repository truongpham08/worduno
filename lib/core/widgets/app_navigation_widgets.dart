import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/navigation/app_navigation_notifier.dart';
import '../../app/routes/route_paths.dart';

/// Consistent back control wired to [AppNavigationNotifier].
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onPressed,
  });

  final VoidCallback? onPressed;

  static void handleDefaultBack(BuildContext context) {
    final nav = context.read<AppNavigationNotifier>();
    final config = nav.configuration;

    if (config.tab == AppTab.coachHistory && config.coachStack.length > 1) {
      nav.popCoachRoute();
      return;
    }
    if (config.tab == AppTab.examHistory && config.examDetailId != null) {
      nav.popExamDetail();
      return;
    }
    if (config.tab == AppTab.home && config.homeStack.length > 1) {
      nav.popHomeRoute();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 19,
        color: Color(0xFF111827),
      ),
      onPressed: onPressed ?? () => handleDefaultBack(context),
    );
  }
}

class WordunoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WordunoAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
    this.actions,
    this.centerTitle = true,
    this.titleStyle,
  });

  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool centerTitle;
  final TextStyle? titleStyle;

  static const _defaultTitleStyle = TextStyle(
    color: Color(0xFF111827),
    fontWeight: FontWeight.w700,
    fontSize: 18,
  );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: showBack
          ? AppBackButton(onPressed: onBack)
          : null,
      title: Text(
        title,
        style: titleStyle ?? _defaultTitleStyle,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF111827)),
      actions: actions,
    );
  }
}

/// Lexia-branded app bar used on home browsing screens.
class LexiaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LexiaAppBar({
    super.key,
    this.showBack = false,
    this.onBack,
    this.actions,
  });

  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: showBack
          ? AppBackButton(onPressed: onBack)
          : null,
      title: const Text(
        'Lexia',
        style: TextStyle(
          color: Color(0xFF3B82F6),
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
      actions: actions,
    );
  }
}
