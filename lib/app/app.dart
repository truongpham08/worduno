import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import 'navigation/app_navigation_notifier.dart';
import 'routes/app_route_information_parser.dart';
import 'routes/app_router_delegate.dart';

class WordunoApp extends StatefulWidget {
  const WordunoApp({super.key});

  @override
  State<WordunoApp> createState() => _WordunoAppState();
}

class _WordunoAppState extends State<WordunoApp> {
  late final AppNavigationNotifier _navigationNotifier;
  late final AppRouterDelegate _routerDelegate;
  late final AppRouteInformationParser _routeParser;

  @override
  void initState() {
    super.initState();
    _navigationNotifier = AppNavigationNotifier();
    _routerDelegate = AppRouterDelegate(
      navigationNotifier: _navigationNotifier,
    );
    _routeParser = AppRouteInformationParser();
  }

  @override
  void dispose() {
    _routerDelegate.dispose();
    _navigationNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _navigationNotifier),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3B82F6),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF0F2FA),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            foregroundColor: Color(0xFF1A1A2E),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: Color(0xFF3B82F6),
            unselectedItemColor: Color(0xFF9CA3AF),
            elevation: 8,
          ),
          fontFamily: 'Roboto',
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
                fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
            headlineMedium: TextStyle(
                fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
            bodyMedium: TextStyle(color: Color(0xFF374151)),
            bodySmall: TextStyle(color: Color(0xFF6B7280)),
          ),
        ),
        routerDelegate: _routerDelegate,
        routeInformationParser: _routeParser,
      ),
    );
  }
}
