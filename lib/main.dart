import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:veerpeercard/providers/theme_provider.dart';
import 'package:veerpeercard/providers/auth_provider.dart'; // 引入auth_provider
import 'package:veerpeercard/screens/main_screen.dart';
import 'package:veerpeercard/screens/login_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 初始化主题
  final themeNotifier = NotifierTheme();
  await themeNotifier.initialize();

  runApp(
    ProviderScope(
      overrides: [
        providerTheme.overrideWith((ref) => themeNotifier),
      ],
      child: const TheApp(),
    ),
  );
}

class TheApp extends ConsumerWidget {
  const TheApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(providerTheme);
    final authState = ref.watch(authStateProvider); // 使用来自auth_provider.dart的provider

    return MaterialApp(
      title: 'VeerPeerCard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: themeMode,
      home: authState.when(
        data: (user) {
          // 根据用户登录状态决定显示哪个界面
          if (user == null) {
            return const LoginScreen();
          }
          return const MainScreen();
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stackTrace) => Scaffold(
          body: Center(
            child: Text('Error: $error'),
          ),
        ),
      ),
    );
  }
}