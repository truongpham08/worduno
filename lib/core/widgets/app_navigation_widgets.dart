import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/navigation/app_navigation_notifier.dart';
import '../../app/routes/route_paths.dart';
import '../theme/app_colors.dart';

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
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: AppColors.greenDark.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onPressed ?? () => handleDefaultBack(context),
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            Icons.chevron_left_rounded,
            size: 22,
            color: AppColors.mid,
          ),
        ),
      ),
    );
  }
}

class WordunoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WordunoAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.showBack = true,
    this.onBack,
    this.actions,
    this.centerTitle = true,
    this.titleStyle,
  });

  final String title;
  final Widget? titleWidget;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool centerTitle;
  final TextStyle? titleStyle;

  static const _defaultTitleStyle = TextStyle(
    color: AppColors.ink,
    fontWeight: FontWeight.w700,
    fontSize: 18,
  );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: showBack
          ? Padding(
              padding: const EdgeInsets.only(left: 8),
              child: AppBackButton(onPressed: onBack),
            )
          : null,
      leadingWidth: showBack ? 50 : null,
      title: titleWidget ??
          Text(
            title,
            style: titleStyle ?? _defaultTitleStyle,
          ),
      iconTheme: const IconThemeData(color: AppColors.ink),
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
      backgroundColor: AppColors.greenDark,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: onBack ?? () => AppBackButton.handleDefaultBack(context),
            )
          : null,
      title: const Text(
        'Lexia',
        style: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
      ),
      actions: actions,
    );
  }
}
