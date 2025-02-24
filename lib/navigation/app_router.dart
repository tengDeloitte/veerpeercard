import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veerpeercard/providers/bottom_tabs_provider.dart';
import 'package:veerpeercard/screens/main_screen.dart';

class AppRouter {
  final WidgetRef ref;
  
  /// 构造函数
  AppRouter(this.ref);

  late final goRouter = GoRouter(
    initialLocation: '/${ref.read(providerCurrentTabIndex)}',
    routes: [
      GoRoute(
        path: '/:tab',
        builder: (context, state) {
          final tabIndex = int.tryParse(state.pathParameters['tab'] ?? '') ?? 2;

          ref.read(providerCurrentTabIndex.notifier).setTabIndex(tabIndex);
          return const MainScreen();
        },
      ),
    ],
    errorPageBuilder: (context, state) {
      return MaterialPage(
        key: state.pageKey,
        child: Scaffold(
          body: Center(
            child: Text(
              state.error.toString(),
            ),
          ),
        ),
      );
    },
  );
}